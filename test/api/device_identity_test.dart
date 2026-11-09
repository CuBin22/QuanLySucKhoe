import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:suc_khoe_ca_nhan/data/device_identity.dart';

import '../notifications/fake_notification_port.dart';

void main() {
  test('device identity survives restart and changing backend clears old pending alarms', () async {
    final dir = await Directory.systemTemp.createTemp('health-device-');
    addTearDown(() => dir.delete(recursive: true));
    final first = await DeviceIdentity.load(directory: dir);
    final port = FakeNotificationPort()..pending.addAll([1, 9]);
    await first.bind(port, 'server-a');
    expect(port.pending, isEmpty);
    final second = await DeviceIdentity.load(directory: dir);
    expect(second.id, first.id);
    port.pending.add(7);
    await second.bind(port, 'server-a');
    expect(port.pending, {7});
    await second.bind(port, 'server-b');
    expect(port.pending, isEmpty);
  });
  test(
    'failed old alarm cancellation never records new backend as bound',
    () async {
      final dir = await Directory.systemTemp.createTemp('health-device-');
      addTearDown(() => dir.delete(recursive: true));
      final identity = await DeviceIdentity.load(directory: dir);
      final port = FakeNotificationPort()
        ..pending.add(4)
        ..failCancel.add(4);
      await expectLater(identity.bind(port, 'new-server'), throwsStateError);
      port.failCancel.clear();
      await (await DeviceIdentity.load(directory: dir))
          .bind(port, 'new-server');
      expect(port.pending, isEmpty);
    },
  );
}
