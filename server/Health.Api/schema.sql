-- SQL Server 2016+. Run against a NEW PersonalHealth database, never master.
SET XACT_ABORT ON;
IF OBJECT_ID(N'dbo.server_settings',N'U') IS NULL AND
 (OBJECT_ID(N'dbo.profiles',N'U') IS NOT NULL OR OBJECT_ID(N'dbo.health_records',N'U') IS NOT NULL OR OBJECT_ID(N'dbo.care_reminders',N'U') IS NOT NULL OR OBJECT_ID(N'dbo.reminder_occurrences',N'U') IS NOT NULL)
 THROW 51000,'Target contains existing tables without application metadata. Choose an empty database.',1;
BEGIN TRANSACTION;
IF OBJECT_ID(N'dbo.server_settings',N'U') IS NULL
BEGIN
 CREATE TABLE dbo.server_settings(id int NOT NULL PRIMARY KEY CHECK(id=1), backend_id uniqueidentifier NOT NULL DEFAULT NEWID(), schema_version int NOT NULL CHECK(schema_version=1));
 INSERT dbo.server_settings(id,schema_version) VALUES(1,1);
END;
IF OBJECT_ID(N'dbo.profiles',N'U') IS NULL
 CREATE TABLE dbo.profiles(
 id int NOT NULL PRIMARY KEY CHECK(id=1), full_name nvarchar(200) NOT NULL CHECK(LEN(LTRIM(RTRIM(full_name)))>0), birth_date date NULL,
 height_cm float(53) NOT NULL CHECK(height_cm>0 AND height_cm<1e308), target_weight_kg float(53) NULL CHECK(target_weight_kg IS NULL OR (target_weight_kg>0 AND target_weight_kg<1e308)),
 created_at_utc bigint NOT NULL, updated_at_utc bigint NOT NULL);
IF OBJECT_ID(N'dbo.health_records',N'U') IS NULL
BEGIN
 CREATE TABLE dbo.health_records(
 id int IDENTITY(1,1) NOT NULL PRIMARY KEY, profile_id int NOT NULL REFERENCES dbo.profiles(id), measured_at_utc bigint NOT NULL,
 weight_kg float(53) NULL CHECK(weight_kg IS NULL OR (weight_kg>0 AND weight_kg<1e308)), height_cm_snapshot float(53) NULL,
 systolic int NULL, diastolic int NULL, heart_rate int NULL CHECK(heart_rate IS NULL OR heart_rate>0), note nvarchar(4000) NOT NULL DEFAULT N'',
 created_at_utc bigint NOT NULL, updated_at_utc bigint NOT NULL,
 CHECK(weight_kg IS NOT NULL OR systolic IS NOT NULL OR heart_rate IS NOT NULL),
 CHECK((systolic IS NULL AND diastolic IS NULL) OR (systolic IS NOT NULL AND diastolic IS NOT NULL AND systolic>diastolic AND diastolic>0)),
 CHECK((weight_kg IS NULL AND height_cm_snapshot IS NULL) OR (weight_kg IS NOT NULL AND height_cm_snapshot IS NOT NULL AND height_cm_snapshot>0 AND height_cm_snapshot<1e308)));
 CREATE INDEX health_time ON dbo.health_records(measured_at_utc DESC,id DESC);
END;
IF OBJECT_ID(N'dbo.care_reminders',N'U') IS NULL
 CREATE TABLE dbo.care_reminders(
 id int IDENTITY(1,1) NOT NULL PRIMARY KEY, profile_id int NOT NULL REFERENCES dbo.profiles(id),
 type nvarchar(20) NOT NULL CHECK(type IN(N'medication',N'appointment')), title nvarchar(200) NOT NULL CHECK(LEN(LTRIM(RTRIM(title)))>0), note nvarchar(4000) NOT NULL DEFAULT N'',
 repeat_rule nvarchar(10) NOT NULL CHECK(repeat_rule IN(N'none',N'daily')), start_date date NOT NULL,end_date date NOT NULL, local_time char(5) NOT NULL,
 timezone_id nvarchar(40) NOT NULL DEFAULT N'Asia/Ho_Chi_Minh' CHECK(timezone_id=N'Asia/Ho_Chi_Minh'),
 is_enabled bit NOT NULL DEFAULT 1,is_archived bit NOT NULL DEFAULT 0,created_at_utc bigint NOT NULL,updated_at_utc bigint NOT NULL,
 CHECK(type<>N'appointment' OR repeat_rule=N'none'), CHECK(DATEDIFF(day,start_date,end_date) BETWEEN 0 AND 29),
 CHECK(repeat_rule<>N'none' OR start_date=end_date), CHECK(TRY_CONVERT(time(0),local_time) IS NOT NULL AND LEN(local_time)=5));
IF OBJECT_ID(N'dbo.reminder_occurrences',N'U') IS NULL
BEGIN
 CREATE TABLE dbo.reminder_occurrences(
 id int IDENTITY(1,1) NOT NULL PRIMARY KEY, reminder_id int NOT NULL REFERENCES dbo.care_reminders(id),scheduled_at_utc bigint NOT NULL,
 status nvarchar(10) NOT NULL CHECK(status IN(N'pending',N'completed',N'skipped',N'cancelled')),resolved_at_utc bigint NULL,created_at_utc bigint NOT NULL);
 CREATE UNIQUE INDEX occurrence_unique ON dbo.reminder_occurrences(reminder_id,scheduled_at_utc) WHERE status<>N'cancelled';
 CREATE INDEX occurrence_time ON dbo.reminder_occurrences(scheduled_at_utc,status);
END;
IF OBJECT_ID(N'dbo.device_notifications',N'U') IS NULL
 CREATE TABLE dbo.device_notifications(
 device_id varchar(64) NOT NULL,occurrence_id int NOT NULL REFERENCES dbo.reminder_occurrences(id),
 notification_state varchar(20) NOT NULL CHECK(notification_state IN('pending_schedule','scheduled','pending_cancel','cancelled','failed')),
 notification_error varchar(64) NULL, PRIMARY KEY(device_id,occurrence_id));
IF OBJECT_ID(N'dbo.api_requests',N'U') IS NULL
 CREATE TABLE dbo.api_requests(request_id uniqueidentifier NOT NULL PRIMARY KEY,operation_hash char(64) NOT NULL,result_id int NOT NULL,created_at_utc bigint NOT NULL);
COMMIT;
