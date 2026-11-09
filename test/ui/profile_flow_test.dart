import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/legacy_app.dart';
import '../support/app_database.dart';
import '../support/sqlite_profile_repository.dart';

import '../notifications/fake_notification_port.dart';
import 'test_host.dart';

void main() {
  sqfliteFfiInit();
  testWidgets('first-run profile saves real data and opens overview', (
    tester,
  ) async {
    final db = (await tester.runAsync(
      () => openAppDatabase(
        factory: databaseFactoryFfi,
        path: inMemoryDatabasePath,
      ),
    ))!;
    addTearDown(db.close);
    await tester.pumpWidget(
      HealthApp(database: db, notifications: FakeNotificationPort()),
    );
    await pumpDatabase(tester);
    await tester.enterText(
      find.byKey(const ValueKey('profile-name')),
      'Người dùng demo',
    );
    await tester.enterText(find.byKey(const ValueKey('profile-height')), '170');
    await tester.ensureVisible(find.byKey(const ValueKey('save-editor')));
    await tester.tap(find.byKey(const ValueKey('save-editor')));
    await pumpDatabase(tester);
    expect(find.byKey(const ValueKey('overview-page')), findsOneWidget);
    expect(
      (await tester.runAsync(() => SqliteProfileRepository(db).load()))
          ?.fullName,
      'Người dùng demo',
    );
  });
}
