import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/legacy_app.dart';
import '../support/app_database.dart';

import 'package:suc_khoe_ca_nhan/features/profile/profile.dart';

import '../support/sqlite_profile_repository.dart';

import '../notifications/fake_notification_port.dart';
import 'test_host.dart';

void main() {
  sqfliteFfiInit();
  testWidgets(
    'phone tablet desktop resize and large text preserve unsaved form',
    (tester) async {
      final db = (await tester.runAsync(
        () => openAppDatabase(
          factory: databaseFactoryFfi,
          path: inMemoryDatabasePath,
        ),
      ))!;
      addTearDown(db.close);
      await tester.runAsync(
        () =>
            SqliteProfileRepository(db)
                .save(const Profile(fullName: 'Demo', heightCm: 170)),
      );
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        HealthApp(database: db, notifications: FakeNotificationPort()),
      );
      await pumpDatabase(tester);
      expect(find.byType(NavigationBar), findsOneWidget);
      await tester.tap(find.text('Chỉ số').last);
      await pumpDatabase(tester);
      await tester.tap(find.byKey(const ValueKey('add-health')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('health-weight')),
        '67,2',
      );
      for (final width in [768.0, 1280.0]) {
        tester.view.physicalSize = Size(width, 900);
        await tester.pumpAndSettle();
        expect(find.text('67,2'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      tester.view.physicalSize = const Size(360, 900);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(BackButton).last);
      await tester.pumpAndSettle();
      expect(find.text('Bỏ thay đổi?'), findsOneWidget);
      await tester.tap(find.text('Tiếp tục nhập'));
      await tester.pumpAndSettle();
      expect(find.text('67,2'), findsOneWidget);
    },
  );
}
