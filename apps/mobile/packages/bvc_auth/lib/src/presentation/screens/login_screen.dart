import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bvc_network/bvc_network.dart';

import '../../auth_providers.dart';
import '../../credential_store.dart';
import '../../phone_password_validation.dart';

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
      context.go('/home');
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

    return Scaffold(
      appBar: AppBar(title: const Text('Đăng nhập')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Chào mừng bạn', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 6),
          const Text('Đăng nhập bằng số điện thoại và mật khẩu.', style: TextStyle(color: Color(0xFFA0B4C8))),
          const SizedBox(height: 18),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s.-]'))],
            decoration: const InputDecoration(
              labelText: 'Số điện thoại',
              hintText: 'Ví dụ: 0912345678',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Mật khẩu'),
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
            title: const Text('Ghi nhớ tài khoản trên máy này'),
            subtitle: const Text(
              'Số điện thoại và mật khẩu được lưu an toàn (Keystore / Keychain).',
              style: TextStyle(fontSize: 11, color: Color(0xFF7A8A9A)),
            ),
          ),
          const SizedBox(height: 6),
          if (_loadedPrefs)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _clearSaved,
                child: const Text('Xóa thông tin đã lưu'),
              ),
            ),
          const SizedBox(height: 8),
          if (_error != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFB00020).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFB00020).withValues(alpha: 0.35)),
              ),
              child: Text(
                _error!,
                style: const TextStyle(color: Color(0xFFFFCCBC), height: 1.35),
              ),
            ),
            const SizedBox(height: 10),
          ],
          FilledButton(
            onPressed: _submitting || !_loadedPrefs ? null : _submit,
            child: Text(_submitting ? 'Đang đăng nhập...' : 'Đăng nhập'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => context.push('/register'),
            child: const Text('Chưa có tài khoản? Đăng ký'),
          ),
          const SizedBox(height: 12),
          if (session.isLoading) const LinearProgressIndicator(),
        ],
      ),
    );
  }
}
