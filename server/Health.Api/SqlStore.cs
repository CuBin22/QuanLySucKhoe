using System.Data;
using System.Data.Common;
using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;

namespace Health.Api;

public sealed partial class SqlStore(string connectionString)
{
    static readonly JsonSerializerOptions Json = new() { PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower };
    const string OccurrenceSelect = """
      SELECT o.*, CASE WHEN n.notification_state IS NOT NULL THEN n.notification_state WHEN o.status='pending' THEN 'pending_schedule' ELSE 'cancelled' END AS notification_state,
      n.notification_error, r.title FROM dbo.reminder_occurrences o JOIN dbo.care_reminders r ON r.id=o.reminder_id
      LEFT JOIN dbo.device_notifications n ON n.occurrence_id=o.id AND n.device_id=@device
      """;
    async Task<DbConnection> Open()
    {
        // Resolve at runtime so dependency-free business tests need no SQL driver.
        var type=Type.GetType("Microsoft.Data.SqlClient.SqlClientFactory, Microsoft.Data.SqlClient",throwOnError:true)!;
        var factory=(DbProviderFactory)type.GetField("Instance")!.GetValue(null)!;
        var connection=factory.CreateConnection()!;connection.ConnectionString=connectionString;
        try { await connection.OpenAsync(); return connection; } catch { await connection.DisposeAsync();throw; }
    }
    static DbCommand Command(DbConnection db, DbTransaction? tx, string sql, params (string Key, object? Value)[] args)
    {
        var cmd=db.CreateCommand();cmd.CommandText=sql;cmd.Transaction=tx;cmd.CommandTimeout=30;
        foreach(var (key,value) in args) {var p=cmd.CreateParameter();p.ParameterName=key;p.Value=value??DBNull.Value;cmd.Parameters.Add(p);}
        return cmd;
    }
    static async Task<List<Dictionary<string,object?>>> Rows(DbConnection db, DbTransaction? tx, string sql, params (string Key,object? Value)[] args)
    {
        await using var cmd=Command(db,tx,sql,args);await using var reader=await cmd.ExecuteReaderAsync();var result=new List<Dictionary<string,object?>>();
        while(await reader.ReadAsync()) {
            var row=new Dictionary<string,object?>();
            for(var i=0;i<reader.FieldCount;i++) {
                var value=await reader.IsDBNullAsync(i)?null:reader.GetValue(i);
                row[reader.GetName(i)]=value switch { bool b => b?1:0, DateTime d=>d.ToString("yyyy-MM-dd",CultureInfo.InvariantCulture), Guid g=>g.ToString("N"), _=>value };
            }
            result.Add(row);
        }
        return result;
    }
    static async Task<int> Exec(DbConnection db,DbTransaction? tx,string sql,params (string Key,object? Value)[] args)
    {await using var cmd=Command(db,tx,sql,args);return await cmd.ExecuteNonQueryAsync();}
    static async Task<int> Insert(DbConnection db,DbTransaction tx,string sql,params (string Key,object? Value)[] args)
    {await using var cmd=Command(db,tx,sql+";SELECT CAST(SCOPE_IDENTITY() AS int)",args);return Convert.ToInt32(await cmd.ExecuteScalarAsync());}
    public async Task<List<Dictionary<string,object?>>> Query(string sql,params (string Key,object? Value)[] args)
    {await using var db=await Open();return await Rows(db,null,sql,args);}
    async Task<T> Transaction<T>(Func<DbConnection,DbTransaction,Task<T>> action)
    {
        await using var db=await Open();await using var tx=await db.BeginTransactionAsync(IsolationLevel.Serializable);
        try {
            // One personal profile: serialize writes, including first profile save.
            await Rows(db,tx,"SELECT id FROM dbo.server_settings WITH(UPDLOCK,HOLDLOCK) WHERE id=1");
            var value=await action(db,tx);await tx.CommitAsync();return value;
        } catch {await tx.RollbackAsync();throw;}
    }
    Task<int> Mutation(string key,string operation,Func<DbConnection,DbTransaction,Task<int>> action)
    {
        if(!Guid.TryParse(key,out var requestId))throw new ApiProblem(400,"Thiếu Idempotency-Key hợp lệ.");
        var hash=Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(operation)));
        return Transaction(async(db,tx)=>{
            var prior=await Rows(db,tx,"SELECT operation_hash,result_id FROM dbo.api_requests WHERE request_id=@key",("@key",requestId));
            if(prior.Count>0) {if((string)prior[0]["operation_hash"]! !=hash)throw new ApiProblem(409,"Mã thao tác đã dùng cho nội dung khác.");return (int)prior[0]["result_id"]!;}
            var id=await action(db,tx);
            await Exec(db,tx,"INSERT dbo.api_requests(request_id,operation_hash,result_id,created_at_utc) VALUES(@key,@hash,@id,@now)",("@key",requestId),("@hash",hash),("@id",id),("@now",DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()));return id;
        });
    }
    public async Task Initialize()
    {
        var builder=new DbConnectionStringBuilder {ConnectionString=connectionString};
        var database=builder.ContainsKey("Initial Catalog")?builder["Initial Catalog"]:builder.ContainsKey("Database")?builder["Database"]:null;
        if(database is null || new[]{"master","model","msdb","tempdb"}.Contains(database.ToString(),StringComparer.OrdinalIgnoreCase)) throw new InvalidOperationException("Select a dedicated application database before --init.");
        await using var db=await Open();await Exec(db,null,await File.ReadAllTextAsync(Path.Combine(AppContext.BaseDirectory,"schema.sql")));
    }
    public async Task<object> Meta() => (await Query("SELECT backend_id,schema_version FROM dbo.server_settings WHERE id=1")).Single();
    public async Task<object?> Profile() => (await Query("SELECT * FROM dbo.profiles WHERE id=1")).FirstOrDefault();
    public Task<int> SaveProfile(ProfileInput input,string key) => Mutation(key,"profile:"+JsonSerializer.Serialize(input,Json),async(db,tx)=>{
        var now=DateTimeOffset.UtcNow;Rules.Profile(input,now);
        await Exec(db,tx,"""
        UPDATE dbo.profiles SET full_name=@name,birth_date=@birth,height_cm=@height,target_weight_kg=@target,updated_at_utc=@now WHERE id=1;
        IF @@ROWCOUNT=0 INSERT dbo.profiles(id,full_name,birth_date,height_cm,target_weight_kg,created_at_utc,updated_at_utc) VALUES(1,@name,@birth,@height,@target,@now,@now);
        """,("@name",input.FullName.Trim()),("@birth",input.BirthDate),("@height",input.HeightCm),("@target",input.TargetWeightKg),("@now",now.ToUnixTimeMilliseconds()));return 1;
    });
    public Task<List<Dictionary<string,object?>>> Health(long from,long to) => Query("SELECT * FROM dbo.health_records WHERE measured_at_utc>=@from AND measured_at_utc<@to ORDER BY measured_at_utc DESC,id DESC",("@from",from),("@to",to));
    public async Task<object> Latest()
    {
        var result=new Dictionary<string,object?>();
        foreach(var (metric,column) in new[]{("weight","weight_kg"),("bloodPressure","systolic"),("heartRate","heart_rate")}) {
            var rows=await Query($"SELECT TOP(1) * FROM dbo.health_records WHERE {column} IS NOT NULL ORDER BY measured_at_utc DESC,id DESC");
            if(rows.Count>0)result[metric]=rows[0];
        }
        return result;
    }
    public Task<int> SaveHealth(int? id,HealthInput input,string key) => Mutation(key,$"health:{id}:"+JsonSerializer.Serialize(input,Json),async(db,tx)=>{
        var now=DateTimeOffset.UtcNow;Rules.Health(input,now);Dictionary<string,object?>? old=null;
        if(id is not null) old=(await Rows(db,tx,"SELECT * FROM dbo.health_records WHERE id=@id",("@id",id))).FirstOrDefault()??throw new ApiProblem(404,"Bản ghi không còn tồn tại.");
        var profile=(await Rows(db,tx,"SELECT height_cm FROM dbo.profiles WHERE id=1")).FirstOrDefault()??throw new ApiProblem(400,"Hãy thiết lập hồ sơ trước.");
        var snapshot=input.WeightKg is null?null:old?.GetValueOrDefault("height_cm_snapshot")??profile["height_cm"];
        (string,object?)[] args=[("@id",id),("@at",input.MeasuredAtUtc),("@weight",input.WeightKg),("@height",snapshot),("@sys",input.Systolic),("@dia",input.Diastolic),("@heart",input.HeartRate),("@note",input.Note?.Trim()??""),("@now",now.ToUnixTimeMilliseconds())];
        if(id is null)return await Insert(db,tx,"INSERT dbo.health_records(profile_id,measured_at_utc,weight_kg,height_cm_snapshot,systolic,diastolic,heart_rate,note,created_at_utc,updated_at_utc) VALUES(1,@at,@weight,@height,@sys,@dia,@heart,@note,@now,@now)",args);
        await Exec(db,tx,"UPDATE dbo.health_records SET measured_at_utc=@at,weight_kg=@weight,height_cm_snapshot=@height,systolic=@sys,diastolic=@dia,heart_rate=@heart,note=@note,updated_at_utc=@now WHERE id=@id",args);return id.Value;
    });
    public Task<int> DeleteHealth(int id,string key) => Mutation(key,$"health-delete:{id}",async(db,tx)=>{
        if(await Exec(db,tx,"DELETE dbo.health_records WHERE id=@id",("@id",id))==0)throw new ApiProblem(404,"Bản ghi không còn tồn tại.");return id;
    });
    public Task<List<Dictionary<string,object?>>> Care(string? type,bool? enabled,bool archived) => Query("SELECT * FROM dbo.care_reminders WHERE (@archived=1 OR is_archived=0) AND (@type IS NULL OR type=@type) AND (@enabled IS NULL OR is_enabled=@enabled) ORDER BY is_enabled DESC,start_date DESC,id DESC",("@archived",archived),("@type",type),("@enabled",enabled));
    public async Task<object?> FindCare(int id) => (await Query("SELECT * FROM dbo.care_reminders WHERE id=@id",("@id",id))).FirstOrDefault();
    static async Task<Dictionary<string,object?>> RequireCare(DbConnection db,DbTransaction tx,int id) => (await Rows(db,tx,"SELECT * FROM dbo.care_reminders WHERE id=@id AND is_archived=0",("@id",id))).FirstOrDefault()??throw new ApiProblem(404,"Lịch không còn tồn tại.");
    static async Task Cancel(DbConnection db,DbTransaction tx,int id,long? futureAfter=null)
    {
        await Exec(db,tx,"""
        UPDATE n SET notification_state='pending_cancel',notification_error=NULL FROM dbo.device_notifications n JOIN dbo.reminder_occurrences o ON o.id=n.occurrence_id
        WHERE o.reminder_id=@id AND o.status='pending' AND (@after IS NULL OR o.scheduled_at_utc>@after);
        UPDATE dbo.reminder_occurrences SET status='cancelled' WHERE reminder_id=@id AND status='pending' AND (@after IS NULL OR scheduled_at_utc>@after);
        """,("@id",id),("@after",futureAfter));
    }
    static async Task AddTimes(DbConnection db,DbTransaction tx,int id,IEnumerable<long> times,long now)
    {
        foreach(var at in times)await Exec(db,tx,"INSERT dbo.reminder_occurrences(reminder_id,scheduled_at_utc,status,created_at_utc) VALUES(@id,@at,'pending',@now)",("@id",id),("@at",at),("@now",now));
    }
    public Task<int> SaveCare(int? id,CareInput input,string key) => Mutation(key,$"care:{id}:"+JsonSerializer.Serialize(input,Json),async(db,tx)=>{
        var now=DateTimeOffset.UtcNow;var times=Rules.Times(input,now,id is null);
        if(id is not null){await RequireCare(db,tx,id.Value);await Cancel(db,tx,id.Value,now.ToUnixTimeMilliseconds());}
        (string,object?)[] args=[("@id",id),("@type",input.Type),("@title",input.Title.Trim()),("@note",input.Note?.Trim()??""),("@repeat",input.RepeatRule),("@start",input.StartDate),("@end",input.EndDate),("@time",input.LocalTime),("@enabled",input.IsEnabled),("@now",now.ToUnixTimeMilliseconds())];
        int savedId;
        if(id is null)savedId=await Insert(db,tx,"INSERT dbo.care_reminders(profile_id,type,title,note,repeat_rule,start_date,end_date,local_time,is_enabled,created_at_utc,updated_at_utc) VALUES(1,@type,@title,@note,@repeat,@start,@end,@time,@enabled,@now,@now)",args);
        else {savedId=id.Value;await Exec(db,tx,"UPDATE dbo.care_reminders SET type=@type,title=@title,note=@note,repeat_rule=@repeat,start_date=@start,end_date=@end,local_time=@time,is_enabled=@enabled,updated_at_utc=@now WHERE id=@id",args);}
        if(input.IsEnabled)await AddTimes(db,tx,savedId,times,now.ToUnixTimeMilliseconds());return savedId;
    });
    public Task<int> SetEnabled(int id,bool enabled,string key) => Mutation(key,$"enabled:{id}:{enabled}",async(db,tx)=>{
        var row=await RequireCare(db,tx,id);if((int)row["is_enabled"]! == (enabled?1:0))return id;var now=DateTimeOffset.UtcNow;
        if(enabled) {
            var input=new CareInput((string)row["type"]!,(string)row["title"]!,(string)row["start_date"]!,(string)row["end_date"]!,(string)row["local_time"]!,(string)row["repeat_rule"]!);
            await AddTimes(db,tx,id,Rules.Times(input,now,false),now.ToUnixTimeMilliseconds());
        }else await Cancel(db,tx,id);
        await Exec(db,tx,"UPDATE dbo.care_reminders SET is_enabled=@enabled,updated_at_utc=@now WHERE id=@id",("@enabled",enabled),("@now",now.ToUnixTimeMilliseconds()),("@id",id));return id;
    });
    public Task<int> Archive(int id,string key) => Mutation(key,$"archive:{id}",async(db,tx)=>{
        await RequireCare(db,tx,id);await Cancel(db,tx,id);await Exec(db,tx,"UPDATE dbo.care_reminders SET is_archived=1,is_enabled=0,updated_at_utc=@now WHERE id=@id",("@now",DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()),("@id",id));return id;
    });
    public Task<List<Dictionary<string,object?>>> Occurrences(string device,int? reminderId,long? from,long? to) => Query(OccurrenceSelect+" WHERE (@reminder IS NULL OR o.reminder_id=@reminder) AND (@from IS NULL OR (o.scheduled_at_utc>=@from AND o.scheduled_at_utc<@to AND o.status<>'cancelled')) ORDER BY o.scheduled_at_utc,o.id",("@device",device),("@reminder",reminderId),("@from",from),("@to",to));
    public async Task<object?> Occurrence(string device,int id) => (await Query(OccurrenceSelect+" WHERE o.id=@id",("@device",device),("@id",id))).FirstOrDefault();
    public Task<int> Resolve(int id,string status,string key) => Mutation(key,$"resolve:{id}:{status}",async(db,tx)=>{
        var row=(await Rows(db,tx,"SELECT * FROM dbo.reminder_occurrences WHERE id=@id",("@id",id))).FirstOrDefault()??throw new ApiProblem(404,"Lần nhắc không còn tồn tại.");var now=DateTimeOffset.UtcNow;
        if(!Rules.Resolve((string)row["status"]!,(long)row["scheduled_at_utc"]!,status,now))return id;
        await Exec(db,tx,"UPDATE dbo.reminder_occurrences SET status=@status,resolved_at_utc=@now WHERE id=@id; UPDATE dbo.device_notifications SET notification_state='pending_cancel',notification_error=NULL WHERE occurrence_id=@id",("@status",status),("@now",now.ToUnixTimeMilliseconds()),("@id",id));return id;
    });
    public async Task<object> Notifications(string device)
    {
        var cancel=await Query(OccurrenceSelect+" WHERE n.notification_state='pending_cancel' ORDER BY o.id",("@device",device));
        var future=await Query(OccurrenceSelect+" WHERE o.status='pending' AND o.scheduled_at_utc>@now AND r.is_enabled=1 AND r.is_archived=0 AND (n.notification_state IS NULL OR n.notification_state<>'pending_cancel') ORDER BY o.scheduled_at_utc,o.id",("@device",device),("@now",DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()));
        return new { cancellations=cancel,future };
    }
    public Task<bool> Notification(string device,int id,string action) => Transaction(async(db,tx)=>{
        var row=(await Rows(db,tx,OccurrenceSelect+" WHERE o.id=@id",("@device",device),("@id",id))).FirstOrDefault();if(row is null)return false;
        var state=(string)row["notification_state"]!;
        if(action=="cancel_failed") {if(state!="pending_cancel")return false;await Exec(db,tx,"UPDATE dbo.device_notifications SET notification_error='cancel_failed' WHERE device_id=@device AND occurrence_id=@id",("@device",device),("@id",id));return true;}
        if(action=="cancelled") {if(state!="pending_cancel")return false;}
        else {
            if(action is not ("scheduled" or "schedule_failed" or "permission_denied" or "notification_unavailable" or "cancel_pending"))throw new ApiProblem(400,"Trạng thái thông báo không hợp lệ.");
            var active=await Rows(db,tx,"SELECT o.id FROM dbo.reminder_occurrences o JOIN dbo.care_reminders r ON r.id=o.reminder_id WHERE o.id=@id AND o.status='pending' AND o.scheduled_at_utc>@now AND r.is_enabled=1 AND r.is_archived=0",("@id",id),("@now",DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()));
            if(active.Count==0 || state=="pending_cancel")return false;
        }
        var next=action is "scheduled" or "cancelled"?action:"failed";var error=next=="failed"?action:null;
        await Exec(db,tx,"""
        UPDATE dbo.device_notifications SET notification_state=@state,notification_error=@error WHERE device_id=@device AND occurrence_id=@id;
        IF @@ROWCOUNT=0 INSERT dbo.device_notifications(device_id,occurrence_id,notification_state,notification_error) VALUES(@device,@id,@state,@error);
        """,("@device",device),("@id",id),("@state",next),("@error",error));return true;
    });
    public async Task<bool> Warnings(string device) => (await Query("SELECT COUNT(*) AS total FROM dbo.device_notifications n JOIN dbo.reminder_occurrences o ON o.id=n.occurrence_id WHERE n.device_id=@device AND n.notification_error IS NOT NULL AND (n.notification_state='pending_cancel' OR (o.status='pending' AND o.scheduled_at_utc>@now))",("@device",device),("@now",DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()))).Single()["total"] is int count && count>0;
}
