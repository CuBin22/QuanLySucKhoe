import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/app_database.dart';

import 'package:suc_khoe_ca_nhan/features/profile/profile.dart';

import '../support/sqlite_profile_repository.dart';

void main() {
  sqfliteFfiInit();
  test('SQLite rejects weight without a height snapshot', () async {
    final db = await openAppDatabase(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    addTearDown(db.close);
    await SqliteProfileRepository(db)
        .save(const Profile(fullName: 'Demo', heightCm: 170));
    await expectLater(
      db.insert('health_records', {
        'profile_id': 1,
        'measured_at_utc': 1,
        'weight_kg': 65,
        'created_at_utc': 1,
        'updated_at_utc': 1,
      }),
      throwsA(predicate((e) => e.toString().contains('CHECK'))),
    );
  });
  test(
    'database creates all four tables with schema version and foreign keys',
    () async {
      final db = await openAppDatabase(
        factory: databaseFactoryFfi,
        path: inMemoryDatabasePath,
      );
      addTearDown(db.close);
      expect(await db.getVersion(), 1);
      expect(
        (await db.rawQuery('PRAGMA foreign_keys')).single.values.single,
        1,
      );
      final tables = (await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      )).map((row) => row['name']);
      expect(
        tables,
        containsAll([
          'profiles',
          'health_records',
          'care_reminders',
          'reminder_occurrences',
        ]),
      );
      await expectLater(
        db.insert('health_records', {
          'profile_id': 99,
          'measured_at_utc': 1,
          'heart_rate': 70,
          'created_at_utc': 1,
          'updated_at_utc': 1,
        }),
        throwsA(predicate((e) => e.toString().contains('FOREIGN KEY'))),
      );
    },
  );
}
