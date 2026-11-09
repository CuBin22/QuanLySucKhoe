import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

typedef ApiTransport = Future<ApiReply> Function(
  String method,
  Uri uri,
  Map<String, String> headers,
  Object? body,
);

class ApiReply {
  const ApiReply(this.status, this.data);
  final int status;
  final Object? data;
}

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({
    required Uri baseUrl,
    required this.apiKey,
    required this.deviceId,
    ApiTransport? send,
  }) : baseUrl = _base(baseUrl),
       send = send ?? _http;
  final Uri baseUrl;
  final String apiKey, deviceId;
  final ApiTransport send;
  final _pending = <String, String>{};
  static Uri _base(Uri value) {
    if (!['http', 'https'].contains(value.scheme) ||
        value.host.isEmpty ||
        value.userInfo.isNotEmpty ||
        value.hasQuery ||
        value.hasFragment) {
      throw ApiException('Địa chỉ API không hợp lệ.');
    }
    return value.replace(
      path: value.path.endsWith('/') ? value.path : '${value.path}/',
    );
  }

  static String newId() => List.generate(
    16,
    (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  Future<Object?> get(String path) => _request('GET', path, null, null);
  Future<Object?> write(String method, String path, Object? body) async {
    final signature = '$method $path ${jsonEncode(body)}';
    final id = _pending.putIfAbsent(signature, newId);
    final result = await _request(method, path, body, id);
    _pending.remove(signature);
    return result;
  }

  Future<Object?> _request(
    String method,
    String path,
    Object? body,
    String? id,
  ) async {
    final target = baseUrl.resolve(path);
    if (target.origin != baseUrl.origin) {
      throw ApiException('Đường dẫn API không hợp lệ.');
    }
    try {
      final reply = await send(method, target, {
        'X-Api-Key': apiKey,
        'X-Device-Id': deviceId,
        'Idempotency-Key': ?id,
      }, body).timeout(const Duration(seconds: 20));
      if (reply.status >= 200 && reply.status < 300) return reply.data;
      if (reply.status == 401 || reply.status == 403) {
        throw ApiException(
          'Khóa truy cập API không hợp lệ. Kiểm tra cấu hình kết nối.',
        );
      }
      if ([400, 404, 409].contains(reply.status) &&
          reply.data is Map &&
          (reply.data as Map)['message'] is String) {
        throw ApiException(
          ((reply.data as Map)['message'] as String).substring(
            0,
            min(500, ((reply.data as Map)['message'] as String).length),
          ),
        );
      }
      throw ApiException('Chưa kết nối được máy chủ dữ liệu. Hãy thử lại.');
    } on TimeoutException {
      throw ApiException(
        'Máy chủ phản hồi chậm. Hãy thử lưu lại để xác nhận cùng thao tác.',
      );
    } on SocketException {
      throw ApiException('Không kết nối được API. Kiểm tra máy chủ và mạng.');
    } on HttpException {
      throw ApiException('Kết nối API bị gián đoạn. Hãy thử lại.');
    } on FormatException {
      throw ApiException('Máy chủ trả dữ liệu không hợp lệ.');
    }
  }

  static Future<ApiReply> _http(
    String method,
    Uri uri,
    Map<String, String> headers,
    Object? body,
  ) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.openUrl(method, uri);
      headers.forEach(request.headers.set);
      request.headers.contentType = ContentType.json;
      if (body != null) request.write(jsonEncode(body));
      final response = await request.close();
      final bytes = <int>[];
      await for (final chunk in response) {
        bytes.addAll(chunk);
        if (bytes.length > 2 * 1024 * 1024) {
          throw const FormatException('Response too large');
        }
      }
      return ApiReply(
        response.statusCode,
        bytes.isEmpty ? null : jsonDecode(utf8.decode(bytes)),
      );
    } finally {
      client.close(force: true);
    }
  }
}
