import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bvc_network/bvc_network.dart';

class AuthUser {
  AuthUser({
    required this.id,
    required this.email,
    required this.phone,
    required this.name,
    required this.role,
    required this.userKind,
    required this.providerId,
  });

  final String id;
  final String email;
  final String? phone;
  final String name;
  final String role;
  /// APP_CUSTOMER | PROVIDER_ACCOUNT | SYSTEM_STAFF
  final String userKind;
  final String? providerId;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      email: (json['email'] as String?) ?? '',
      phone: json['phone'] as String?,
      name: (json['name'] as String?) ?? '',
      role: (json['role'] as String?) ?? 'USER',
      userKind: (json['userKind'] as String?) ?? 'APP_CUSTOMER',
      providerId: json['providerId'] as String?,
    );
  }
}

class AuthSession {
  AuthSession({required this.accessToken, required this.refreshToken, required this.user});

  final String accessToken;
  final String refreshToken;
  final AuthUser user;
}

/// Auth via Backend JWT (/auth/login, /auth/register) — SĐT + mật khẩu.
abstract class AuthRepository {
  Future<AuthSession?> loadSession();

  Future<AuthSession> login({required String phone, required String password});

  Future<AuthSession> register({required String name, required String phone, required String password});

  /// Làm mới access + refresh (rotation); lưu storage và [onSessionRefreshed] nếu có.
  Future<AuthSession> refreshSession();

  Future<void> signOut();
}

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._network, {void Function()? onSessionRefreshed})
      : _onSessionRefreshed = onSessionRefreshed;

  final NetworkService _network;
  final void Function()? _onSessionRefreshed;

  static const _kTokenKey = 'bvc_access_token';
  static const _kRefreshKey = 'bvc_refresh_token';
  static const _kUserKey = 'bvc_user_json';

  @override
  Future<AuthSession?> loadSession() async {
    final sp = await SharedPreferences.getInstance();
    final token = sp.getString(_kTokenKey);
    final refresh = sp.getString(_kRefreshKey);
    final userRaw = sp.getString(_kUserKey);
    if (token == null || token.isEmpty || userRaw == null || userRaw.isEmpty) return null;
    if (refresh == null || refresh.isEmpty) {
      await signOut();
      return null;
    }
    try {
      final userMap = (jsonDecode(userRaw) as Map).cast<String, dynamic>();
      return AuthSession(accessToken: token, refreshToken: refresh, user: AuthUser.fromJson(userMap));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AuthSession> login({required String phone, required String password}) async {
    try {
      final res = await _network.post<Map<String, dynamic>>(
        '/auth/login',
        data: <String, dynamic>{'identifier': phone.trim(), 'password': password},
      );
      final body = parseApiResponse<Map<String, dynamic>>(
        res.data ?? const {},
        (data) => (data as Map).cast<String, dynamic>(),
      );
      final token = (body.data['accessToken'] as String?) ?? '';
      final refresh = (body.data['refreshToken'] as String?) ?? '';
      final user = AuthUser.fromJson((body.data['user'] as Map).cast<String, dynamic>());
      if (token.isEmpty || refresh.isEmpty) throw Exception('Thiếu token từ máy chủ');
      await _persist(accessToken: token, refreshToken: refresh, user: user);
      return AuthSession(accessToken: token, refreshToken: refresh, user: user);
    } on DioException catch (e) {
      throw Exception(formatDioError(e));
    }
  }

  @override
  Future<AuthSession> register({required String name, required String phone, required String password}) async {
    try {
      final res = await _network.post<Map<String, dynamic>>(
        '/auth/register',
        data: <String, dynamic>{
          'name': name.trim(),
          'phone': phone.trim(),
          'password': password,
        },
      );
      final body = parseApiResponse<Map<String, dynamic>>(
        res.data ?? const {},
        (data) => (data as Map).cast<String, dynamic>(),
      );
      final token = (body.data['accessToken'] as String?) ?? '';
      final refresh = (body.data['refreshToken'] as String?) ?? '';
      final user = AuthUser.fromJson((body.data['user'] as Map).cast<String, dynamic>());
      if (token.isEmpty || refresh.isEmpty) throw Exception('Thiếu token từ máy chủ');
      await _persist(accessToken: token, refreshToken: refresh, user: user);
      return AuthSession(accessToken: token, refreshToken: refresh, user: user);
    } on DioException catch (e) {
      throw Exception(formatDioError(e));
    }
  }

  @override
  Future<AuthSession> refreshSession() async {
    final sp = await SharedPreferences.getInstance();
    final stored = sp.getString(_kRefreshKey);
    if (stored == null || stored.isEmpty) {
      throw Exception('Phiên đăng nhập hết hạn, vui lòng đăng nhập lại');
    }
    try {
      final res = await _network.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: <String, dynamic>{'refreshToken': stored},
      );
      final body = parseApiResponse<Map<String, dynamic>>(
        res.data ?? const {},
        (data) => (data as Map).cast<String, dynamic>(),
      );
      final token = (body.data['accessToken'] as String?) ?? '';
      final refresh = (body.data['refreshToken'] as String?) ?? '';
      final user = AuthUser.fromJson((body.data['user'] as Map).cast<String, dynamic>());
      if (token.isEmpty || refresh.isEmpty) throw Exception('Thiếu token từ máy chủ');
      await _persist(accessToken: token, refreshToken: refresh, user: user);
      final session = AuthSession(accessToken: token, refreshToken: refresh, user: user);
      _onSessionRefreshed?.call();
      return session;
    } on DioException catch (e) {
      throw Exception(formatDioError(e));
    }
  }

  Future<void> _persist({required String accessToken, required String refreshToken, required AuthUser user}) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kTokenKey, accessToken);
    await sp.setString(_kRefreshKey, refreshToken);
    await sp.setString(_kUserKey, jsonEncode(<String, dynamic>{
      'id': user.id,
      'email': user.email,
      'phone': user.phone,
      'name': user.name,
      'role': user.role,
      'userKind': user.userKind,
      'providerId': user.providerId,
    }));
  }

  @override
  Future<void> signOut() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kTokenKey);
    await sp.remove(_kRefreshKey);
    await sp.remove(_kUserKey);
  }
}
