import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bvc_network/bvc_network.dart';

import '../../auth_providers.dart';
import '../../credential_store.dart';
import '../../phone_password_validation.dart';

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
      appBar: AppBar(title: const Text('Đăng ký')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Tạo tài khoản', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 6),
          const Text('Đăng ký bằng SĐT và mật khẩu (không OTP).', style: TextStyle(color: Color(0xFFA0B4C8))),
          const SizedBox(height: 18),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Họ tên'),
          ),
          const SizedBox(height: 12),
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
            decoration: const InputDecoration(
              labelText: 'Mật khẩu',
              helperText: '8–64 ký tự, có chữ cái và số',
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
            subtitle: const Text(
              'Lưu SĐT và mật khẩu an toàn trên máy.',
              style: TextStyle(fontSize: 11, color: Color(0xFF7A8A9A)),
            ),
          ),
          const SizedBox(height: 14),
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
            child: Text(_submitting ? 'Đang tạo...' : 'Tạo tài khoản'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Đã có tài khoản? Quay lại đăng nhập'),
          ),
        ],
      ),
    );
  }
}
