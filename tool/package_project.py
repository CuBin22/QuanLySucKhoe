"""Create the handover archive without SDK/cache, private DBs or host paths."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import hashlib, json

root=Path(__file__).resolve().parents[1]
out=root/'deliverables/do_an_sql_server.zip'
folders=['lib','android','windows','server','test','integration_test','tool','docs','deliverables']
files=['pubspec.yaml','pubspec.lock','analysis_options.yaml','README.md','DESIGN.md','UX-CONTRACT.md','premium-ui.json','.gitignore','.metadata']
excluded_dirs={'.gradle','.dart_tool','.idea','ephemeral','build','bin','obj','__pycache__','.symlinks','.local'}
current_tools={'build_sql_documents.py','export_sqlite.py','flutter.ps1','native_test_runner.dart',
               'package_project.py','package_windows.ps1','run_app.ps1','run_checks.ps1',
               'start_api.ps1','test_export_sqlite.py'}
selected=[root/x for x in files]
for folder in folders:
    for p in (root/folder).rglob('*'):
        if not p.is_file() or p.is_symlink():continue
        rel=p.relative_to(root)
        if any(x in excluded_dirs for x in rel.parts):continue
        if rel.parts[:2]==('deliverables','sqlite_archive') and p.name!='README.md':continue
        if rel.parts[0]=='tool' and p.name not in current_tools:continue
        if rel.parts[0]=='docs':
            if len(rel.parts)>1 and rel.parts[1]=='diagrams':continue
            if len(rel.parts)>1 and rel.parts[1]=='evidence' and (len(rel.parts)<3 or rel.parts[2]!='sql-server'):continue
            if len(rel.parts)>1 and rel.parts[1]=='superpowers' and '2026-11-02-sql-server' not in p.name:continue
            if p.name in {'demo-script.md','report-source.md','artifact-verification.md','final-review.md','testing.md'}:continue
        if p==out or p.name in {'local.properties','file-manifest.json','api-key.txt'} or p.suffix in {'.zip','.iml','.pyc','.pdb','.db','.sqlite','.sqlite3','.db3','.jks','.keystore','.msix'}:continue
        if p.name.endswith(('.db-wal','.db-shm','.db-journal')):continue
        selected.append(p)
manifest={str(p.relative_to(root)).replace('\\','/'):{'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(set(selected))}
(root/'deliverables/file-manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf8')
selected.append(root/'deliverables/file-manifest.json')
with ZipFile(out,'w',compression=ZIP_DEFLATED,compresslevel=6) as z:
    for p in sorted(set(selected)):
        z.write(p,'do_an_sql_server/'+p.relative_to(root).as_posix())
with ZipFile(out) as z:
    assert z.testzip() is None
    assert all('/.tooling/' not in n and (n.endswith('/sqlite_archive/README.md') or '/sqlite_archive/' not in n) and '/.local/' not in n and not n.endswith('.db') for n in z.namelist())
    required={'server/Health.Api/Health.Api.csproj','server/Health.Api/schema.sql',
              'lib/data/api_client.dart','deliverables/bao_cao_sql_server.docx',
              'deliverables/thuyet_trinh_sql_server.pptx',
              'deliverables/windows_sqlserver/suc_khoe_ca_nhan.exe',
              'docs/evidence/sql-server/api-self-tests.log'}
    assert required.issubset({n.removeprefix('do_an_sql_server/') for n in z.namelist()})
print(json.dumps({'file':str(out),'files':len(selected),'bytes':out.stat().st_size,'sha256':hashlib.sha256(out.read_bytes()).hexdigest()}))
