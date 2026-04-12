import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth_providers.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authSessionProvider);
    final session = auth.value;
    final user = session?.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Tài khoản')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (user != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                color: Colors.white.withValues(alpha: 0.04),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Thông tin', style: TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  _RowKV(label: 'Họ tên', value: user.name),
                  if (user.phone != null && user.phone!.isNotEmpty)
                    _RowKV(label: 'Số điện thoại', value: user.phone!)
                  else if (user.email.isNotEmpty)
                    _RowKV(label: 'Email', value: user.email),
                  _RowKV(label: 'Loại tài khoản', value: _kindLabel(user.userKind)),
                  _RowKV(label: 'Role', value: user.role),
                ],
              ),
            )
          else if (auth.isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else
            const Text('Chưa đăng nhập.', style: TextStyle(color: Color(0xFFA0B4C8))),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: user == null
                ? null
                : () async {
                    await ref.read(authSessionProvider.notifier).signOut();
                    if (context.mounted) context.go('/login');
                  },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Đăng xuất'),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB00020)),
          ),
          const SizedBox(height: 10),
          const Text(
            'Đăng xuất sẽ xoá token trên máy. Lần sau mở app sẽ yêu cầu đăng nhập lại.',
            style: TextStyle(color: Color(0xFFA0B4C8), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

String _kindLabel(String k) {
  switch (k) {
    case 'APP_CUSTOMER':
      return 'Khách hàng (app)';
    case 'PROVIDER_ACCOUNT':
      return 'Nhà cung cấp';
    case 'SYSTEM_STAFF':
      return 'Vận hành hệ thống';
    default:
      return k;
  }
}

class _RowKV extends StatelessWidget {
  const _RowKV({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Color(0xFFA0B4C8)))),
          const SizedBox(width: 10),
          Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }
}

