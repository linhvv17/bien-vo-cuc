import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bvc_network/bvc_network.dart';
import 'package:bvc_ui/bvc_ui.dart';

import '../../auth_providers.dart';
import '../../credential_store.dart';
import '../../phone_password_validation.dart';
import '../widgets/coastal_auth_layout.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
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
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final remember = await CredentialStore.getRememberDefault();
    final saved = await CredentialStore.loadIfRemembered();
    if (!mounted) return;
    setState(() {
      _rememberCredentials = remember;
      _loadedPrefs = true;
      if (saved.phone != null && saved.phone!.isNotEmpty) {
        _phone.text = saved.phone!;
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final normalized = normalizeVietnameseMobilePhone(_phone.text);
    final password = _password.text;

    if (name.length < 2) {
      setState(() => _error = 'Họ tên ít nhất 2 ký tự.');
      return;
    }
    if (normalized == null) {
      setState(() => _error = 'Số điện thoại di động Việt Nam không hợp lệ (vd: 0912345678).');
      return;
    }
    if (!isBasicPassword(password)) {
      setState(
        () => _error = 'Mật khẩu 8–64 ký tự, gồm ít nhất một chữ cái (a-z, A-Z) và một chữ số.',
      );
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(authSessionProvider.notifier).register(name: name, phone: normalized, password: password);
      await CredentialStore.setRemember(_rememberCredentials);
      if (_rememberCredentials) {
        await CredentialStore.save(normalizedPhone: normalized, password: password);
      } else {
        await CredentialStore.clear();
      }
      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = formatDioError(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Đăng ký'),
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
                  title: 'Bước vào hành trình biển',
                  subtitle:
                      'Tạo tài khoản bằng số điện thoại — không OTP. Cùng xem triều, thời tiết và đặt chỗ tại Thụy Xuân, Thái Thụy.',
                ),
                const SizedBox(height: 8),
                AuthGlassCard(
                  child: TextField(
                    controller: _name,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Họ tên',
                      hintText: 'Nguyễn Văn A',
                      prefixIcon: Icon(
                        Icons.person_outline_rounded,
                        color: AppColors.secondary.withValues(alpha: 0.85),
                        size: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
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
                      helperText: '8–64 ký tự, có chữ cái và số',
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
                  onChanged: _loadedPrefs ? (v) => setState(() => _rememberCredentials = v ?? true) : null,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Ghi nhớ để lần sau đăng nhập nhanh'),
                  subtitle: Text(
                    'Lưu SĐT và mật khẩu an toàn trên máy.',
                    style: TextStyle(fontSize: 11, color: AppColors.mutedForeground.withValues(alpha: 0.95)),
                  ),
                ),
                const SizedBox(height: 14),
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
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                  ).copyWith(
                    elevation: WidgetStateProperty.resolveWith((s) {
                      if (s.contains(WidgetState.disabled)) return 0.0;
                      return 2.0;
                    }),
                  ),
                  onPressed: _submitting || !_loadedPrefs ? null : _submit,
                  child: Text(_submitting ? 'Đang tạo...' : 'Tạo tài khoản'),
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child: Text(
                      'Đã có tài khoản? Quay lại đăng nhập',
                      style: TextStyle(color: AppColors.goldGlow.withValues(alpha: 0.92)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
