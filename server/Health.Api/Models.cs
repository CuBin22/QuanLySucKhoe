using System.Globalization;

namespace Health.Api;

public sealed record ProfileInput(string FullName, double HeightCm, string? BirthDate = null, double? TargetWeightKg = null);
public sealed record HealthInput(long MeasuredAtUtc, double? WeightKg = null, int? Systolic = null, int? Diastolic = null, int? HeartRate = null, string? Note = null);
public sealed record CareInput(string Type, string Title, string StartDate, string EndDate, string LocalTime, string RepeatRule = "none", string? Note = null, bool IsEnabled = true);
public sealed record EnabledInput(bool IsEnabled);
public sealed record ResolutionInput(string Status);
public sealed record NotificationInput(string Action);
public sealed class ApiProblem(int status, string message) : Exception(message) { public int Status { get; } = status; }

public static class Rules
{
    static void Require(bool condition, string message) { if (!condition) throw new ApiProblem(400,message); }
    static bool Positive(double? value) => value is > 0 && double.IsFinite(value.Value) && value < 1e308;
    public static DateOnly Date(string text) {
        Require(DateOnly.TryParseExact(text,"yyyy-MM-dd",CultureInfo.InvariantCulture,DateTimeStyles.None,out var date),"Ngày không hợp lệ.");
        return date;
    }
    public static void Profile(ProfileInput input, DateTimeOffset now) {
        Require(!string.IsNullOrWhiteSpace(input.FullName) && input.FullName.Trim().Length<=200,"Nhập họ tên tối đa 200 ký tự.");
        Require(Positive(input.HeightCm) && (input.TargetWeightKg is null || Positive(input.TargetWeightKg)),"Số đo phải hữu hạn và lớn hơn 0.");
        if(input.BirthDate is not null) Require(Date(input.BirthDate)<=DateOnly.FromDateTime(now.ToOffset(TimeSpan.FromHours(7)).Date),"Ngày sinh không được ở tương lai.");
    }
    public static void Health(HealthInput input, DateTimeOffset now) {
        Require(input.MeasuredAtUtc>=DateTimeOffset.MinValue.ToUnixTimeMilliseconds() && input.MeasuredAtUtc<=now.ToUnixTimeMilliseconds(),"Thời điểm đo không hợp lệ hoặc ở tương lai.");
        Require(input.WeightKg is not null || input.Systolic is not null || input.HeartRate is not null,"Nhập ít nhất một nhóm chỉ số.");
        Require(input.WeightKg is null || Positive(input.WeightKg),"Cân nặng phải hữu hạn và lớn hơn 0.");
        Require((input.Systolic is null && input.Diastolic is null) || (input.Systolic is not null && input.Diastolic is not null && input.Systolic>input.Diastolic && input.Diastolic>0),"Nhập đủ cặp huyết áp, tâm thu lớn hơn tâm trương.");
        Require(input.HeartRate is null || input.HeartRate>0,"Nhịp tim phải lớn hơn 0.");
        Require((input.Note?.Length??0)<=4000,"Ghi chú tối đa 4000 ký tự.");
    }
    public static long[] Times(CareInput input, DateTimeOffset now, bool creating, bool requireFuture=true) {
        Require(input.Type is "medication" or "appointment","Loại lịch không hợp lệ.");
        Require(!string.IsNullOrWhiteSpace(input.Title) && input.Title.Trim().Length<=200,"Nhập tên lịch tối đa 200 ký tự.");
        Require((input.Note?.Length??0)<=4000,"Ghi chú tối đa 4000 ký tự.");
        var start=Date(input.StartDate);var end=Date(input.EndDate);var days=end.DayNumber-start.DayNumber;
        Require(days is >=0 and <=29,"Khoảng lịch phải từ 1 đến 30 ngày.");
        Require(input.RepeatRule is "none" or "daily","Quy tắc lặp không hợp lệ.");
        Require(input.Type!="appointment" || input.RepeatRule=="none","Tái khám chỉ đặt một lần.");
        Require(input.RepeatRule!="none" || days==0,"Lịch một lần phải cùng ngày bắt đầu và kết thúc.");
        Require(TimeOnly.TryParseExact(input.LocalTime,"HH:mm",CultureInfo.InvariantCulture,DateTimeStyles.None,out var time),"Giờ không hợp lệ.");
        if(creating) Require(start>=DateOnly.FromDateTime(now.ToOffset(TimeSpan.FromHours(7)).Date),"Ngày bắt đầu không được trước hôm nay.");
        var result=new List<long>();
        for(var i=0;i<=days;i++) {
            var at=new DateTimeOffset(start.AddDays(i).ToDateTime(time),TimeSpan.FromHours(7));
            if(at>now) result.Add(at.ToUnixTimeMilliseconds());
        }
        Require(!requireFuture || result.Count>0,"Lịch không còn lần nhắc trong tương lai.");
        return result.ToArray();
    }
    public static bool Resolve(string current, long due, string result, DateTimeOffset now) {
        Require(result is "completed" or "skipped","Chọn hoàn thành hoặc bỏ qua.");
        if(current==result) return false;
        if(current!="pending") throw new ApiProblem(409,"Lần nhắc đã xử lý hoặc đã hủy.");
        Require(due<=now.ToUnixTimeMilliseconds(),"Chưa đến thời điểm xác nhận.");return true;
    }
}
