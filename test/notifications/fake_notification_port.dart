import 'package:suc_khoe_ca_nhan/notifications/notification_port.dart';
import 'package:suc_khoe_ca_nhan/features/care/reminder_occurrence.dart';

class FakeNotificationPort implements NotificationPort {
  NotificationPermission permission = NotificationPermission.granted;
  final events = <String>[];
  final pending = <int>{};
  final failCancel = <int>{};
  bool failSchedule = false;
  @override
  Future<NotificationPermission> status() async => permission;
  @override
  Future<NotificationPermission> requestPermission() async => permission;
  @override
  Future<void> schedule(
    ReminderOccurrence item, {
    required String title,
  }) async {
    events.add('schedule:${item.id}');
    if (failSchedule) throw StateError('schedule_failed');
    pending.add(item.id);
  }

  @override
  Future<void> cancel(int id) async {
    events.add('cancel:$id');
    if (failCancel.contains(id)) throw StateError('cancel_failed');
    pending.remove(id);
  }

  @override
  Future<Set<int>> pendingIds() async => {...pending};
  @override
  Future<int?> getLaunchOccurrenceId() async => null;
  @override
  Stream<int> get selections => const Stream.empty();
}
