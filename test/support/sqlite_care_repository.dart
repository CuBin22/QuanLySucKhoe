import 'package:suc_khoe_ca_nhan/features/care/care_repository.dart';
import 'package:sqflite_common/sqlite_api.dart';

import 'package:suc_khoe_ca_nhan/features/care/care_reminder.dart';
import 'package:suc_khoe_ca_nhan/features/care/reminder_occurrence.dart';
import 'package:suc_khoe_ca_nhan/features/care/care_rules.dart';

class SqliteCareRepository implements CareRepository {
  SqliteCareRepository(this.db);
  final Database db;
  @override
  Future<int> save(CareReminder reminder, {required DateTime nowUtc}) async {
    final times = generateOccurrenceTimes(
      reminder,
      nowUtc: nowUtc,
      creating: reminder.id == null,
    );
    return db.transaction((txn) async {
      if (reminder.id != null) {
        await _find(txn, reminder.id!);
        await _cancelPending(txn, reminder.id!, futureAfter: nowUtc);
      }
      final values = <String, Object?>{
        'profile_id': 1,
        'type': reminder.type.name,
        'title': reminder.title.trim(),
        'note': reminder.note.trim(),
        'repeat_rule': reminder.repeatRule.name,
        'start_date': reminder.startDate,
        'end_date': reminder.endDate,
        'local_time': reminder.localTime,
        'timezone_id': 'Asia/Ho_Chi_Minh',
        'is_enabled': reminder.isEnabled ? 1 : 0,
        'is_archived': 0,
        'updated_at_utc': nowUtc.millisecondsSinceEpoch,
      };
      final int id;
      if (reminder.id == null) {
        values['created_at_utc'] = nowUtc.millisecondsSinceEpoch;
        id = await txn.insert('care_reminders', values);
      } else {
        id = reminder.id!;
        await txn.update(
          'care_reminders',
          values,
          where: 'id = ?',
          whereArgs: [id],
        );
      }
      if (reminder.isEnabled) await _insertTimes(txn, id, times, nowUtc);
      return id;
    });
  }

  Future<CareReminder> _find(DatabaseExecutor txn, int id) async {
    final rows = await txn.query(
      'care_reminders',
      where: 'id = ? AND is_archived = 0',
      whereArgs: [id],
    );
    if (rows.isEmpty) throw StateError('Lịch không còn tồn tại.');
    return CareReminder.fromMap(rows.single);
  }

  Future<void> _cancelPending(
    DatabaseExecutor txn,
    int id, {
    DateTime? futureAfter,
  }) async {
    await txn.update(
      'reminder_occurrences',
      {
        'status': 'cancelled',
        'notification_state': 'pending_cancel',
        'notification_error': null,
      },
      where:
          "reminder_id = ? AND status = 'pending'${futureAfter == null ? '' : ' AND scheduled_at_utc > ?'}",
      whereArgs: [
        id,
        if (futureAfter != null) futureAfter.millisecondsSinceEpoch,
      ],
    );
  }

  Future<void> _insertTimes(
    DatabaseExecutor txn,
    int id,
    List<DateTime> times,
    DateTime nowUtc,
  ) async {
    for (final time in times) {
      await txn.insert('reminder_occurrences', {
        'reminder_id': id,
        'scheduled_at_utc': time.millisecondsSinceEpoch,
        'status': 'pending',
        'notification_state': 'pending_schedule',
        'created_at_utc': nowUtc.millisecondsSinceEpoch,
      });
    }
  }

