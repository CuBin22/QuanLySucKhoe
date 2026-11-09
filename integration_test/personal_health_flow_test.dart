import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../test/support/app_database.dart';

import 'package:suc_khoe_ca_nhan/features/profile/profile.dart';

import '../test/support/sqlite_profile_repository.dart';

import 'package:suc_khoe_ca_nhan/features/health/health_record.dart';

import '../test/support/sqlite_health_repository.dart';

import 'package:suc_khoe_ca_nhan/features/care/care_reminder.dart';

import '../test/support/sqlite_care_repository.dart';

import 'package:suc_khoe_ca_nhan/features/care/reminder_occurrence.dart';

// Integration of both repositories with a file database, not an OS delivery test.
void main() {
  sqfliteFfiInit();
  test('both workflows persist across database close and reopen', () async {
    final dir = await Directory.systemTemp.createTemp('health_flow_');
    addTearDown(() => dir.delete(recursive: true));
    final path = '${dir.path}/flow.db';
    var db = await openAppDatabase(factory: databaseFactoryFfi, path: path);
    final now = DateTime.utc(2026, 10, 31, 0);
    await SqliteProfileRepository(db)
        .save(const Profile(fullName: 'Integration demo', heightCm: 170));
    var health = SqliteHealthRepository(db, utcNow: () => now);
    final id = await health.save(
      HealthRecord(
        measuredAtUtc: now.subtract(const Duration(days: 1)),
        weightKg: 65,
      ),
    );
    final deleteId = await health.save(
      HealthRecord(measuredAtUtc: now, heartRate: 72),
    );
    await health.save(
      HealthRecord(
        id: id,
        measuredAtUtc: now.subtract(const Duration(days: 1)),
        weightKg: 66,
      ),
    );
    await health.delete(deleteId);
    await health.save(
      HealthRecord(measuredAtUtc: now, systolic: 120, diastolic: 80),
    );
    var care = SqliteCareRepository(db);
    final reminderId = await care.save(
      const CareReminder(
        type: ReminderType.medication,
        title: 'Demo',
        startDate: '2026-10-31',
        endDate: '2026-11-02',
        localTime: '08:00',
        repeatRule: RepeatRule.daily,
      ),
      nowUtc: now,
    );
    final occurrenceId = (await care.occurrencesFor(reminderId)).first.id;
    await care.resolve(
      occurrenceId,
      OccurrenceStatus.completed,
      nowUtc: now.add(const Duration(hours: 2)),
    );
    await db.close();
    db = await openAppDatabase(factory: databaseFactoryFfi, path: path);
    addTearDown(db.close);
    health = SqliteHealthRepository(db, utcNow: () => now);
    care = SqliteCareRepository(db);
    expect(
      (await SqliteProfileRepository(db).load())!.fullName,
      'Integration demo',
    );
    final latest = await health.latestByMetric();
    expect(latest[HealthMetric.weight]!.weightKg, 66);
    expect(latest[HealthMetric.bloodPressure]!.systolic, 120);
    expect(latest[HealthMetric.heartRate], isNull);
    final occurrences = await care.occurrencesFor(reminderId);
    expect(occurrences.length, 3);
    expect(occurrences.first.status, OccurrenceStatus.completed);
    expect(occurrences.first.id, occurrenceId);
  });
}
