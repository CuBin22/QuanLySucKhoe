import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/app_database.dart';
import '../support/demo_seed.dart';

import 'package:suc_khoe_ca_nhan/features/profile/profile.dart';

import '../support/sqlite_profile_repository.dart';

void main() {
  sqfliteFfiInit();
  test('explicit demo setup fills a fresh database without overwriting an existing profile', () async {
    final db = await openAppDatabase(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    addTearDown(db.close);
    expect(await seedDemoData(db), isTrue);
    expect(
      (await db.rawQuery('SELECT COUNT(*) AS n FROM health_records'))
          .single['n'],
      30,
    );
    await SqliteProfileRepository(db)
        .save(const Profile(fullName: 'Hồ sơ thật', heightCm: 170));
    expect(await seedDemoData(db), isFalse);
    expect((await SqliteProfileRepository(db).load())!.fullName, 'Hồ sơ thật');
    expect(
      (await db.rawQuery('SELECT COUNT(*) AS n FROM health_records'))
          .single['n'],
      30,
    );
  });
}
