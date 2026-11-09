import 'package:flutter_test/flutter_test.dart';
import 'package:suc_khoe_ca_nhan/data/api_client.dart';
import 'package:suc_khoe_ca_nhan/data/api_repositories.dart';
import 'package:suc_khoe_ca_nhan/features/health/health_record.dart';
import 'package:suc_khoe_ca_nhan/features/care/care_reminder.dart';

void main() {
  ApiClient client(ApiTransport send) => ApiClient(
    baseUrl: Uri.parse('https://health.example/api/'),
    apiKey: 'key',
    deviceId: 'device-one',
    send: send,
  );
  test(
    'profile null remains first run and Unicode/decimal row maps precisely',
    () async {
      var empty = true;
      final repo = ApiProfileRepository(
        client(
          (m, u, h, b) async => ApiReply(
            200,
            empty
                ? null
                : {
                    'full_name': 'Kiến Phi',
                    'height_cm': 170.123456789,
                    'birth_date': null,
                    'target_weight_kg': 65.234,
                  },
          ),
        ),
      );
      expect(await repo.load(), isNull);
      empty = false;
      final p = await repo.load();
      expect(p!.fullName, 'Kiến Phi');
      expect(p.heightCm, 170.123456789);
    },
  );
  test(
    'health latest maps independent groups and preserves precision',
    () async {
      final repo = ApiHealthRepository(
        client((m, u, h, b) async {
          expect(u.path, '/api/health/latest');
          return const ApiReply(200, {
            'weight': {
              'id': 1,
              'measured_at_utc': 1,
              'weight_kg': 65.23456789,
              'height_cm_snapshot': 170.123,
              'note': '',
            },
            'bloodPressure': {
              'id': 2,
              'measured_at_utc': 2,
              'systolic': 120,
              'diastolic': 80,
              'note': '',
            },
          });
        }),
      );
      final latest = await repo.latestByMetric();
      expect(latest[HealthMetric.weight]!.weightKg, 65.23456789);
      expect(latest[HealthMetric.bloodPressure]!.id, 2);
      expect(latest[HealthMetric.heartRate], isNull);
    },
  );
  test('care save sends schedule but never trusts client now clock', () async {
    final repo = ApiCareRepository(
      client((m, u, h, b) async {
        expect(m, 'POST');
        expect(u.path, '/api/care');
        expect((b as Map)['start_date'], '2026-11-02');
        expect(b.containsKey('now_utc'), isFalse);
        return const ApiReply(200, {'id': 8});
      }),
    );
    expect(
      await repo.save(
        const CareReminder(
          type: ReminderType.medication,
          title: 'Lịch thử',
          startDate: '2026-11-02',
          endDate: '2026-11-02',
          localTime: '08:00',
        ),
        nowUtc: DateTime.utc(1900),
      ),
      8,
    );
  });
  test('notification state update belongs to this device and respects rejected race', () async {
    final store = ApiNotificationStore(
      client((m, u, h, b) async {
        expect(h['X-Device-Id'], 'device-one');
        expect(u.path, '/api/notifications/7');
        expect((b as Map)['action'], 'scheduled');
        return const ApiReply(200, {'changed': false});
      }),
    );
    expect(await store.markScheduled(7), isFalse);
  });
  test(
    'malformed successful payload fails instead of erasing profile',
    () async {
      final repo = ApiProfileRepository(
        client((m, u, h, b) async => const ApiReply(200, [])),
      );
      await expectLater(repo.load(), throwsA(isA<ApiException>()));
    },
  );
}
