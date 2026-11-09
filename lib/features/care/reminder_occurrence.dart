enum OccurrenceStatus { pending, completed, skipped, cancelled }

class ReminderOccurrence {
  const ReminderOccurrence({
    required this.id,
    required this.reminderId,
    required this.scheduledAtUtc,
    required this.status,
    this.resolvedAtUtc,
    required this.notificationState,
    this.notificationError,
  });
  final int id, reminderId;
  final DateTime scheduledAtUtc;
  final OccurrenceStatus status;
  final DateTime? resolvedAtUtc;
  final String notificationState;
  final String? notificationError;
  factory ReminderOccurrence.fromMap(Map<String, Object?> row) =>
      ReminderOccurrence(
        id: row['id'] as int,
        reminderId: row['reminder_id'] as int,
        scheduledAtUtc: DateTime.fromMillisecondsSinceEpoch(
          row['scheduled_at_utc'] as int,
          isUtc: true,
        ),
        status: OccurrenceStatus.values.byName(row['status'] as String),
        resolvedAtUtc: row['resolved_at_utc'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                row['resolved_at_utc'] as int,
                isUtc: true,
              ),
        notificationState: row['notification_state'] as String,
        notificationError: row['notification_error'] as String?,
      );
}
