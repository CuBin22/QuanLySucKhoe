using System.Text.Json;

namespace Health.Api;
public sealed partial class SqlStore
{
    static readonly Dictionary<string,string[]> ImportColumns=new() {
      ["profiles"]=["id","full_name","birth_date","height_cm","target_weight_kg","created_at_utc","updated_at_utc"],
      ["health_records"]=["id","profile_id","measured_at_utc","weight_kg","height_cm_snapshot","systolic","diastolic","heart_rate","note","created_at_utc","updated_at_utc"],
      ["care_reminders"]=["id","profile_id","type","title","note","repeat_rule","start_date","end_date","local_time","timezone_id","is_enabled","is_archived","created_at_utc","updated_at_utc"],
      ["reminder_occurrences"]=["id","reminder_id","scheduled_at_utc","status","resolved_at_utc","created_at_utc"]
    };
    static bool LegacyBit(JsonElement value) => value.GetInt32() switch {0=>false,1=>true,_=>throw new ApiProblem(400,"Cờ dữ liệu cũ không hợp lệ.")};
    public static void ValidateImport(JsonElement payload)
    {
        try {
            if(payload.GetProperty("format").GetString()!="personal-health-sqlite-v1")throw new ApiProblem(400,"Sai định dạng tệp xuất.");
            var tables=payload.GetProperty("tables");var now=DateTimeOffset.UtcNow;
            foreach(var (table,columns) in ImportColumns) {
                var ids=new HashSet<int>();
                foreach(var row in tables.GetProperty(table).EnumerateArray()) {
                    var id=row.GetProperty("id").GetInt32();if(id<1 || !ids.Add(id))throw new ApiProblem(400,"ID dữ liệu cũ không hợp lệ hoặc bị trùng.");
                    foreach(var col in columns) {
                        var value=row.GetProperty(col);
                        if(col.EndsWith("_at_utc") && value.ValueKind!=JsonValueKind.Null)DateTimeOffset.FromUnixTimeMilliseconds(value.GetInt64());
                    }
                }
            }
            var profiles=tables.GetProperty("profiles");
            if(profiles.GetArrayLength()>1)throw new ApiProblem(400,"Chỉ hỗ trợ một hồ sơ cá nhân.");
            foreach(var row in profiles.EnumerateArray()) {
                if(row.GetProperty("id").GetInt32()!=1)throw new ApiProblem(400,"Hồ sơ phải có id=1.");
                Rules.Profile(row.Deserialize<ProfileInput>(Json)!,now);
            }
            foreach(var row in tables.GetProperty("health_records").EnumerateArray()) {
                if(profiles.GetArrayLength()!=1 || row.GetProperty("profile_id").GetInt32()!=1)throw new ApiProblem(400,"Số đo thiếu hồ sơ liên kết.");
                var health=row.Deserialize<HealthInput>(Json)!;Rules.Health(health,now);var snapshot=row.GetProperty("height_cm_snapshot");
                if(health.WeightKg is null ? snapshot.ValueKind!=JsonValueKind.Null : snapshot.ValueKind==JsonValueKind.Null || !double.IsFinite(snapshot.GetDouble()) || snapshot.GetDouble()<=0 || snapshot.GetDouble()>=1e308)throw new ApiProblem(400,"Snapshot chiều cao không hợp lệ.");
            }
            var reminderIds=new HashSet<int>();
            foreach(var row in tables.GetProperty("care_reminders").EnumerateArray()) {
                if(profiles.GetArrayLength()!=1 || row.GetProperty("profile_id").GetInt32()!=1)throw new ApiProblem(400,"Lịch thiếu hồ sơ liên kết.");
                if(row.GetProperty("timezone_id").GetString()!="Asia/Ho_Chi_Minh")throw new ApiProblem(400,"Múi giờ dữ liệu cũ không được hỗ trợ.");
                var care=new CareInput(row.GetProperty("type").GetString()!,row.GetProperty("title").GetString()!,row.GetProperty("start_date").GetString()!,row.GetProperty("end_date").GetString()!,row.GetProperty("local_time").GetString()!,row.GetProperty("repeat_rule").GetString()!,row.GetProperty("note").GetString(),LegacyBit(row.GetProperty("is_enabled")));
                LegacyBit(row.GetProperty("is_archived"));Rules.Times(care,now,false,requireFuture:false);reminderIds.Add(row.GetProperty("id").GetInt32());
            }
            foreach(var row in tables.GetProperty("reminder_occurrences").EnumerateArray()) {
                if(!reminderIds.Contains(row.GetProperty("reminder_id").GetInt32()))throw new ApiProblem(400,"Lần nhắc thiếu kế hoạch liên kết.");
                var status=row.GetProperty("status").GetString();
                if(status is not ("pending" or "completed" or "skipped" or "cancelled"))throw new ApiProblem(400,"Kết quả lần nhắc không hợp lệ.");
                if(status is "completed" or "skipped" && row.GetProperty("resolved_at_utc").ValueKind==JsonValueKind.Null)throw new ApiProblem(400,"Kết quả lần nhắc thiếu thời điểm xử lý.");
            }
        } catch(ApiProblem){throw;} catch(Exception ex) when(ex is JsonException or KeyNotFoundException or InvalidOperationException or FormatException or OverflowException or ArgumentOutOfRangeException) {
            throw new ApiProblem(400,"Tệp xuất SQLite thiếu trường hoặc chứa giá trị không hợp lệ.");
        }
    }
    public async Task ImportFile(string path)
    {
        if(new FileInfo(path).Length>20*1024*1024)throw new ApiProblem(400,"Tệp nhập tối đa 20 MB.");
        using var document=JsonDocument.Parse(await File.ReadAllTextAsync(path));ValidateImport(document.RootElement);
        var tables=document.RootElement.GetProperty("tables");
        await Transaction(async(db,tx)=>{
            foreach(var table in ImportColumns.Keys.Concat(new[]{"device_notifications","api_requests"})) {
                var rows=await Rows(db,tx,$"SELECT COUNT(*) AS total FROM dbo.{table}");
                if((int)rows[0]["total"]! !=0)throw new ApiProblem(409,"Chỉ nhập vào SQL Server rỗng. Dữ liệu hiện tại được giữ nguyên.");
            }
            foreach(var (table,columns) in ImportColumns) {
                var identity=table!="profiles";
                if(identity)await Exec(db,tx,$"SET IDENTITY_INSERT dbo.{table} ON");
                foreach(var row in tables.GetProperty(table).EnumerateArray()) {
                    var args=columns.Select((col,i)=>("@p"+i,LegacyValue(row.GetProperty(col)))).ToArray();
                    await Exec(db,tx,$"INSERT dbo.{table}({string.Join(',',columns)}) VALUES({string.Join(',',args.Select(a=>a.Item1))})",args);
                }
                if(identity)await Exec(db,tx,$"SET IDENTITY_INSERT dbo.{table} OFF");
            }
            return true;
        });
    }
    static object? LegacyValue(JsonElement value) => value.ValueKind switch {
        JsonValueKind.Null=>null,JsonValueKind.String=>value.GetString(),JsonValueKind.Number=>value.TryGetInt64(out var integer)?(object)integer:value.GetDouble(),_=>throw new ApiProblem(400,"Kiểu dữ liệu cũ không hợp lệ.")
    };
}
