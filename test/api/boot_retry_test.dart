import 'package:flutter_test/flutter_test.dart';
import 'package:suc_khoe_ca_nhan/app.dart';
import 'package:suc_khoe_ca_nhan/app_services.dart';
import 'package:suc_khoe_ca_nhan/data/api_client.dart';

import '../notifications/fake_notification_port.dart';
import '../ui/test_host.dart';

void main() {
  testWidgets('retry after API recovery opens the profile without an async setState error', (tester) async {
    var profileRequests = 0;
    final api = ApiClient(
      baseUrl: Uri.parse('https://health.example/api/'),
      apiKey: 'test-key',
      deviceId: 'test-device',
      send: (method, uri, headers, body) async {
        if (uri.path.endsWith('/profile')) {
          profileRequests++;
          return profileRequests == 1
              ? const ApiReply(503, {'message': 'temporarily offline'})
              : const ApiReply(200, null);
        }
        if (uri.path.endsWith('/notifications')) {
          return const ApiReply(200, {'cancellations': [], 'future': []});
        }
        if (uri.path.endsWith('/notifications/warnings')) {
          return const ApiReply(200, {'has_warnings': false});
        }
        return const ApiReply(200, []);
      },
    );
    await tester.pumpWidget(
      HealthApp(services: AppServices.remote(api, FakeNotificationPort())),
    );
    await pumpDatabase(tester);
    expect(find.text('Thử lại'), findsOneWidget);

    await tester.tap(find.text('Thử lại'));
    await pumpDatabase(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Thử lại'), findsNothing);
    expect(profileRequests, greaterThanOrEqualTo(2));
  });
}
