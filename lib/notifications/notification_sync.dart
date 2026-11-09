import '../data/notification_store.dart';

import 'notification_port.dart';
import '../features/care/reminder_occurrence.dart';

class NotificationSync {
  NotificationSync(
    this.store,
    this.port, {
    DateTime Function()? utcNow,
    this.beforeReconcile,
  }) : _utcNow = utcNow ?? (() => DateTime.now().toUtc());
  final NotificationStore store;
  final Future<void> Function()? beforeReconcile;
  bool _bindingFailed = false;
  bool _orphanFailed = false;
  final NotificationPort port;
  final DateTime Function() _utcNow;
  Future<void> _tail = Future.value();
  Future<void> reconcile() {
    final next = _tail.then((_) => _run());
    _tail = next.catchError((Object error) {});
    return next;
  }

  Future<void> _run() async {
    _orphanFailed = false;
    try {
      await beforeReconcile?.call();
      _bindingFailed = false;
    } catch (_) {
      _bindingFailed = true;
      rethrow;
    }
    final blocked = <int>{};
    final cancellations = await store.cancellations();
    for (final row in cancellations) {
      try {
        await port.cancel(row['id'] as int);
        await store.markCancelled(row['id'] as int);
      } catch (_) {
        blocked.add(row['reminder_id'] as int);
        await store.cancelFailed(row['id'] as int);
      }
    }
    final future = await store.future(_utcNow());
    NotificationPermission permission;
    Set<int> pending;
    try {
      permission = await port.status();
      pending = await port.pendingIds();
    } catch (_) {
      permission = NotificationPermission.unavailable;
      pending = {};
    }
    // An OS schedule can survive a lost API acknowledgement. The canonical
    // active IDs, not only recorded device rows, determine what must remain.
    final desired = future.map((row) => row['id'] as int).toSet();
    final knownCancellations = cancellations.map((row) => row['id'] as int).toSet();
    for (final id in pending.difference(desired).difference(knownCancellations)) {
      try { await port.cancel(id); }
      catch (_) { _orphanFailed = true; }
    }
    if (_orphanFailed) return;
    for (final row in future) {
      final id = row['id'] as int;
      if (blocked.contains(row['reminder_id'])) {
        await _failure(id, 'cancel_pending');
        continue;
      }
      if (permission != NotificationPermission.granted) {
        await _failure(
          id,
          permission == NotificationPermission.denied
              ? 'permission_denied'
              : 'notification_unavailable',
        );
        continue;
      }
      try {
        if (!pending.contains(id)) {
          if (!await store.isPending(id) ||
              !_utcNow().isBefore(
                DateTime.fromMillisecondsSinceEpoch(
                  row['scheduled_at_utc'] as int,
                  isUtc: true,
                ),
              )) {
            continue;
          }
          await port.schedule(
            ReminderOccurrence.fromMap(row),
            title: row['title'] as String,
          );
        }
        final changed = await store.markScheduled(id);
        if (!changed) await port.cancel(id);
      } catch (_) {
        await _failure(id, 'schedule_failed');
      }
    }
  }

  Future<void> _failure(int id, String code) async {
    await store.failure(id, code);
  }

  Future<bool> hasWarnings() async =>
      _bindingFailed || _orphanFailed || await store.hasWarnings(_utcNow());
}
