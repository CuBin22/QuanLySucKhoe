import 'care_reminder.dart';
import 'reminder_occurrence.dart';

abstract class CareRepository {
  Future<int> save(CareReminder reminder, {required DateTime nowUtc});
  Future<void> setEnabled(int id, bool enabled, {required DateTime nowUtc});
  Future<void> archive(int id, {required DateTime nowUtc});
  Future<void> resolve(
    int occurrenceId,
    OccurrenceStatus result, {
    required DateTime nowUtc,
  });
  Future<List<CareReminder>> list({
    ReminderType? type,
    bool? enabled,
    bool includeArchived = false,
  });
  Future<CareReminder?> find(int id);
  Future<List<ReminderOccurrence>> occurrencesFor(int reminderId);
  Future<List<ReminderOccurrence>> occurrencesBetween({
    required DateTime fromUtc,
    required DateTime toUtc,
  });
  Future<int?> reminderIdForOccurrence(int occurrenceId);
}
