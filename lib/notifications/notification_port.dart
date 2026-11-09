import '../features/care/reminder_occurrence.dart';

enum NotificationPermission { granted, denied, unavailable }

abstract class NotificationPort {
  Future<NotificationPermission> status();
  Future<NotificationPermission> requestPermission();
  Future<void> schedule(ReminderOccurrence occurrence, {required String title});
  Future<void> cancel(int id);
  Future<Set<int>> pendingIds();
  Future<int?> getLaunchOccurrenceId();
  Stream<int> get selections;
}
