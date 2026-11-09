import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:suc_khoe_ca_nhan/data/api_client.dart';
import 'package:suc_khoe_ca_nhan/data/remote_services.dart';

void main() {
  late Directory workspace;

  setUp(() async {
    workspace = await Directory('.dart_tool').createTemp('health-key-test-');
    await Directory('${workspace.path}${Platform.pathSeparator}.local').create();
    await File(
      '${workspace.path}${Platform.pathSeparator}.local${Platform.pathSeparator}api-key.txt',
    ).writeAsString('key-from-api-script\n');
  });
  tearDown(() async => workspace.delete(recursive: true));

  test('Windows launched directly reads the local API key', () async {
    expect(
      await resolveApiKey(
        environment: {},
        definedKey: '',
        workingDirectory: workspace,
        isWindows: true,
      ),
      'key-from-api-script',
    );
  });

  test('explicit environment key takes priority over local file', () async {
    expect(
      await resolveApiKey(
        environment: {'HEALTH_API_KEY': 'explicit-key'},
        definedKey: '',
        workingDirectory: workspace,
        isWindows: true,
      ),
      'explicit-key',
    );
  });

  test('Android never reads desktop local key', () async {
    await expectLater(
      resolveApiKey(
        environment: {},
        definedKey: '',
        workingDirectory: workspace,
        isWindows: false,
      ),
      throwsA(isA<ApiException>()),
    );
  });
}
