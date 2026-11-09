const schemaStatements = <String>[
  '''CREATE TABLE profiles (
    id INTEGER PRIMARY KEY CHECK(id = 1),
    full_name TEXT NOT NULL CHECK(length(trim(full_name)) > 0),
    birth_date TEXT,
    height_cm REAL NOT NULL CHECK(height_cm > 0 AND height_cm < 1e308),
    target_weight_kg REAL CHECK(target_weight_kg IS NULL OR (target_weight_kg > 0 AND target_weight_kg < 1e308)),
    created_at_utc INTEGER NOT NULL, updated_at_utc INTEGER NOT NULL
  )''',
  '''CREATE TABLE health_records (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    profile_id INTEGER NOT NULL REFERENCES profiles(id),
    measured_at_utc INTEGER NOT NULL,
    weight_kg REAL CHECK(weight_kg IS NULL OR (weight_kg > 0 AND weight_kg < 1e308)),
    height_cm_snapshot REAL,
    systolic INTEGER, diastolic INTEGER, heart_rate INTEGER,
    note TEXT NOT NULL DEFAULT '',
    created_at_utc INTEGER NOT NULL, updated_at_utc INTEGER NOT NULL,
    CHECK(weight_kg IS NOT NULL OR systolic IS NOT NULL OR heart_rate IS NOT NULL),
    CHECK((systolic IS NULL AND diastolic IS NULL) OR (systolic IS NOT NULL AND diastolic IS NOT NULL AND systolic > diastolic AND diastolic > 0)),
    CHECK(heart_rate IS NULL OR heart_rate > 0),
    CHECK((weight_kg IS NULL AND height_cm_snapshot IS NULL) OR (weight_kg IS NOT NULL AND height_cm_snapshot IS NOT NULL AND height_cm_snapshot > 0 AND height_cm_snapshot < 1e308))
  )''',
  'CREATE INDEX health_time ON health_records(measured_at_utc DESC, id DESC)',
  '''CREATE TABLE care_reminders (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    profile_id INTEGER NOT NULL REFERENCES profiles(id),
    type TEXT NOT NULL CHECK(type IN ('medication','appointment')),
    title TEXT NOT NULL CHECK(length(trim(title)) > 0), note TEXT NOT NULL DEFAULT '',
    repeat_rule TEXT NOT NULL CHECK(repeat_rule IN ('none','daily')),
    start_date TEXT NOT NULL, end_date TEXT NOT NULL, local_time TEXT NOT NULL,
    timezone_id TEXT NOT NULL DEFAULT 'Asia/Ho_Chi_Minh',
    is_enabled INTEGER NOT NULL DEFAULT 1 CHECK(is_enabled IN (0,1)),
    is_archived INTEGER NOT NULL DEFAULT 0 CHECK(is_archived IN (0,1)),
    created_at_utc INTEGER NOT NULL, updated_at_utc INTEGER NOT NULL,
    CHECK(type != 'appointment' OR repeat_rule = 'none'),
    CHECK(julianday(end_date) - julianday(start_date) BETWEEN 0 AND 29)
  )''',
  '''CREATE TABLE reminder_occurrences (
    id INTEGER PRIMARY KEY AUTOINCREMENT CHECK(id BETWEEN 1 AND 2147483647),
    reminder_id INTEGER NOT NULL REFERENCES care_reminders(id),
    scheduled_at_utc INTEGER NOT NULL,
    status TEXT NOT NULL CHECK(status IN ('pending','completed','skipped','cancelled')),
    resolved_at_utc INTEGER,
    notification_state TEXT NOT NULL CHECK(notification_state IN ('pending_schedule','scheduled','pending_cancel','cancelled','failed')),
    notification_error TEXT,
    created_at_utc INTEGER NOT NULL
  )''',
  "CREATE UNIQUE INDEX occurrence_unique ON reminder_occurrences(reminder_id, scheduled_at_utc) WHERE status != 'cancelled'",
  'CREATE INDEX occurrence_time ON reminder_occurrences(scheduled_at_utc, status)',
];
