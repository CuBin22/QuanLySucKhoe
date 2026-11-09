import 'package:flutter_test/flutter_test.dart';
import 'package:suc_khoe_ca_nhan/data/api_client.dart';
import 'package:suc_khoe_ca_nhan/data/api_repositories.dart';
import 'package:suc_khoe_ca_nhan/notifications/notification_sync.dart';

import '../notifications/fake_notification_port.dart';

void main() {
  test('reconnect cancels unacknowledged OS alarm missing from canonical future list', () async {
    final port = FakeNotificationPort()..pending.add(31);
    final api = ApiClient(
      baseUrl: Uri.parse('https://health.example/api/'),
      apiKey: 'key',
      deviceId: 'device',
      send: (m, u, h, b) async =>
          const ApiReply(200, {'cancellations': [], 'future': []}),
    );
    await NotificationSync(ApiNotificationStore(api), port).reconcile();
    expect(port.pending, isEmpty);
    expect(port.events, ['cancel:31']);
  });
  test(
    'failed orphan cancellation blocks replacement until retry succeeds',
    () async {
      final now = DateTime.now().toUtc();
      final row = {
        'id': 32,
        'reminder_id': 5,
        'scheduled_at_utc': now
            .add(const Duration(hours: 1))
            .millisecondsSinceEpoch,
        'status': 'pending',
        'notification_state': 'pending_schedule',
        'title': 'Test',
      };
      final port = FakeNotificationPort()
        ..pending.add(31)
        ..failCancel.add(31);
      final api = ApiClient(
        baseUrl: Uri.parse('https://health.example/api/'),
        apiKey: 'key',
        deviceId: 'device',
        send: (m, u, h, b) async {
          if (u.path.endsWith('/occurrences/32')) return ApiReply(200, row);
          if (u.path.endsWith('/notifications/32')) {
            return const ApiReply(200, {'changed': true});
          }
          return ApiReply(200, {
            'cancellations': [],
            'future': [row],
          });
        },
      );
      final sync = NotificationSync(ApiNotificationStore(api), port);
      await sync.reconcile();
      expect(port.pending, {31});
      expect(port.events, isNot(contains('schedule:32')));
      port.failCancel.clear();
      await sync.reconcile();
      expect(port.pending, {32});
      expect(port.events.last, 'schedule:32');
    },
  );
}
