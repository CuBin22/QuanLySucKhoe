import 'dart:io';

import '../app_services.dart';
import '../notifications/notification_port.dart';
import 'api_client.dart';
import 'device_identity.dart';

Future<String> resolveApiKey({
  Map<String, String>? environment,
  String definedKey = const String.fromEnvironment('API_KEY'),
  Directory? workingDirectory,
  bool? isWindows,
}) async {
  final supplied = (environment ?? Platform.environment)['HEALTH_API_KEY'];
  if (supplied != null && supplied.trim().isNotEmpty) {
    return supplied.trim();
  }
  if (definedKey.trim().isNotEmpty) {
    return definedKey.trim();
  }
  if (isWindows ?? Platform.isWindows) {
    final localKey = File(
      '${(workingDirectory ?? Directory.current).path}${Platform.pathSeparator}.local${Platform.pathSeparator}api-key.txt',
    );
    if (await localKey.exists()) {
      final saved = (await localKey.readAsString()).trim();
      if (saved.isNotEmpty) {
        return saved;
      }
    }
  }
  throw ApiException(
    'Chưa cấu hình API_KEY. Hãy chạy API trước rồi mở lại ứng dụng.',
  );
}

Future<AppServices> createRemoteServices(NotificationPort port) async {
  const definedUrl = String.fromEnvironment('API_BASE_URL');
  final url =
      Platform.environment['HEALTH_API_URL'] ??
      (definedUrl.isNotEmpty
          ? definedUrl
          : Platform.isAndroid
          ? 'http://10.0.2.2:5080/api/'
          : 'http://127.0.0.1:5080/api/');
  final key = await resolveApiKey();
  final identity = await DeviceIdentity.load();
  final api = ApiClient(
    baseUrl: Uri.parse(url),
    apiKey: key,
    deviceId: identity.id,
  );
  final meta = await api.get('meta');
  if (meta is! Map ||
      meta['backend_id'] is! String ||
      meta['schema_version'] != 1) {
    throw ApiException('Máy chủ chưa khởi tạo đúng cơ sở dữ liệu SQL Server.');
  }
  return AppServices.remote(
    api,
    port,
    beforeReconcile: () => identity.bind(port, meta['backend_id'] as String),
  );
}
