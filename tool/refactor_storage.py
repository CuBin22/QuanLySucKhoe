"""One-time migration of SQLite persistence to test-only adapters."""
from pathlib import Path
import re
root=Path(__file__).resolve().parents[1]
support=root/'test/support';support.mkdir(parents=True,exist_ok=True)
def imports(source,original):
    def replace(m):
        uri=m.group(1)
        if uri.startswith('.'):
            target=(original.parent/uri).resolve().relative_to(root/'lib').as_posix()
            return "import 'package:suc_khoe_ca_nhan/"+target+"';"
        return m.group(0)
    return re.sub(r"import '([^']+)';",replace,source)
contracts={
 'profile':"""import 'profile.dart';
abstract class ProfileRepository {
 Future<Profile?> load();
 Future<void> save(Profile profile);
}
""",
 'health':"""import 'health_record.dart';
abstract class HealthRepository {
 Future<int> save(HealthRecord record);
 Future<void> delete(int id);
 Future<List<HealthRecord>> list({required DateTime fromUtc,required DateTime toUtc});
 Future<Map<HealthMetric,HealthRecord>> latestByMetric();
}
""",
 'care':"""import 'care_reminder.dart';
import 'reminder_occurrence.dart';
abstract class CareRepository {
 Future<int> save(CareReminder reminder,{required DateTime nowUtc});
 Future<void> setEnabled(int id,bool enabled,{required DateTime nowUtc});
 Future<void> archive(int id,{required DateTime nowUtc});
 Future<void> resolve(int occurrenceId,OccurrenceStatus result,{required DateTime nowUtc});
 Future<List<CareReminder>> list({ReminderType? type,bool? enabled,bool includeArchived=false});
 Future<CareReminder?> find(int id);
 Future<List<ReminderOccurrence>> occurrencesFor(int reminderId);
 Future<List<ReminderOccurrence>> occurrencesBetween({required DateTime fromUtc,required DateTime toUtc});
 Future<int?> reminderIdForOccurrence(int occurrenceId);
}
"""}
for feature,contract in contracts.items():
    p=root/f'lib/features/{feature}/{feature}_repository.dart'
    name=feature.title()+'Repository';source=p.read_text(encoding='utf-8-sig')
    assert f'class {name}' in source and 'sql' in source,'Run this migration only once'
    source=imports(source,p).replace(f'class {name} {{',f'class Sqlite{name} implements {name} {{').replace(f'  {name}(',f'  Sqlite{name}(')
    source=f"import 'package:suc_khoe_ca_nhan/features/{feature}/{feature}_repository.dart';\n"+source
    if feature=='care':
        n=source.rfind('}')
        source=source[:n]+"Future<int?> reminderIdForOccurrence(int id) async {final rows=await db.query('reminder_occurrences',columns:['reminder_id'],where:'id = ?',whereArgs:[id]);return rows.isEmpty?null:rows.single['reminder_id'] as int;}\n"+source[n:]
    (support/f'sqlite_{feature}_repository.dart').write_text(source,encoding='utf8')
    p.write_text(contract,encoding='utf8')
for name in ['app_database.dart','schema.dart','demo_seed.dart']:
    p=root/'lib/data'/name;source=p.read_text(encoding='utf-8-sig')
    if name=='demo_seed.dart':
        source=imports(source,p)
        for feature in contracts:
            source=source.replace(f"import 'package:suc_khoe_ca_nhan/features/{feature}/{feature}_repository.dart';",f"import 'sqlite_{feature}_repository.dart';")
            source=source.replace(feature.title()+'Repository(', 'Sqlite'+feature.title()+'Repository(')
    if name=='app_database.dart':
        source=source.replace("import 'package:sqflite/sqflite.dart' as mobile;",'')
        source=re.sub(r"if \(factory == null\) \{.*?\n  \}","if(factory==null){desktop.sqfliteFfiInit();factory=desktop.databaseFactoryFfi;}",source,count=1,flags=re.S)
    (support/name).write_text(source,encoding='utf8');p.unlink()
for p in list((root/'test').rglob('*.dart'))+list((root/'integration_test').rglob('*.dart')):
    if support in p.parents:continue
    source=p.read_text(encoding='utf-8-sig')
    for feature in contracts:
        name=feature.title()+'Repository'
        uri=f'features/{feature}/{feature}_repository.dart'
        relative=Path(__import__('os').path.relpath(support/f'sqlite_{feature}_repository.dart',p.parent)).as_posix()
        source=source.replace(f"import 'package:suc_khoe_ca_nhan/{uri}';",f"import '{relative}';")
        source=re.sub(r'\b'+name+r'\b','Sqlite'+name,source)
    for original,local in [('data/app_database.dart','app_database.dart'),('data/demo_seed.dart','demo_seed.dart'),('app.dart','legacy_app.dart'),('notifications/notification_sync.dart','notification_sync.dart')]:
        relative=Path(__import__('os').path.relpath(support/local,p.parent)).as_posix()
        source=source.replace(f"import 'package:suc_khoe_ca_nhan/{original}';",f"import '{relative}';")
    # Public UI helper accepts the repository contract, including remote stores.
    if p.name=='test_host.dart':
        source=source.replace("import '../support/sqlite_health_repository.dart';","import 'package:suc_khoe_ca_nhan/features/health/health_repository.dart';").replace('SqliteHealthRepository repository','HealthRepository repository')
    p.write_text(source,encoding='utf8')
print('Moved SQLite implementations to test/support and updated legacy test imports')