  @override
  Future<void> setEnabled(
    int id,
    bool enabled, {
    required DateTime nowUtc,
  }) async {
    await db.transaction((txn) async {
      final plan = await _find(txn, id);
      if (plan.isEnabled == enabled) return;
      if (enabled) {
        final times = generateOccurrenceTimes(
          plan,
          nowUtc: nowUtc,
          creating: false,
        );
        await _insertTimes(txn, id, times, nowUtc);
      } else {
        await _cancelPending(txn, id);
      }
      await txn.update(
        'care_reminders',
        {
          'is_enabled': enabled ? 1 : 0,
          'updated_at_utc': nowUtc.millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  @override
  Future<void> archive(int id, {required DateTime nowUtc}) async {
    await db.transaction((txn) async {
      await _find(txn, id);
      await _cancelPending(txn, id);
      await txn.update(
        'care_reminders',
        {
          'is_enabled': 0,
          'is_archived': 1,
          'updated_at_utc': nowUtc.millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  @override
  Future<void> resolve(
    int occurrenceId,
    OccurrenceStatus result, {
    required DateTime nowUtc,
  }) async {
    if (result != OccurrenceStatus.completed &&
        result != OccurrenceStatus.skipped) {
      throw StateError('Chọn hoàn thành hoặc bỏ qua.');
    }
    await db.transaction((txn) async {
      final rows = await txn.query(
        'reminder_occurrences',
        where: 'id = ?',
        whereArgs: [occurrenceId],
      );
      if (rows.isEmpty) throw StateError('Lần nhắc không còn tồn tại.');
      final item = ReminderOccurrence.fromMap(rows.single);
      if (item.status == result) return;
      if (item.status != OccurrenceStatus.pending) {
        throw StateError('Lần nhắc đã có kết quả hoặc đã hủy.');
      }
      if (item.scheduledAtUtc.isAfter(nowUtc)) {
        throw StateError('Chưa đến thời điểm xác nhận.');
      }
      await txn.update(
        'reminder_occurrences',
        {
          'status': result.name,
          'resolved_at_utc': nowUtc.millisecondsSinceEpoch,
          'notification_state': 'pending_cancel',
          'notification_error': null,
        },
        where: 'id = ?',
        whereArgs: [occurrenceId],
      );
    });
  }

  @override
  Future<List<CareReminder>> list({
    ReminderType? type,
    bool? enabled,
    bool includeArchived = false,
  }) async {
    final conditions = [
      if (!includeArchived) 'is_archived = 0',
      if (type != null) 'type = ?',
      if (enabled != null) 'is_enabled = ?',
    ];
    final rows = await db.query(
      'care_reminders',
      where: conditions.isEmpty ? null : conditions.join(' AND '),
      whereArgs: [
        if (type != null) type.name,
        if (enabled != null) enabled ? 1 : 0,
      ],
      orderBy: 'is_enabled DESC, start_date DESC, id DESC',
    );
    return rows.map(CareReminder.fromMap).toList();
  }

  @override
  Future<CareReminder?> find(int id) async {
    final rows = await db.query(
      'care_reminders',
      where: 'id = ?',
      whereArgs: [id],
    );
    return rows.isEmpty ? null : CareReminder.fromMap(rows.single);
  }

  @override
  Future<List<ReminderOccurrence>> occurrencesFor(int reminderId) async =>
      (await db.query(
        'reminder_occurrences',
        where: 'reminder_id = ?',
        whereArgs: [reminderId],
        orderBy: 'scheduled_at_utc, id',
      )).map(ReminderOccurrence.fromMap).toList();
  @override
  Future<List<ReminderOccurrence>> occurrencesBetween({
    required DateTime fromUtc,
    required DateTime toUtc,
  }) async => (await db.query(
    'reminder_occurrences',
    where: "scheduled_at_utc >= ? AND scheduled_at_utc < ? AND status != 'cancelled'",
    whereArgs: [fromUtc.millisecondsSinceEpoch, toUtc.millisecondsSinceEpoch],
    orderBy: 'scheduled_at_utc, id',
  )).map(ReminderOccurrence.fromMap).toList();
  @override
  Future<int?> reminderIdForOccurrence(int id) async {
    final rows = await db.query(
      'reminder_occurrences',
      columns: ['reminder_id'],
      where: 'id = ?',
      whereArgs: [id],
    );
    return rows.isEmpty ? null : rows.single['reminder_id'] as int;
  }
}
