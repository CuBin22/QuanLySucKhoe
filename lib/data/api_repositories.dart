import 'api_client.dart';
import 'notification_store.dart';
import '../features/profile/profile_repository.dart';
import '../features/health/health_repository.dart';
import '../features/care/care_repository.dart';
import '../features/profile/profile.dart';
import '../features/health/health_record.dart';
import '../features/care/care_reminder.dart';
import '../features/care/reminder_occurrence.dart';

Map<String, Object?> _row(Object? data) {
  if (data is! Map<String, dynamic>) {
    throw ApiException('Máy chủ trả dữ liệu không hợp lệ.');
  }
  return Map<String, Object?>.from(data);
}

List<Map<String, Object?>> _rows(Object? data) {
  if (data is! List) throw ApiException('Máy chủ trả danh sách không hợp lệ.');
  return data.map(_row).toList();
}

int _id(Object? data) {
  final id = _row(data)['id'];
  if (id is! int || id <= 0) {
    throw ApiException('Máy chủ chưa xác nhận lưu dữ liệu.');
  }
  return id;
}

class ApiProfileRepository implements ProfileRepository {
  ApiProfileRepository(this.api);
  final ApiClient api;
  @override
  Future<Profile?> load() async {
    final data = await api.get('profile');
    return data == null ? null : Profile.fromMap(_row(data));
  }

  @override
  Future<void> save(Profile p) async {
    _id(
      await api.write('PUT', 'profile', {
        'full_name': p.fullName,
        'height_cm': p.heightCm,
        'birth_date': p.birthDate,
        'target_weight_kg': p.targetWeightKg,
      }),
    );
  }
}

class ApiHealthRepository implements HealthRepository {
  ApiHealthRepository(this.api);
  final ApiClient api;
  @override
  Future<int> save(HealthRecord r) async => _id(
    await api.write(
      r.id == null ? 'POST' : 'PUT',
      r.id == null ? 'health' : 'health/${r.id}',
      {
        'measured_at_utc': r.measuredAtUtc.toUtc().millisecondsSinceEpoch,
        'weight_kg': r.weightKg,
        'systolic': r.systolic,
        'diastolic': r.diastolic,
        'heart_rate': r.heartRate,
        'note': r.note,
      },
    ),
  );
  @override
  Future<void> delete(int id) async {
    _id(await api.write('DELETE', 'health/$id', null));
  }

  @override
  Future<List<HealthRecord>> list({
    required DateTime fromUtc,
    required DateTime toUtc,
  }) async => _rows(
    await api.get(
      'health?from=${fromUtc.millisecondsSinceEpoch}&to=${toUtc.millisecondsSinceEpoch}',
    ),
  ).map(HealthRecord.fromMap).toList();
  @override
  Future<Map<HealthMetric, HealthRecord>> latestByMetric() async {
    final data = _row(await api.get('health/latest'));
    return {
      for (final m in HealthMetric.values)
        if (data[m.name] != null) m: HealthRecord.fromMap(_row(data[m.name])),
    };
  }
}

class ApiCareRepository implements CareRepository {
  ApiCareRepository(this.api);
  final ApiClient api;
  @override
  Future<int> save(CareReminder r, {required DateTime nowUtc}) async => _id(
    await api.write(
      r.id == null ? 'POST' : 'PUT',
      r.id == null ? 'care' : 'care/${r.id}',
      {
        'type': r.type.name,
        'title': r.title,
        'note': r.note,
        'repeat_rule': r.repeatRule.name,
        'start_date': r.startDate,
        'end_date': r.endDate,
        'local_time': r.localTime,
        'is_enabled': r.isEnabled,
      },
    ),
  );
  @override
  Future<void> setEnabled(
    int id,
    bool enabled, {
    required DateTime nowUtc,
  }) async {
    _id(await api.write('PUT', 'care/$id/enabled', {'is_enabled': enabled}));
  }

  @override
  Future<void> archive(int id, {required DateTime nowUtc}) async {
    _id(await api.write('POST', 'care/$id/archive', null));
  }

  @override
  Future<void> resolve(
    int id,
    OccurrenceStatus result, {
    required DateTime nowUtc,
  }) async {
    _id(
      await api.write('PUT', 'occurrences/$id/resolution', {
        'status': result.name,
      }),
    );
  }

  @override
  Future<List<CareReminder>> list({
    ReminderType? type,
    bool? enabled,
    bool includeArchived = false,
  }) async {
    final query = Uri(
      queryParameters: {
        'include_archived': '$includeArchived',
        if (type != null) 'type': type.name,
        if (enabled != null) 'enabled': '$enabled',
      },
    ).query;
    return _rows(await api.get('care?$query'))
        .map(CareReminder.fromMap)
        .toList();
  }

  @override
  Future<CareReminder?> find(int id) async {
    final data = await api.get('care/$id');
    return data == null ? null : CareReminder.fromMap(_row(data));
  }

  @override
  Future<List<ReminderOccurrence>> occurrencesFor(int id) async =>
      _rows(await api.get('occurrences?reminder_id=$id'))
          .map(ReminderOccurrence.fromMap)
          .toList();
  @override
  Future<List<ReminderOccurrence>> occurrencesBetween({
    required DateTime fromUtc,
    required DateTime toUtc,
  }) async => _rows(
    await api.get(
      'occurrences?from=${fromUtc.millisecondsSinceEpoch}&to=${toUtc.millisecondsSinceEpoch}',
    ),
  ).map(ReminderOccurrence.fromMap).toList();
  @override
  Future<int?> reminderIdForOccurrence(int id) async {
    final data = await api.get('occurrences/$id');
    return data == null ? null : _row(data)['reminder_id'] as int;
  }
}

class ApiNotificationStore implements NotificationStore {
  ApiNotificationStore(this.api);
  final ApiClient api;
  @override
  Future<List<Map<String, Object?>>> cancellations() async =>
      _rows(_row(await api.get('notifications'))['cancellations']);
  @override
  Future<List<Map<String, Object?>>> future(DateTime nowUtc) async =>
      _rows(_row(await api.get('notifications'))['future']);
  @override
  Future<bool> isPending(int id) async {
    final data = await api.get('occurrences/$id');
    if (data == null) return false;
    final row = _row(data);
    return row['status'] == 'pending' &&
        row['notification_state'] != 'pending_cancel';
  }

  Future<bool> _set(int id, String action) async =>
      _row(
        await api.write('PUT', 'notifications/$id', {'action': action}),
      )['changed'] ==
      true;
  @override
  Future<bool> markScheduled(int id) => _set(id, 'scheduled');
  @override
  Future<void> markCancelled(int id) async {
    await _set(id, 'cancelled');
  }

  @override
  Future<void> cancelFailed(int id) async {
    await _set(id, 'cancel_failed');
  }

  @override
  Future<void> failure(int id, String code) async {
    await _set(id, code);
  }

  @override
  Future<bool> hasWarnings(DateTime nowUtc) async =>
      _row(await api.get('notifications/warnings'))['has_warnings'] == true;
}
