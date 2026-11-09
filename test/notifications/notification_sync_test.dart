import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/app_database.dart';

import 'package:suc_khoe_ca_nhan/features/profile/profile.dart';

import '../support/sqlite_profile_repository.dart';

import 'package:suc_khoe_ca_nhan/features/care/care_reminder.dart';

import '../support/sqlite_care_repository.dart';

import 'package:suc_khoe_ca_nhan/features/care/reminder_occurrence.dart';
import 'package:suc_khoe_ca_nhan/notifications/notification_port.dart';

import '../support/notification_sync.dart';

import 'fake_notification_port.dart';

void main() {
  sqfliteFfiInit();
  late Database db;
  late SqliteCareRepository repo;
  late FakeNotificationPort port;
  late NotificationSync sync;
  late DateTime now;
  CareReminder plan({int? id}) => CareReminder(
    id: id,
    type: ReminderType.medication,
    title: 'Private demo',
    startDate: '2026-10-31',
    endDate: '2026-10-31',
    localTime: '08:00',
  );
  setUp(() async {
    now = DateTime.utc(2026, 10, 31);
    db = await openAppDatabase(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    await SqliteProfileRepository(db)
        .save(const Profile(fullName: 'Demo', heightCm: 170));
    repo = SqliteCareRepository(db);
    port = FakeNotificationPort();
    sync = NotificationSync(db, port, utcNow: () => now);
  });
  tearDown(() => db.close());
  test(
    'permission denial preserves schedule and records a retryable warning',
    () async {
      final id = await repo.save(plan(), nowUtc: now);
      port.permission = NotificationPermission.denied;
      await sync.reconcile();
      expect((await repo.list()).length, 1);
      expect(
        (await repo.occurrencesFor(id)).single.notificationState,
        'failed',
      );
      expect(port.events, isEmpty);
    },
  );
  test(
    'repeated and concurrent reconciliation never duplicates an OS schedule',
    () async {
      final id = await repo.save(plan(), nowUtc: now);
      final item = (await repo.occurrencesFor(id)).single;
      await Future.wait([sync.reconcile(), sync.reconcile()]);
      await NotificationSync(db, port, utcNow: () => now).reconcile();
      expect(port.events, ['schedule:${item.id}']);
      expect(
        (await repo.occurrencesFor(id)).single.notificationState,
        'scheduled',
      );
    },
  );
  test('expired occurrence is never replayed at startup', () async {
    await repo.save(plan(), nowUtc: now);
    now = now.add(const Duration(hours: 2));
    await sync.reconcile();
    expect(port.events, isEmpty);
  });
  test('failed cancellation blocks replacement and retry cancels old before scheduling new', () async {
    final id = await repo.save(plan(), nowUtc: now);
    final old = (await repo.occurrencesFor(id)).single;
    await sync.reconcile();
    port.events.clear();
    await repo.setEnabled(id, false, nowUtc: now);
    await repo.setEnabled(id, true, nowUtc: now);
    final fresh = (await repo.occurrencesFor(id)).last;
    port.failCancel.add(old.id);
    await sync.reconcile();
    expect(port.events, ['cancel:${old.id}']);
    expect(
      (await repo.occurrencesFor(id)).first.notificationState,
      'pending_cancel',
    );
    port.events.clear();
    port.failCancel.clear();
    await sync.reconcile();
    expect(port.events, ['cancel:${old.id}', 'schedule:${fresh.id}']);
  });
  test(
    'completed occurrence cancellation failure remains pending for retry',
    () async {
      final id = await repo.save(plan(), nowUtc: now);
      final item = (await repo.occurrencesFor(id)).single;
      await sync.reconcile();
      port.events.clear();
      now = now.add(const Duration(hours: 2));
      await repo.resolve(item.id, OccurrenceStatus.completed, nowUtc: now);
      port.failCancel.add(item.id);
      await sync.reconcile();
      expect(
        (await repo.occurrencesFor(id)).single.notificationState,
        'pending_cancel',
      );
      expect(
        (await repo.occurrencesFor(id)).single.status,
        OccurrenceStatus.completed,
      );
      port.failCancel.clear();
      await sync.reconcile();
      expect(
        (await repo.occurrencesFor(id)).single.notificationState,
        'cancelled',
      );
    },
  );
  test('schedule failure is retried without leaking its exception text into database', () async {
    final id = await repo.save(plan(), nowUtc: now);
    port.failSchedule = true;
    await sync.reconcile();
    final failed = (await repo.occurrencesFor(id)).single;
    expect(failed.notificationState, 'failed');
    expect(failed.notificationError, 'schedule_failed');
    port.failSchedule = false;
    await sync.reconcile();
    expect(
      (await repo.occurrencesFor(id)).single.notificationState,
      'scheduled',
    );
  });
}
