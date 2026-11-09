import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:suc_khoe_ca_nhan/app.dart';
import 'package:suc_khoe_ca_nhan/app_services.dart';
import 'package:suc_khoe_ca_nhan/data/api_client.dart';

import '../notifications/fake_notification_port.dart';
import '../ui/test_host.dart';

void main() {
  testWidgets(
    'remote save failure keeps form and retry confirms same mutation without local fallback',
    (tester) async {
      var attempts = 0;
      Map<String, Object?>? saved;
      final ids = <String>[];
      final api = ApiClient(
        baseUrl: Uri.parse('https://health.example/api/'),
        apiKey: 'key',
        deviceId: 'device',
        send: (method, uri, headers, body) async {
          final resource = uri.path.substring('/api/'.length);
          if (resource == 'profile') {
            return const ApiReply(200, {'full_name': 'Demo', 'height_cm': 170});
          }
          if (resource == 'health' && method == 'POST') {
            attempts++;
            ids.add(headers['Idempotency-Key']!);
            if (attempts == 1) {
              return const ApiReply(503, {'message': 'database unavailable'});
            }
            saved = {
              'id': 1,
              ...Map<String, Object?>.from(body as Map),
              'height_cm_snapshot': 170,
            };
            return const ApiReply(200, {'id': 1});
          }
          if (resource == 'health/latest') {
            return ApiReply(200, saved == null ? {} : {'weight': saved});
          }
          if (resource == 'health') {
            return ApiReply(200, saved == null ? [] : [saved]);
          }
          if (resource == 'notifications') {
            return const ApiReply(200, {'cancellations': [], 'future': []});
          }
          if (resource == 'notifications/warnings') {
            return const ApiReply(200, {'has_warnings': false});
          }
          return const ApiReply(200, []);
        },
      );
      await tester.pumpWidget(
        HealthApp(services: AppServices.remote(api, FakeNotificationPort())),
      );
      await pumpDatabase(tester);
      await tester.tap(find.text('Chỉ số').last);
      await pumpDatabase(tester);
      await tester.tap(find.byKey(const ValueKey('add-health')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('health-weight')),
        '65,23456789',
      );
      await tester.ensureVisible(find.byKey(const ValueKey('save-editor')));
      await tester.tap(find.byKey(const ValueKey('save-editor')));
      await pumpDatabase(tester);
      expect(find.text('65,23456789'), findsOneWidget);
      expect(find.textContaining('Không lưu được dữ liệu'), findsOneWidget);
      expect(saved, isNull);
      await tester.tap(find.byKey(const ValueKey('save-editor')));
      await pumpDatabase(tester);
      expect(attempts, 2);
      expect(ids[0], ids[1]);
      expect(saved!['weight_kg'], 65.23456789);
    },
  );
}
