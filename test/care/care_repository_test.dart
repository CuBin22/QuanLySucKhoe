import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/app_database.dart';

import 'package:suc_khoe_ca_nhan/features/profile/profile.dart';

import '../support/sqlite_profile_repository.dart';

import 'package:suc_khoe_ca_nhan/features/care/care_reminder.dart';
import 'package:suc_khoe_ca_nhan/features/care/reminder_occurrence.dart';

import '../support/sqlite_care_repository.dart';

void main() {
  sqfliteFfiInit();
  late Database db;
  late SqliteCareRepository repo;
  final start = DateTime.utc(2026, 10, 31);
  CareReminder plan({int? id, String time = '08:00'}) => CareReminder(
    id: id,
    type: ReminderType.medication,
    title: 'Lịch thử',
    repeatRule: RepeatRule.daily,
    startDate: '2026-10-31',
    endDate: '2026-11-02',
    localTime: time,
  );
  setUp(() async {
    db = await openAppDatabase(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    await SqliteProfileRepository(db)
        .save(const Profile(fullName: 'Demo', heightCm: 170));
    repo = SqliteCareRepository(db);
  });
  tearDown(() => db.close());
  test('editing preserves overdue and completed history and replaces only future occurrences', () async {
    final id = await repo.save(plan(), nowUtc: start);
    var items = await repo.occurrencesFor(id);
    expect(items.length, 3);
    final now = DateTime.utc(2026, 11, 1, 2);
    await repo.resolve(items.first.id, OccurrenceStatus.completed, nowUtc: now);
    final resolved = (await repo.occurrencesFor(id)).first.resolvedAtUtc;
    await repo.resolve(
      items.first.id,
      OccurrenceStatus.completed,
      nowUtc: now.add(const Duration(minutes: 2)),
    );
    expect((await repo.occurrencesFor(id)).first.resolvedAtUtc, resolved);
    await repo.save(
      plan(id: id, time: '09:00'),
      nowUtc: now,
    );
    items = await repo.occurrencesFor(id);
    expect(
      items.where((x) => x.status == OccurrenceStatus.completed).length,
      1,
    );
    expect(
      items
          .where(
            (x) =>
                x.status == OccurrenceStatus.pending &&
                x.scheduledAtUtc.isBefore(now),
          )
          .length,
      1,
    );
    expect(
      items.where((x) => x.status == OccurrenceStatus.cancelled).length,
      1,
    );
    expect(
      items
          .where(
            (x) =>
                x.status == OccurrenceStatus.pending &&
                x.scheduledAtUtc.isAfter(now),
          )
          .single
          .scheduledAtUtc,
      DateTime.utc(2026, 11, 2, 2),
    );
  });
  test('disabling and reenabling uses new IDs and archiving preserves confirmed history', () async {
    final id = await repo.save(plan(), nowUtc: start);
    final initial = await repo.occurrencesFor(id);
    final now = DateTime.utc(2026, 10, 31, 2);
    await repo.resolve(initial.first.id, OccurrenceStatus.skipped, nowUtc: now);
    await repo.setEnabled(id, false, nowUtc: now);
    await repo.setEnabled(id, true, nowUtc: now);
    final items = await repo.occurrencesFor(id);
    final future = items
        .where((x) => x.status == OccurrenceStatus.pending)
        .toList();
    expect(future.length, 2);
    expect(future.every((x) => x.id > initial.last.id), isTrue);
    await repo.archive(id, nowUtc: now);
    expect(await repo.list(), isEmpty);
    expect(
      (await repo.occurrencesFor(id))
          .where((x) => x.status == OccurrenceStatus.skipped)
          .length,
      1,
    );
  });
  test(
    'future confirmation and changing an already confirmed result are rejected',
    () async {
      final id = await repo.save(plan(), nowUtc: start);
      final first = (await repo.occurrencesFor(id)).first;
      await expectLater(
        repo.resolve(first.id, OccurrenceStatus.completed, nowUtc: start),
        throwsStateError,
      );
      final now = start.add(const Duration(hours: 2));
      await repo.resolve(first.id, OccurrenceStatus.completed, nowUtc: now);
      await expectLater(
        repo.resolve(first.id, OccurrenceStatus.skipped, nowUtc: now),
        throwsStateError,
      );
    },
  );
  test('failed occurrence insertion rolls back the parent reminder', () async {
    await db.rawInsert(
      "INSERT INTO sqlite_sequence(name,seq) VALUES('reminder_occurrences',2147483647)",
    );
    await expectLater(
      repo.save(plan(), nowUtc: start),
      throwsA(isA<DatabaseException>()),
    );
    expect(await repo.list(), isEmpty);
  });
}
