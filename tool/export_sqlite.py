"""Read-only export of schema-v1 SQLite data for the SQL Server import CLI."""
import argparse
import json
import sqlite3
from contextlib import closing
from pathlib import Path

TABLES=('profiles','health_records','care_reminders','reminder_occurrences')

def export(source: Path, destination: Path):
    source=source.resolve(strict=True)
    if destination.exists(): raise ValueError('Output already exists; choose another filename.')
    with closing(sqlite3.connect(source.as_uri()+'?mode=ro',uri=True)) as db:
        db.row_factory=sqlite3.Row
        if db.execute('PRAGMA user_version').fetchone()[0]!=1: raise ValueError('Only SQLite schema version 1 is supported.')
        db.execute('BEGIN')
        tables={table:[dict(row) for row in db.execute(f'SELECT * FROM {table} ORDER BY id')] for table in TABLES}
        db.execute('COMMIT')
    payload={'format':'personal-health-sqlite-v1','tables':tables}
    content=json.dumps(payload,ensure_ascii=False,allow_nan=False,indent=2)
    destination.parent.mkdir(parents=True,exist_ok=True)
    with destination.open('x',encoding='utf8') as output: output.write(content)
    return {table:len(rows) for table,rows in tables.items()}

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('sqlite_file',type=Path);parser.add_argument('output_json',type=Path)
    args=parser.parse_args()
    try: print(json.dumps(export(args.sqlite_file,args.output_json)))
    except (ValueError,sqlite3.Error,OSError) as error: parser.exit(1,f'Export failed: {error}\n')
