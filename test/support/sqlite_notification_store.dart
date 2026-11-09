import 'package:sqflite_common/sqlite_api.dart';
import 'package:suc_khoe_ca_nhan/data/notification_store.dart';

class SqliteNotificationStore implements NotificationStore {
  SqliteNotificationStore(this.db);
  final Database db;
  @override
  Future<List<Map<String, Object?>>> cancellations() => db.query(
    'reminder_occurrences',
    where: "notification_state = 'pending_cancel'",
    orderBy: 'id',
  );
  @override
  Future<List<Map<String, Object?>>> future(DateTime now) => db.rawQuery(
    "SELECT o.*,r.title FROM reminder_occurrences o JOIN care_reminders r ON r.id=o.reminder_id WHERE o.status='pending' AND o.notification_state!='pending_cancel' AND o.scheduled_at_utc>? AND r.is_enabled=1 AND r.is_archived=0 ORDER BY o.scheduled_at_utc,o.id",
    [now.millisecondsSinceEpoch],
  );
  @override
  Future<bool> isPending(int id) async => (await db.query(
    'reminder_occurrences',
    where:
        "id = ? AND status='pending' AND notification_state!='pending_cancel'",
    whereArgs: [id],
  )).isNotEmpty;
  @override
  Future<bool> markScheduled(int id) async =>
      await db.update(
        'reminder_occurrences',
        {'notification_state': 'scheduled', 'notification_error': null},
        where: "id=? AND status='pending' AND notification_state!='pending_cancel'",
        whereArgs: [id],
      ) !=
      0;
  @override
  Future<void> markCancelled(int id) async {
    await db.update(
      'reminder_occurrences',
      {'notification_state': 'cancelled', 'notification_error': null},
      where: "id=? AND notification_state='pending_cancel'",
      whereArgs: [id],
    );
  }

  @override
  Future<void> cancelFailed(int id) async {
    await db.update(
      'reminder_occurrences',
      {'notification_error': 'cancel_failed'},
      where: 'id=?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> failure(int id, String code) async {
    await db.update(
      'reminder_occurrences',
      {'notification_state': 'failed', 'notification_error': code},
      where:
          "id=? AND status='pending' AND notification_state!='pending_cancel'",
      whereArgs: [id],
    );
  }

  @override
  Future<bool> hasWarnings(DateTime now) async =>
      (await db.rawQuery(
        "SELECT COUNT(*) AS count FROM reminder_occurrences WHERE notification_error IS NOT NULL AND (notification_state='pending_cancel' OR (status='pending' AND scheduled_at_utc>?))",
        [now.millisecondsSinceEpoch],
      )).single['count'] !=
      0;
}
