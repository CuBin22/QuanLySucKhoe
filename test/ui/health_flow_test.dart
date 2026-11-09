import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/app_database.dart';

import 'package:suc_khoe_ca_nhan/features/profile/profile.dart';

import '../support/sqlite_profile_repository.dart';

import 'package:suc_khoe_ca_nhan/features/health/health_record.dart';

import '../support/sqlite_health_repository.dart';

import 'test_host.dart';

class SlowHealthRepository extends SqliteHealthRepository {
  SlowHealthRepository(super.db);
  final gate = Completer<void>();
  int calls = 0;
  @override
  Future<int> save(HealthRecord record) async {
    calls++;
    await gate.future;
    return super.save(record);
  }
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
  tearDown(() async {
    if (db.isOpen) await db.close();
  });
  testWidgets('invalid weight stays in form with inline correction', (
    tester,
  ) async {
    await openHealthForm(tester, SqliteHealthRepository(db));
    await tester.enterText(find.byKey(const ValueKey('health-weight')), '0');
    await tester.ensureVisible(find.byKey(const ValueKey('save-editor')));
    await tester.tap(find.byKey(const ValueKey('save-editor')));
    await tester.pumpAndSettle();
    expect(find.text('Giá trị phải là số hữu hạn lớn hơn 0.'), findsOneWidget);
    expect(find.byKey(const ValueKey('health-weight')), findsOneWidget);
  });
  testWidgets('two taps cause only one persisted health record', (
    tester,
  ) async {
    final repo = SlowHealthRepository(db);
    await openHealthForm(tester, repo);
    await tester.enterText(find.byKey(const ValueKey('health-weight')), '65,5');
    await tester.ensureVisible(find.byKey(const ValueKey('save-editor')));
    await tester.tap(find.byKey(const ValueKey('save-editor')));
    await tester.tap(find.byKey(const ValueKey('save-editor')));
    await tester.pump();
    expect(repo.calls, 1);
    repo.gate.complete();
    await pumpDatabase(tester);
    final count = await tester.runAsync(
      () => db.rawQuery('SELECT COUNT(*) AS n FROM health_records'),
    );
    expect(count!.single['n'], 1);
  });
  testWidgets(
    'database failure preserves entered weight and gives a retryable error',
    (tester) async {
      await openHealthForm(tester, SqliteHealthRepository(db));
      await tester.enterText(
        find.byKey(const ValueKey('health-weight')),
        '65,5',
      );
      await tester.runAsync(db.close);
      await tester.ensureVisible(find.byKey(const ValueKey('save-editor')));
      await tester.tap(find.byKey(const ValueKey('save-editor')));
      await pumpDatabase(tester);
      expect(find.textContaining('Không lưu được dữ liệu'), findsOneWidget);
      expect(find.text('65,5'), findsOneWidget);
    },
  );
}
