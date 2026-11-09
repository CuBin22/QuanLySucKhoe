"""Regression: packaging preserves working DBs and never includes them."""
from pathlib import Path
from zipfile import ZipFile
import subprocess
import uuid

root=Path(__file__).resolve().parents[1]
fixture=root/'.tooling'/f'package-regression-{uuid.uuid4().hex}'
personal=fixture/'windows_portable/data/personal_health.db'
personal.parent.mkdir(parents=True)
personal.write_bytes(b'PRIVATE DATABASE SENTINEL')
(personal.parent/'personal_health.db-wal').write_bytes(b'PRIVATE SIDECAR')
result=subprocess.run(['powershell','-NoProfile','-ExecutionPolicy','Bypass','-File',str(root/'tool/package_windows.ps1'),'-OutputRoot',str(fixture)],cwd=root,capture_output=True,text=True)
assert result.returncode==0,result.stdout+result.stderr
assert personal.read_bytes()==b'PRIVATE DATABASE SENTINEL'
fresh=[p for p in fixture.glob('windows_portable_*') if p.is_dir()]
assert len(fresh)==1
assert not list(fresh[0].rglob('*.db*'))
with ZipFile(fixture/'so_suc_khoe_unsigned.msix') as z:
    assert z.testzip() is None
    assert not any('.db' in n.lower() or '.sqlite' in n.lower() for n in z.namelist())
    assert b'PRIVATE DATABASE SENTINEL' not in b''.join(z.read(n) for n in z.namelist())
print('PACKAGING_REGRESSION PASS: existing DB/sidecar preserved; new portable and MSIX contain no databases')
