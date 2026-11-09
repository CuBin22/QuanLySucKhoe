import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/app_database.dart';

import 'package:suc_khoe_ca_nhan/features/profile/profile.dart';

import '../support/sqlite_profile_repository.dart';

import 'package:suc_khoe_ca_nhan/features/health/health_record.dart';

import '../support/sqlite_health_repository.dart';

void main() {
  sqfliteFfiInit();
  late Database db;
  late SqliteHealthRepository repo;
  final now = DateTime.utc(2026, 10, 31, 12);
  setUp(() async {
    db = await openAppDatabase(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    await SqliteProfileRepository(db)
        .save(const Profile(fullName: 'Demo', heightCm: 170));
    repo = SqliteHealthRepository(db, utcNow: () => now);
  });
  tearDown(() => db.close());
  test('latest values are selected independently for each metric', () async {
    final weightId = await repo.save(
      HealthRecord(
        measuredAtUtc: now.subtract(const Duration(days: 1)),
        weightKg: 65,
      ),
    );
    final bpId = await repo.save(
      HealthRecord(measuredAtUtc: now, systolic: 120, diastolic: 80),
    );
    final latest = await repo.latestByMetric();
    expect(latest[HealthMetric.weight]?.id, weightId);
    expect(latest[HealthMetric.weight]?.weightKg, 65);
    expect(latest[HealthMetric.bloodPressure]?.id, bpId);
    expect(latest[HealthMetric.heartRate], isNull);
  });
  test('height snapshots survive profile edits and weight removal or addition is consistent', () async {
    final id = await repo.save(HealthRecord(measuredAtUtc: now, weightKg: 65));
    await SqliteProfileRepository(db)
        .save(const Profile(fullName: 'Demo', heightCm: 180));
    await repo.save(HealthRecord(id: id, measuredAtUtc: now, weightKg: 66));
    var rows = await repo.list(
      fromUtc: now.subtract(const Duration(days: 1)),
      toUtc: now.add(const Duration(days: 1)),
    );
    expect(rows.single.heightCmSnapshot, 170);
    await repo.save(HealthRecord(id: id, measuredAtUtc: now, heartRate: 70));
    rows = await repo.list(
      fromUtc: now.subtract(const Duration(days: 1)),
      toUtc: now.add(const Duration(days: 1)),
    );
    expect(rows.single.heightCmSnapshot, isNull);
    await repo.save(HealthRecord(id: id, measuredAtUtc: now, weightKg: 66));
    rows = await repo.list(
      fromUtc: now.subtract(const Duration(days: 1)),
      toUtc: now.add(const Duration(days: 1)),
    );
    expect(rows.single.heightCmSnapshot, 180);
  });
  test(
    'invalid record never writes and missing update or delete is explicit',
    () async {
      await expectLater(
        repo.save(HealthRecord(measuredAtUtc: now, systolic: 120)),
        throwsFormatException,
      );
      await expectLater(
        repo.save(HealthRecord(id: 999, measuredAtUtc: now, heartRate: 72)),
        throwsStateError,
      );
      await expectLater(repo.delete(999), throwsStateError);
      expect(
        await repo.list(
          fromUtc: now.subtract(const Duration(days: 1)),
          toUtc: now.add(const Duration(days: 1)),
        ),
        isEmpty,
      );
    },
  );
}
