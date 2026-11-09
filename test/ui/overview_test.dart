import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/legacy_app.dart';
import '../support/app_database.dart';

import 'package:suc_khoe_ca_nhan/domain/app_time.dart';
import 'package:suc_khoe_ca_nhan/features/profile/profile.dart';

import '../support/sqlite_profile_repository.dart';

import 'package:suc_khoe_ca_nhan/features/health/health_record.dart';

import '../support/sqlite_health_repository.dart';

import 'package:suc_khoe_ca_nhan/features/care/care_reminder.dart';

import '../support/sqlite_care_repository.dart';

import '../notifications/fake_notification_port.dart';
import 'test_host.dart';

void main() {
  sqfliteFfiInit();
  testWidgets('overview keeps independent latest values and lists today care', (
    tester,
  ) async {
    final db = (await tester.runAsync(
      () => openAppDatabase(
        factory: databaseFactoryFfi,
        path: inMemoryDatabasePath,
      ),
    ))!;
    addTearDown(db.close);
    await tester.runAsync(() async {
      final now = DateTime.now().toUtc();
      await SqliteProfileRepository(db)
          .save(const Profile(fullName: 'Demo', heightCm: 170));
      final health = SqliteHealthRepository(db);
      await health.save(
        HealthRecord(
          measuredAtUtc: now.subtract(const Duration(days: 1)),
          weightKg: 65,
        ),
      );
      await health.save(
        HealthRecord(measuredAtUtc: now, systolic: 120, diastolic: 80),
      );
      final wall = vietnamWallTime(now.add(const Duration(days: 1)));
      await SqliteCareRepository(db).save(
        CareReminder(
          type: ReminderType.appointment,
          title: 'Lịch hôm nay từ database',
          startDate: dateKey(wall),
          endDate: dateKey(wall),
          localTime: '12:00',
        ),
        nowUtc: now,
      );
      await db.update('reminder_occurrences', {
        'scheduled_at_utc': vietnamDayStart(now)
            .add(const Duration(hours: 12))
            .millisecondsSinceEpoch,
      });
    });
    await tester.pumpWidget(
      HealthApp(database: db, notifications: FakeNotificationPort()),
    );
    await pumpDatabase(tester);
    expect(find.text('65 kg'), findsOneWidget);
    expect(find.text('120/80 mmHg'), findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('overview-page')),
      const Offset(0, -650),
    );
    await pumpDatabase(tester);
    expect(find.textContaining('Lịch hôm nay từ database'), findsOneWidget);
  });
}
