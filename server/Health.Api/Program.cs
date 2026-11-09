using Health.Api;
using System.Data.Common;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;

if(args.Contains("--self-test")) return SelfTests.Run();
var validateIndex=Array.IndexOf(args,"--validate-import");
if(validateIndex>=0) {
    if(validateIndex+1>=args.Length){Console.Error.WriteLine("Supply JSON export path.");return 1;}
    try {using var doc=JsonDocument.Parse(await File.ReadAllTextAsync(args[validateIndex+1]));SqlStore.ValidateImport(doc.RootElement);Console.WriteLine("IMPORT_VALIDATION PASS; SQL Server was not contacted.");return 0;}
    catch(ApiProblem ex){Console.Error.WriteLine(ex.Message);return 1;}
    catch(JsonException){Console.Error.WriteLine("Invalid JSON export.");return 1;}
    catch(IOException){Console.Error.WriteLine("Cannot read the JSON export. Supply its absolute path.");return 1;}
}
var builder=WebApplication.CreateBuilder(args.Where(a=>a is not ("--init" or "--integration-test")).ToArray());
builder.Services.ConfigureHttpJsonOptions(o=>o.SerializerOptions.PropertyNamingPolicy=JsonNamingPolicy.SnakeCaseLower);
builder.WebHost.ConfigureKestrel(o=>o.Limits.MaxRequestBodySize=65536);
var connection=builder.Configuration["ConnectionStrings:Health"];
if(string.IsNullOrWhiteSpace(connection)) {Console.Error.WriteLine("Set ConnectionStrings__Health on the API server.");return 1;}
var store=new SqlStore(connection);
if(args.Contains("--init")) {
    try {await store.Initialize();Console.WriteLine("SQL Server schema initialized; existing data was not reset.");return 0;}
    catch(Exception ex){Console.Error.WriteLine($"Initialization failed ({ex.GetType().Name}). Restore the SQL driver and check the dedicated SQL Server database.");return 1;}
}
var importIndex=Array.IndexOf(args,"--import");
if(importIndex>=0) {
    if(importIndex+1>=args.Length){Console.Error.WriteLine("Supply the exported JSON path after --import.");return 1;}
    try {await store.ImportFile(args[importIndex+1]);Console.WriteLine("Imported legacy records and IDs. Source SQLite was not changed.");return 0;}
    catch(ApiProblem ex){Console.Error.WriteLine(ex.Message);return 1;}
    catch(JsonException){Console.Error.WriteLine("Invalid JSON export.");return 1;}
    catch(IOException){Console.Error.WriteLine("Cannot read the JSON export. Supply its absolute path.");return 1;}
}
var apiKey=builder.Configuration["HEALTH_API_KEY"]??"";
if(apiKey.Length<32 || apiKey.Length>512) {Console.Error.WriteLine("HEALTH_API_KEY must contain 32 to 512 characters.");return 1;}
var expectedHash=SHA256.HashData(Encoding.UTF8.GetBytes(apiKey));
var app=builder.Build();
app.Use(async(context,next)=>{
    try {
        var supplied=context.Request.Headers["X-Api-Key"].ToString();
        var device=context.Request.Headers["X-Device-Id"].ToString();
        RequestSecurity.Validate(app.Environment.IsDevelopment(),context.Request.IsHttps,expectedHash,supplied,device);
        await next(context);
    } catch(ApiProblem ex) {
        context.Response.StatusCode=ex.Status;await context.Response.WriteAsJsonAsync(new {message=ex.Message});
    } catch(BadHttpRequestException) {
        context.Response.StatusCode=400;await context.Response.WriteAsJsonAsync(new {message="Nội dung yêu cầu không hợp lệ."});
    } catch(JsonException) {
        context.Response.StatusCode=400;await context.Response.WriteAsJsonAsync(new {message="Dữ liệu JSON không hợp lệ."});
    } catch(Exception ex) {
        // Never return SQL errors, connection strings, keys or health payloads.
        app.Logger.LogError("Storage request failed ({ErrorType})",ex.GetType().Name);
        context.Response.StatusCode=503;await context.Response.WriteAsJsonAsync(new {message="Chưa kết nối được SQL Server. Dữ liệu chưa được xác nhận lưu; hãy thử lại."});
    }
});
static string Device(HttpRequest r)=>r.Headers["X-Device-Id"].ToString();
static string Key(HttpRequest r)=>r.Headers["Idempotency-Key"].ToString();
app.MapGet("/api/meta",async()=>Results.Json(await store.Meta()));
app.MapGet("/api/profile",async()=>Results.Json(await store.Profile()));
app.MapPut("/api/profile",async(ProfileInput input,HttpRequest r)=>Results.Json(new {id=await store.SaveProfile(input,Key(r))}));
app.MapGet("/api/health",async(long from,long to)=>Results.Json(await store.Health(from,to)));
app.MapGet("/api/health/latest",async()=>Results.Json(await store.Latest()));
app.MapPost("/api/health",async(HealthInput input,HttpRequest r)=>Results.Json(new {id=await store.SaveHealth(null,input,Key(r))}));
app.MapPut("/api/health/{id:int}",async(int id,HealthInput input,HttpRequest r)=>Results.Json(new {id=await store.SaveHealth(id,input,Key(r))}));
app.MapDelete("/api/health/{id:int}",async(int id,HttpRequest r)=>Results.Json(new {id=await store.DeleteHealth(id,Key(r))}));
app.MapGet("/api/care",async(HttpRequest r)=>Results.Json(await store.Care(r.Query["type"].FirstOrDefault(),bool.TryParse(r.Query["enabled"],out var e)?e:null,bool.TryParse(r.Query["include_archived"],out var a)&&a)));
app.MapGet("/api/care/{id:int}",async(int id)=>Results.Json(await store.FindCare(id)));
app.MapPost("/api/care",async(CareInput input,HttpRequest r)=>Results.Json(new {id=await store.SaveCare(null,input,Key(r))}));
app.MapPut("/api/care/{id:int}",async(int id,CareInput input,HttpRequest r)=>Results.Json(new {id=await store.SaveCare(id,input,Key(r))}));
app.MapPut("/api/care/{id:int}/enabled",async(int id,EnabledInput input,HttpRequest r)=>Results.Json(new {id=await store.SetEnabled(id,input.IsEnabled,Key(r))}));
app.MapPost("/api/care/{id:int}/archive",async(int id,HttpRequest r)=>Results.Json(new {id=await store.Archive(id,Key(r))}));
app.MapGet("/api/occurrences",async(HttpRequest r)=>{
    int? reminder=int.TryParse(r.Query["reminder_id"],out var id)?id:null;
    long? from=long.TryParse(r.Query["from"],out var f)?f:null;long? to=long.TryParse(r.Query["to"],out var t)?t:null;
    if(reminder is null && (from is null || to is null))throw new ApiProblem(400,"Chọn lịch hoặc khoảng thời gian.");
    return Results.Json(await store.Occurrences(Device(r),reminder,from,to));
});
app.MapGet("/api/occurrences/{id:int}",async(int id,HttpRequest r)=>Results.Json(await store.Occurrence(Device(r),id)));
app.MapPut("/api/occurrences/{id:int}/resolution",async(int id,ResolutionInput input,HttpRequest r)=>Results.Json(new {id=await store.Resolve(id,input.Status,Key(r))}));
app.MapGet("/api/notifications",async(HttpRequest r)=>Results.Json(await store.Notifications(Device(r))));
app.MapGet("/api/notifications/warnings",async(HttpRequest r)=>Results.Json(new {has_warnings=await store.Warnings(Device(r))}));
app.MapPut("/api/notifications/{id:int}",async(int id,NotificationInput input,HttpRequest r)=>Results.Json(new {changed=await store.Notification(Device(r),id,input.Action)}));
await app.RunAsync();return 0;
