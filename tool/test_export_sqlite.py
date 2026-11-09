import hashlib
import importlib.util
from pathlib import Path
import sqlite3
import tempfile
import json
from contextlib import closing

spec=importlib.util.spec_from_file_location('export_sqlite',Path(__file__).with_name('export_sqlite.py'))
module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
with tempfile.TemporaryDirectory() as tmp:
    directory=Path(tmp);source=directory/'old.db';out=directory/'health.export.json'
    with closing(sqlite3.connect(source)) as db, db:
        db.execute('PRAGMA user_version=1')
        for name in module.TABLES: db.execute(f'CREATE TABLE {name}(id INTEGER PRIMARY KEY,note TEXT)')
        db.execute("INSERT INTO profiles VALUES(1,?)",('Trương Kiến Phi',))
    before=hashlib.sha256(source.read_bytes()).digest()
    counts=module.export(source,out)
    assert counts['profiles']==1 and json.loads(out.read_text(encoding='utf8'))['tables']['profiles'][0]['note']=='Trương Kiến Phi'
    assert hashlib.sha256(source.read_bytes()).digest()==before
    try: module.export(source,out)
    except ValueError: pass
    else: raise AssertionError('Must never overwrite an existing export')
    assert not (directory/'old.db-journal').exists()
print('EXPORT_TEST PASS: source unchanged, Unicode preserved, existing destination rejected')
