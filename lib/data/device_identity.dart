import 'dart:io';
import 'dart:convert';

import 'package:path_provider/path_provider.dart';

import '../notifications/notification_port.dart';
import 'api_client.dart';

class DeviceIdentity {
  DeviceIdentity._(this.id, this._file, this._backend);
  final String id;
  final File _file;
  String? _backend;
  static Future<DeviceIdentity> load({Directory? directory}) async {
    directory ??= await getApplicationSupportDirectory();
    await directory.create(recursive: true);
    final file = File(
      '${directory.path}${Platform.pathSeparator}api_device.json',
    );
    if (await file.exists()) {
      try {
        final data =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        if (data['device_id'] is String &&
            RegExp(r'^[a-f0-9]{32}$').hasMatch(data['device_id'] as String)) {
          return DeviceIdentity._(
            data['device_id'] as String,
            file,
            data['backend_id'] as String?,
          );
        }
      } on FormatException {
        /* Rebind OS schedules if local metadata was damaged. */
      } on TypeError {
        /* Rebind OS schedules if local metadata was damaged. */
      }
    }
    final identity = DeviceIdentity._(ApiClient.newId(), file, null);
    await identity._save();
    return identity;
  }

  Future<void> _save() => _file
      .writeAsString(
        jsonEncode({'device_id': id, 'backend_id': _backend}),
        flush: true,
      )
      .then((_) {});
  Future<void> bind(NotificationPort port, String backendId) async {
    if (_backend == backendId) return;
    for (final id in await port.pendingIds()) {
      await port.cancel(id);
    }
    _backend = backendId;
    try {
      await _save();
    } catch (_) {
      _backend = null;
      rethrow;
    }
  }
}
