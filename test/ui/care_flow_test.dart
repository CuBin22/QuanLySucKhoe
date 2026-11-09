import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/legacy_app.dart';
import '../support/app_database.dart';

import 'package:suc_khoe_ca_nhan/domain/app_time.dart';
import 'package:suc_khoe_ca_nhan/features/profile/profile.dart';

import '../support/sqlite_profile_repository.dart';
import '../support/sqlite_care_repository.dart';

import 'package:suc_khoe_ca_nhan/features/care/care_reminder.dart';
import 'package:suc_khoe_ca_nhan/features/care/reminder_occurrence.dart';
import 'package:suc_khoe_ca_nhan/notifications/notification_port.dart';

import '../notifications/fake_notification_port.dart';
import 'test_host.dart';

class LaunchPort extends FakeNotificationPort {
  LaunchPort(this.launch);
  final int launch;
  @override
  Future<int?> getLaunchOccurrenceId() async => launch;
}

void main() {
  sqfliteFfiInit();
  late Database db;
  setUp(() async {
    db = await openAppDatabase(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    await SqliteProfileRepository(db)
        .save(const Profile(fullName: 'Demo', heightCm: 170));
  });
  tearDown(() => db.close());
  testWidgets(
    'creating care schedule survives denied notification permission',
    (tester) async {
      final port = FakeNotificationPort()
        ..permission = NotificationPermission.denied;
      await tester.pumpWidget(HealthApp(database: db, notifications: port));
      await pumpDatabase(tester);
      await tester.tap(find.text('Lịch chăm sóc').last);
      await pumpDatabase(tester);
      await tester.tap(find.byKey(const ValueKey('add-care')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('care-title')),
        'Lịch thử giao diện',
      );
      await tester.ensureVisible(find.byKey(const ValueKey('save-editor')));
      await tester.tap(find.byKey(const ValueKey('save-editor')));
      await pumpDatabase(tester);
      expect(find.text('Lịch thử giao diện'), findsOneWidget);
      expect(find.textContaining('chưa bật được thông báo'), findsWidgets);
      expect(
        (await tester.runAsync(() => SqliteCareRepository(db).list()))!.length,
        1,
      );
    },
  );
  testWidgets(
    'cold-start notification opens target and only due occurrence can be completed',
    (tester) async {
      final now = DateTime.now().toUtc();
      final wall = vietnamWallTime(now.add(const Duration(minutes: 10)));
      final repo = SqliteCareRepository(db);
      final id = (await tester.runAsync(
        () => repo.save(
          CareReminder(
            type: ReminderType.appointment,
            title: 'Lịch mở từ thông báo',
            startDate: dateKey(wall),
            endDate: dateKey(wall),
            localTime:
                '${wall.hour.toString().padLeft(2, '0')}:${wall.minute.toString().padLeft(2, '0')}',
          ),
          nowUtc: now,
        ),
      ))!;
      final item = (await tester.runAsync(() => repo.occurrencesFor(id)))!
          .single;
      await tester.pumpWidget(
        HealthApp(database: db, notifications: LaunchPort(item.id)),
      );
      await pumpDatabase(tester);
      expect(find.text('Lịch mở từ thông báo'), findsWidgets);
      final button = find.byKey(ValueKey('complete-${item.id}'));
      expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
      await tester.runAsync(
        () => db.update(
          'reminder_occurrences',
          {
            'scheduled_at_utc': now
                .subtract(const Duration(minutes: 1))
                .millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [item.id],
        ),
      );
      await tester.tap(find.byKey(const ValueKey('care-refresh')));
      await pumpDatabase(tester);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await pumpDatabase(tester);
      expect(
        (await tester.runAsync(() => repo.occurrencesFor(id)))!.single.status,
        OccurrenceStatus.completed,
      );
      expect(find.text('Đã hoàn thành'), findsOneWidget);
    },
  );
  testWidgets(
    'unknown notification ID opens schedule list with an explanation',
    (tester) async {
      await tester.pumpWidget(
        HealthApp(database: db, notifications: LaunchPort(999)),
      );
      await pumpDatabase(tester);
      expect(find.textContaining('Lần nhắc không còn tồn tại'), findsWidgets);
      expect(find.byKey(const ValueKey('add-care')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('switching away from a dirty profile asks before discarding', (
    tester,
  ) async {
    await tester.pumpWidget(
      HealthApp(database: db, notifications: FakeNotificationPort()),
    );
    await pumpDatabase(tester);
    await tester.tap(find.text('Hồ sơ').last);
    await pumpDatabase(tester);
    await tester.enterText(
      find.byKey(const ValueKey('profile-name')),
      'Tên chưa lưu',
    );
    await tester.tap(find.text('Tổng quan').first);
    await tester.pumpAndSettle();
    expect(find.text('Bỏ thay đổi?'), findsOneWidget);
    await tester.tap(find.text('Tiếp tục nhập'));
    await tester.pumpAndSettle();
    expect(find.text('Tên chưa lưu'), findsOneWidget);
  });
}
