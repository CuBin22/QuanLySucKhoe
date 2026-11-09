namespace Health.Api;

public static class SelfTests
{
    public static int Run()
    {
        var passed = 0; var failed = 0;
        void Test(string name, Action action) { try { action(); passed++; Console.WriteLine($"PASS {name}"); } catch (Exception ex) { failed++; Console.WriteLine($"FAIL {name}: {ex.Message}"); } }
        static void Check(bool value) { if (!value) throw new Exception("Assertion failed"); }
        static void Reject(Action action) { try { action(); } catch (ApiProblem) { return; } throw new Exception("Expected validation rejection"); }
        var now = new DateTimeOffset(2026, 11, 2, 0, 0, 0, TimeSpan.Zero);
        CareInput Plan(string end = "2026-12-01", string time = "08:00") => new("medication", "Lịch thử", "2026-11-02", end, time, "daily");
        Test("Vietnamese profile and exact decimal accepted", () => Rules.Profile(new("Trương Kiến Phi", 170.123456789), now));
        Test("blank/nonfinite profile rejected", () => { Reject(() => Rules.Profile(new(" ", 170), now)); Reject(() => Rules.Profile(new("Demo", double.NaN), now)); });
        Test("future and invalid birth date rejected", () => { Reject(() => Rules.Profile(new("Demo",170,"2026-02-30"),now)); Reject(() => Rules.Profile(new("Demo",170,"2027-01-01"),now)); });
        Test("independent health metric accepts high precision", () => Rules.Health(new(now.ToUnixTimeMilliseconds(), WeightKg:65.23456789), now));
        Test("incomplete pressure and empty health rejected", () => { Reject(() => Rules.Health(new(1,Systolic:120),now));Reject(() => Rules.Health(new(1),now)); });
        Test("future measurement rejected by server clock", () => Reject(() => Rules.Health(new(now.AddMinutes(1).ToUnixTimeMilliseconds(),HeartRate:70),now)));
        Test("thirty-day daily schedule uses UTC plus seven", () => { var times=Rules.Times(Plan(),now,true);Check(times.Length==30);Check(times[0]==now.AddHours(1).ToUnixTimeMilliseconds()); });
        Test("thirty-one days invalid and appointment cannot repeat", () => {Reject(() => Rules.Times(Plan("2026-12-02"),now,true));Reject(() => Rules.Times(Plan() with {Type="appointment"},now,true)); });
        Test("past and malformed local schedule rejected", () => {Reject(() => Rules.Times(Plan(time:"25:00"),now,true));Reject(() => Rules.Times(Plan() with {StartDate="2026-11-01"},now,true)); });
        Test("resolve is due-only and same result idempotent", () => {Reject(() => Rules.Resolve("pending",now.AddSeconds(1).ToUnixTimeMilliseconds(),"completed",now));Check(!Rules.Resolve("completed",1,"completed",now));Reject(() => Rules.Resolve("completed",1,"skipped",now));Check(Rules.Resolve("pending",1,"completed",now)); });
        Test("empty legacy export accepted",()=>SqlStore.ValidateImport(System.Text.Json.JsonDocument.Parse("""{"format":"personal-health-sqlite-v1","tables":{"profiles":[],"health_records":[],"care_reminders":[],"reminder_occurrences":[]}}""").RootElement));
        Test("wrong legacy export rejected",()=>Reject(()=>SqlStore.ValidateImport(System.Text.Json.JsonDocument.Parse("{}").RootElement)));
        var hash=System.Security.Cryptography.SHA256.HashData(System.Text.Encoding.UTF8.GetBytes("private-key"));
        Test("authenticated device accepted in development",()=>RequestSecurity.Validate(true,false,hash,"private-key",new string('a',32)));
        Test("missing key and malformed device rejected",()=>{Reject(()=>RequestSecurity.Validate(true,false,hash,"",new string('a',32)));Reject(()=>RequestSecurity.Validate(true,false,hash,"private-key","arbitrary SQL"));});
        Test("production HTTP rejected",()=>Reject(()=>RequestSecurity.Validate(false,false,hash,"private-key",new string('a',32))));
        Console.WriteLine($"API_SELF_TEST_RESULT passed={passed} failed={failed}");
        return failed==0?0:1;
    }
}
