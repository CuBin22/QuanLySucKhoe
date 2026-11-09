enum ReminderType { medication, appointment }

enum RepeatRule { none, daily }

class CareReminder {
  const CareReminder({
    this.id,
    required this.type,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.localTime,
    this.repeatRule = RepeatRule.none,
    this.note = '',
    this.isEnabled = true,
    this.isArchived = false,
  });
  final int? id;
  final ReminderType type;
  final String title, note, startDate, endDate, localTime;
  final RepeatRule repeatRule;
  final bool isEnabled, isArchived;
  factory CareReminder.fromMap(Map<String, Object?> row) => CareReminder(
    id: row['id'] as int,
    type: ReminderType.values.byName(row['type'] as String),
    title: row['title'] as String,
    note: row['note'] as String,
    repeatRule: RepeatRule.values.byName(row['repeat_rule'] as String),
    startDate: row['start_date'] as String,
    endDate: row['end_date'] as String,
    localTime: row['local_time'] as String,
    isEnabled: row['is_enabled'] == 1,
    isArchived: row['is_archived'] == 1,
  );
}
