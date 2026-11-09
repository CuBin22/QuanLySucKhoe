import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:suc_khoe_ca_nhan/data/api_client.dart';

void main() {
  test(
    'API uses headers and preserves Vietnamese JSON without SQL credentials',
    () async {
      final client = ApiClient(
        baseUrl: Uri.parse('https://health.example/api/'),
        apiKey: 'test-private-key',
        deviceId: 'device-a',
        send: (method, uri, headers, body) async {
          expect(method, 'PUT');
          expect(uri.path, '/api/profile');
          expect(headers['X-Api-Key'], 'test-private-key');
          expect(headers['X-Device-Id'], 'device-a');
          expect((body as Map)['full_name'], 'Trương Kiến Phi');
          return const ApiReply(200, {'ok': true});
        },
      );
      expect(
        await client.write('PUT', 'profile', {'full_name': 'Trương Kiến Phi'}),
        {'ok': true},
      );
    },
  );
  test('ambiguous create retry reuses mutation id, next successful create uses new id', () async {
    final ids = <String>[];
    var calls = 0;
    final client = ApiClient(
      baseUrl: Uri.parse('https://health.example/api/'),
      apiKey: 'key',
      deviceId: 'a',
      send: (m, u, h, b) async {
        ids.add(h['Idempotency-Key']!);
        calls++;
        if (calls == 1) throw TimeoutException('lost response');
        return const ApiReply(200, {'id': 1});
      },
    );
    await expectLater(
      client.write('POST', 'health', {'weight_kg': 65.234}),
      throwsA(isA<ApiException>()),
    );
    await client.write('POST', 'health', {'weight_kg': 65.234});
    await client.write('POST', 'health', {'weight_kg': 65.234});
    expect(ids[0], ids[1]);
    expect(ids[2], isNot(ids[1]));
  });
  test(
    'unauthorized and invalid JSON fail instead of producing empty data',
    () async {
      final client = ApiClient(
        baseUrl: Uri.parse('https://health.example/api/'),
        apiKey: 'bad',
        deviceId: 'a',
        send: (m, u, h, b) async =>
            const ApiReply(401, {'message': 'secret SQL connection text'}),
      );
      await expectLater(
        client.get('profile'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'safe message',
            isNot(contains('secret SQL')),
          ),
        ),
      );
    },
  );
}
