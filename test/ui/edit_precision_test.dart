import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/app_database.dart';

import 'package:suc_khoe_ca_nhan/features/profile/profile.dart';

import '../support/sqlite_profile_repository.dart';

import 'package:suc_khoe_ca_nhan/features/profile/profile_screen.dart';
import 'package:suc_khoe_ca_nhan/features/health/health_record.dart';

import '../support/sqlite_health_repository.dart';

import 'package:suc_khoe_ca_nhan/features/health/health_form.dart';

import 'test_host.dart';

void main() {
  sqfliteFfiInit();
  testWidgets('note-only edit preserves exact recorded weight', (tester) async {
    final db = (await tester.runAsync(
      () => openAppDatabase(
        factory: databaseFactoryFfi,
        path: inMemoryDatabasePath,
      ),
    ))!;
    addTearDown(db.close);
    final repo = SqliteHealthRepository(db);
    final now = DateTime.now().toUtc().subtract(const Duration(minutes: 1));
    await tester.runAsync(() async {
      await SqliteProfileRepository(db)
          .save(const Profile(fullName: 'Demo', heightCm: 170));
      await repo.save(HealthRecord(measuredAtUtc: now, weightKg: 65.23456789));
    });
    final record = (await tester.runAsync(
      () => repo.latestByMetric(),
    ))![HealthMetric.weight]!;
    await tester.pumpWidget(
      MaterialApp(
        home: HealthForm(repository: repo, initial: record),
      ),
    );
    await tester.enterText(find.byType(TextFormField).last, 'Changed note');
    await tester.ensureVisible(find.byKey(const ValueKey('save-editor')));
    await tester.tap(find.byKey(const ValueKey('save-editor')));
    await pumpDatabase(tester);
    expect(
      (await tester.runAsync(
        () => repo.latestByMetric(),
      ))![HealthMetric.weight]!.weightKg,
      65.23456789,
    );
  });
  testWidgets('name-only edit preserves profile height and small target', (
    tester,
  ) async {
    final db = (await tester.runAsync(
      () => openAppDatabase(
        factory: databaseFactoryFfi,
        path: inMemoryDatabasePath,
      ),
    ))!;
    addTearDown(db.close);
    final repo = SqliteProfileRepository(db);
    const initial = Profile(
      fullName: 'Demo',
      heightCm: 170.123456789,
      targetWeightKg: 0.0000001,
    );
    await tester.runAsync(() => repo.save(initial));
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileScreen(
          repository: repo,
          initial: initial,
          onSaved: () async {},
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('profile-name')),
      'Changed name',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('save-editor')));
    await tester.tap(find.byKey(const ValueKey('save-editor')));
    await pumpDatabase(tester);
    final saved = await tester.runAsync(repo.load);
    expect(saved!.fullName, 'Changed name');
    expect(saved.heightCm, initial.heightCm);
    expect(saved.targetWeightKg, initial.targetWeightKg);
  });
}
