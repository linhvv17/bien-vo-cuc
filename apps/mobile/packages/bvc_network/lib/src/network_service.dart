import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bvc_auth/bvc_auth.dart';

import 'env.dart';

// --- Token / interceptor / timeouts: toàn bộ tại đây, không tạo Dio ở module con ---

/// Login / register / refresh: không gắn Bearer (tránh loop 401 ↔ refresh).
bool _isAuthPublicRequest(RequestOptions o) {
  final Uri uri;
  if (o.uri.hasScheme) {
    uri = o.uri;
  } else {
    final base = Uri.parse(o.baseUrl);
    final p = o.path.startsWith('/') ? o.path : '/${o.path}';
    uri = base.resolveUri(Uri.parse(p));
  }
  final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  return segs.length == 2 &&
      segs[0] == 'auth' &&
      (segs[1] == 'login' || segs[1] == 'register' || segs[1] == 'refresh');
}

Future<AuthSession>? _refreshInFlight;

final apiBaseUrlProvider = Provider<String>((ref) => resolveApiBaseUrl());

/// [Dio] duy nhất — private trong package; module con không được phụ thuộc trực tiếp.
final Provider<Dio> _appDioProvider = Provider<Dio>((ref) {
  final base = ref.watch(apiBaseUrlProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: base,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 12),
      headers: const <String, dynamic>{'Accept': 'application/json'},
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final isPublicAuth = _isAuthPublicRequest(options);
        if (isPublicAuth) {
          options.headers.remove('Authorization');
          return handler.next(options);
        }
        String? token;
        try {
          final session = await ref.read(authSessionProvider.future);
          token = session?.accessToken;
        } catch (_) {
          token = null;
        }
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        } else {
          options.headers.remove('Authorization');
        }
        return handler.next(options);
      },
      onError: (DioException err, ErrorInterceptorHandler handler) async {
        if (err.response?.statusCode != 401) {
          return handler.next(err);
        }
        final opts = err.requestOptions;
        if (opts.extra['authRetried'] == true) {
          return handler.next(err);
        }
        if (_isAuthPublicRequest(opts)) {
          return handler.next(err);
        }
        try {
          Future<AuthSession> fut;
          if (_refreshInFlight != null) {
            fut = _refreshInFlight!;
          } else {
            fut = ref.read(authRepositoryProvider).refreshSession();
            _refreshInFlight = fut;
            fut.whenComplete(() {
              if (identical(_refreshInFlight, fut)) {
                _refreshInFlight = null;
              }
            });
          }
          final session = await fut;
          opts.headers['Authorization'] = 'Bearer ${session.accessToken}';
          opts.extra['authRetried'] = true;
          final response = await dio.fetch(opts);
          return handler.resolve(response);
        } catch (_) {
          await ref.read(authSessionProvider.notifier).signOut();
          return handler.next(err);
        }
      },
    ),
  );
  return dio;
});

/// Façade HTTP cho toàn app: **mọi module** inject [networkServiceProvider] và chỉ gọi
/// [get] / [post] / … — không khởi tạo [Dio], không import `dio` cho client.
class NetworkService {
  NetworkService(this._dio);

  final Dio _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }
}

/// **Inject provider này** vào repository / feature — không dùng [Dio] trực tiếp.
final Provider<NetworkService> networkServiceProvider = Provider<NetworkService>((ref) {
  return NetworkService(ref.watch(_appDioProvider));
});
