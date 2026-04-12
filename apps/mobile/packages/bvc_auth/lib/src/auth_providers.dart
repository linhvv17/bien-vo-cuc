import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_repository.dart';
import 'package:bvc_network/bvc_network.dart';

final Provider<AuthRepository> authRepositoryProvider = Provider<AuthRepository>((ref) {
  final network = ref.watch(networkServiceProvider);
  return AuthRepositoryImpl(
    network,
    onSessionRefreshed: () => ref.invalidate(authSessionProvider),
  );
});

class AuthSessionController extends AsyncNotifier<AuthSession?> {
  @override
  Future<AuthSession?> build() async {
    // [read] thay vì [watch]: tránh mỗi lần Dio/repo đổi lại gọi loadSession → kẹt AsyncLoading.
    final repo = ref.read(authRepositoryProvider);
    return repo.loadSession();
  }

  Future<void> login({required String phone, required String password}) async {
    final repo = ref.read(authRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => repo.login(phone: phone, password: password));
    // AsyncValue.guard không throw — UI phải biết thất bại; ném lại để try/catch hiển thị lỗi.
    if (state.hasError) throw state.error!;
  }

  Future<void> register({required String name, required String phone, required String password}) async {
    final repo = ref.read(authRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => repo.register(name: name, phone: phone, password: password));
    if (state.hasError) throw state.error!;
  }

  Future<void> signOut() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.signOut();
    state = const AsyncData(null);
  }
}

final authSessionProvider = AsyncNotifierProvider<AuthSessionController, AuthSession?>(AuthSessionController.new);
