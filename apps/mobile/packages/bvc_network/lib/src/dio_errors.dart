import 'package:dio/dio.dart';

/// Chuỗi hiển thị cho người dùng (API Nest `apiError`, timeout, mất mạng, …).
String formatDioError(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map) {
      final success = data['success'];
      final msg = data['message'];
      if (success == false && msg != null) {
        if (msg is String && msg.isNotEmpty) return msg;
        if (msg is List && msg.isNotEmpty) {
          return msg.map((x) => x.toString()).join(', ');
        }
      }
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Hết giờ chờ máy chủ. Kiểm tra API đang chạy và mạng.';
      case DioExceptionType.connectionError:
        final base = e.requestOptions.baseUrl;
        return 'Không kết nối được máy chủ ($base). '
            'Bật backend, kiểm tra adb reverse (Android) hoặc đúng IP.';
      default:
        break;
    }

    final uri = e.requestOptions.uri;
    final base = '${e.type.name}${uri.toString().isNotEmpty ? ' • $uri' : ''}';
    if (e.response != null) {
      return '$base • HTTP ${e.response!.statusCode}';
    }
    final msg = e.message;
    if (msg != null && msg.isNotEmpty) return '$base • $msg';
    return base;
  }
  final raw = e.toString();
  if (raw.startsWith('Exception: ')) return raw.substring(11);
  return raw;
}
