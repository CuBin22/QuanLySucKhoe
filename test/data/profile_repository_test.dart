import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/app_database.dart';

import 'package:suc_khoe_ca_nhan/features/profile/profile.dart';

import '../support/sqlite_profile_repository.dart';

// Model the SQL grammar boundary of Android's pre-3.24 SQLite while all
// supported statements and transactions still execute against real SQLite.
class LegacySqliteDatabase implements Database {
  LegacySqliteDatabase(this.inner);
  final Database inner;
  @override
  Future<int> rawInsert(String sql, [List<Object?>? arguments]) {
    if (sql.contains('ON CONFLICT')) {
      throw UnsupportedError('SQLite before 3.24 does not support UPSERT');
    }
    return inner.rawInsert(sql, arguments);
  }

  @override
  Future<T> transaction<T>(
    Future<T> Function(Transaction txn) action, {
    bool? exclusive,
  }) => inner.transaction(action, exclusive: exclusive);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  sqfliteFfiInit();
  test(
    'profile create and update work with legacy Android SQL grammar',
    () async {
      final db = await openAppDatabase(
        factory: databaseFactoryFfi,
        path: inMemoryDatabasePath,
      );
      addTearDown(db.close);
      final repo = SqliteProfileRepository(LegacySqliteDatabase(db));
      await repo.save(const Profile(fullName: 'Demo', heightCm: 170));
      final created = (await db.query('profiles')).single['created_at_utc'];
      await db.insert('health_records', {
        'profile_id': 1,
        'measured_at_utc': 1,
        'heart_rate': 70,
        'created_at_utc': 1,
        'updated_at_utc': 1,
      });
      await repo.save(const Profile(fullName: 'Updated', heightCm: 171));
      expect((await db.query('profiles')).single['created_at_utc'], created);
      expect((await db.query('profiles')).single['height_cm'], 171);
      expect((await db.query('health_records')).length, 1);
    },
  );
  test(
    'saving twice updates singleton profile and survives database reopening',
    () async {
      final folder = Directory.systemTemp.createTempSync('health-test-');
      addTearDown(() => folder.deleteSync(recursive: true));
      final path = '${folder.path}/health.db';
      var db = await openAppDatabase(factory: databaseFactoryFfi, path: path);
      var repo = SqliteProfileRepository(db);
      expect(await repo.load(), isNull);
      await repo.save(const Profile(fullName: 'Người dùng thử', heightCm: 170));
      await repo.save(
        const Profile(
          fullName: 'Tên đã sửa',
          heightCm: 172,
          targetWeightKg: 65,
        ),
      );
      expect(
        (await db.rawQuery('SELECT COUNT(*) AS count FROM profiles'))
            .single['count'],
        1,
      );
      await db.close();
      db = await openAppDatabase(factory: databaseFactoryFfi, path: path);
      addTearDown(db.close);
      repo = SqliteProfileRepository(db);
      expect((await repo.load())?.fullName, 'Tên đã sửa');
      expect((await repo.load())?.heightCm, 172);
    },
  );
  test(
    'profile rejects blank name and non-finite height without creating a row',
    () async {
      final db = await openAppDatabase(
        factory: databaseFactoryFfi,
        path: inMemoryDatabasePath,
      );
      addTearDown(db.close);
      final repo = SqliteProfileRepository(db);
      await expectLater(
        repo.save(const Profile(fullName: ' ', heightCm: 170)),
        throwsFormatException,
      );
      await expectLater(
        repo.save(const Profile(fullName: 'Test', heightCm: double.nan)),
        throwsFormatException,
      );
      expect(await repo.load(), isNull);
    },
  );
}
