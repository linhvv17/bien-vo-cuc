import 'dart:async';

import 'package:bvc_auth/bvc_auth.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// [ProviderContainer] gốc (đặt trong [main]) để guard đọc [authSessionProvider].
ProviderContainer? appProviderContainer;

/// Chặn route khi chưa đăng nhập.
class AppAuthGuard extends RouteGuard {
  AppAuthGuard() : super(redirectTo: '/login');

  @override
  FutureOr<bool> canActivate(String path, ParallelRoute route) async {
    final c = appProviderContainer;
    if (c == null) return false;
    final auth = await c.read(authSessionProvider.future);
    return auth != null;
  }
}
