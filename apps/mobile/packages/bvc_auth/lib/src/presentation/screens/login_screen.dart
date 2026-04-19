import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'package:bvc_network/bvc_network.dart';
import 'package:bvc_ui/bvc_ui.dart';

import '../../auth_providers.dart';
import '../../auth_repository.dart';
import '../../credential_store.dart';
import '../../phone_password_validation.dart';
import '../widgets/coastal_auth_layout.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _submitting = false;
  String? _error;
  bool _rememberCredentials = true;
  bool _loadedPrefs = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final remember = await CredentialStore.getRememberDefault();
    final saved = await CredentialStore.loadIfRemembered();
    if (!mounted) return;
    setState(() {
      _rememberCredentials = remember;
      _loadedPrefs = true;
      if (saved.phone != null && saved.phone!.isNotEmpty) {
        _phone.text = saved.phone!;
      }
      if (saved.password != null && saved.password!.isNotEmpty) {
        _password.text = saved.password!;
      }
    });
  }

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _persistCredentialsIfNeeded(String normalizedPhone, String password) async {
    await CredentialStore.setRemember(_rememberCredentials);
    if (_rememberCredentials) {
      await CredentialStore.save(normalizedPhone: normalizedPhone, password: password);
    } else {
      await CredentialStore.clear();
    }
  }

  Future<void> _submit() async {
    final normalized = normalizeVietnameseMobilePhone(_phone.text);
    if (normalized == null) {
      setState(() => _error = 'Nhập số điện thoại di động Việt Nam hợp lệ (vd: 0912345678).');
      return;
    }
    if (_password.text.isEmpty) {
      setState(() => _error = 'Nhập mật khẩu.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(authSessionProvider.notifier).login(phone: normalized, password: _password.text);
      await _persistCredentialsIfNeeded(normalized, _password.text);
      if (!mounted) return;
      Modular.to.navigate('/main');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = formatDioError(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _clearSaved() async {
    await CredentialStore.clear();
    if (!mounted) return;
    setState(() {
      _rememberCredentials = false;
      _password.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xóa số và mật khẩu đã lưu trên máy.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);

    ref.listen<AsyncValue<AuthSession?>>(authSessionProvider, (prev, next) {
      next.whenData((s) {
        if (s == null) return;
        if (!context.mounted) return;
        final p = Modular.to.path;
        if (p != '/login' && p != '/register') return;
        Modular.to.navigate('/main');
      });
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Đăng nhập'),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CoastalAuthBackdrop(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                const CoastalAuthHero(
                  title: 'Chào bạn trở lại',
                  subtitle:
                      'Đăng nhập để xem triều, thời tiết và đặt dịch vụ tại Biển Vô Cực — nơi trời và nước gặp nhau.',
                ),
                const SizedBox(height: 8),
                AuthGlassCard(
                  child: TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s.-]'))],
                    decoration: InputDecoration(
                      labelText: 'Số điện thoại',
                      hintText: 'Ví dụ: 0912345678',
                      prefixIcon: Icon(
                        Icons.phone_iphone_rounded,
                        color: AppColors.secondary.withValues(alpha: 0.85),
                        size: 22,
                      ),
                      suffixIcon: _phone.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Xoá',
                              onPressed: () => setState(() => _phone.clear()),
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 12),
                AuthGlassCard(
                  child: TextField(
                    controller: _password,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submitting || !_loadedPrefs ? null : _submit(),
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      prefixIcon: Icon(
                        Icons.lock_outline_rounded,
                        color: AppColors.secondary.withValues(alpha: 0.85),
                        size: 22,
                      ),
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        icon: Icon(_obscurePassword ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: _rememberCredentials,
                  onChanged: _loadedPrefs
                      ? (v) => setState(() => _rememberCredentials = v ?? true)
                      : null,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppColors.secondary,
                  checkColor: AppColors.background,
                  title: const Text('Ghi nhớ tài khoản trên máy này'),
                  subtitle: Text(
                    'Số điện thoại và mật khẩu được lưu an toàn (Keystore / Keychain).',
                    style: TextStyle(fontSize: 11, color: AppColors.mutedForeground.withValues(alpha: 0.95)),
                  ),
                ),
                const SizedBox(height: 6),
                if (_loadedPrefs)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: _clearSaved,
                      child: Text(
                        'Xóa thông tin đã lưu',
                        style: TextStyle(color: AppColors.oceanLight.withValues(alpha: 0.95)),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                if (_error != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.destructive.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppRadii.base),
                      border: Border.all(color: AppColors.destructive.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppColors.foreground, height: 1.35),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                FilledButton(
                  style: FilledButton.styleFrom(
                    elevation: 0,
                    shadowColor: AppColors.primary.withValues(alpha: 0.45),
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                  ).copyWith(
                    elevation: WidgetStateProperty.resolveWith((s) {
                      if (s.contains(WidgetState.disabled)) return 0.0;
                      return 2.0;
                    }),
                  ),
                  onPressed: _submitting || !_loadedPrefs ? null : _submit,
                  child: Text(_submitting ? 'Đang đăng nhập...' : 'Đăng nhập'),
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: () => Modular.to.pushNamed('/register'),
                    child: Text(
                      'Chưa có tài khoản? Đăng ký',
                      style: TextStyle(color: AppColors.goldGlow.withValues(alpha: 0.92)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (session.isLoading) const LinearProgressIndicator(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
