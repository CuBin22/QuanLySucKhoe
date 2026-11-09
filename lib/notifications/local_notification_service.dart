import 'dart:async';

import 'package:flutter/services.dart';

import '../features/care/reminder_occurrence.dart';
import 'notification_port.dart';

class LocalNotificationService implements NotificationPort {
  LocalNotificationService() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'selected' && call.arguments is num) {
        _selections.add((call.arguments as num).toInt());
      }
    });
  }
  static const _channel = MethodChannel(
    'vn.kienphi.personal_health/notifications',
  );
  final _selections = StreamController<int>.broadcast();
  @override
  Stream<int> get selections => _selections.stream;
  Future<NotificationPermission> _permission(String method) async {
    try {
      final value = await _channel.invokeMethod<String>(method);
      return NotificationPermission.values.firstWhere(
        (p) => p.name == value,
        orElse: () => NotificationPermission.unavailable,
      );
    } catch (_) {
      return NotificationPermission.unavailable;
    }
  }

  @override
  Future<NotificationPermission> status() => _permission('status');
  @override
  Future<NotificationPermission> requestPermission() =>
      _permission('requestPermission');
  @override
  Future<void> schedule(
    ReminderOccurrence occurrence, {
    required String title,
  }) async {
    await _channel.invokeMethod<void>('schedule', {
      'id': occurrence.id,
      'at': occurrence.scheduledAtUtc.millisecondsSinceEpoch,
    });
  }

  @override
  Future<void> cancel(int id) =>
      _channel.invokeMethod<void>('cancel', {'id': id});
  @override
  Future<Set<int>> pendingIds() async =>
      (await _channel.invokeListMethod<num>('pendingIds') ?? [])
          .map((x) => x.toInt())
          .toSet();
  @override
  Future<int?> getLaunchOccurrenceId() async {
    try {
      return (await _channel.invokeMethod<num>('getLaunchOccurrenceId'))
          ?.toInt();
    } catch (_) {
      return null;
    }
  }

  Future<void> dispose() async {
    _channel.setMethodCallHandler(null);
    await _selections.close();
  }
}
