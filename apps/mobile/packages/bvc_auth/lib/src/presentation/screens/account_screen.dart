import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth_providers.dart';
import 'package:bvc_ui/bvc_ui.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authSessionProvider);
    final session = auth.value;
    final user = session?.user;

    return Stack(
      children: [
        const Positioned.fill(child: WavesBackground()),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Tài khoản'),
            centerTitle: false,
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (auth.isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
              else if (user == null)
                const _FullHint(
                  title: 'Chưa đăng nhập',
                  description: 'Đăng nhập để đặt dịch vụ và xem lịch sử.',
                )
              else ...[
                _ProfileCard(
                  name: user.name.isNotEmpty ? user.name : 'Tài khoản',
                  email: user.email,
                  onEdit: () {},
                ),
                const SizedBox(height: 12),
                const _SectionTitle(text: 'Lịch sử đặt dịch vụ'),
                const SizedBox(height: 10),
                _MenuTile(
                  icon: Icons.receipt_long_rounded,
                  title: 'Lịch sử đặt dịch vụ',
                  subtitle: 'Xem danh sách đơn của bạn',
                  onTap: () => context.go('/book/mine'),
                ),
                const SizedBox(height: 14),
                _MenuTile(
                  icon: Icons.person_rounded,
                  title: 'Thông tin cá nhân',
                  subtitle: 'Chỉnh sửa hồ sơ',
                  onTap: () {},
                ),
                const SizedBox(height: 10),
                _MenuTile(
                  icon: Icons.notifications_rounded,
                  title: 'Thông báo',
                  subtitle: 'Quản lý thông báo',
                  onTap: () {},
                ),
                const SizedBox(height: 10),
                _MenuTile(
                  icon: Icons.settings_rounded,
                  title: 'Cài đặt',
                  subtitle: 'Tuỳ chỉnh ứng dụng',
                  onTap: () {},
                ),
                const SizedBox(height: 10),
                _MenuTile(
                  icon: Icons.help_outline_rounded,
                  title: 'Trợ giúp',
                  subtitle: 'Câu hỏi thường gặp',
                  onTap: () {},
                ),
                const SizedBox(height: 18),
                Center(
                  child: TextButton.icon(
                    onPressed: () async {
                      await ref.read(authSessionProvider.notifier).signOut();
                      if (context.mounted) context.go('/login');
                    },
                    icon: const Icon(Icons.logout_rounded, color: AppColors.destructive),
                    label: const Text('Đăng xuất', style: TextStyle(color: AppColors.destructive, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: AppColors.mutedForeground,
      ),
    );
  }
}

class _FullHint extends StatelessWidget {
  const _FullHint({required this.title, required this.description});
  final String title;
  final String description;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 72,
              width: 72,
              decoration: BoxDecoration(color: AppColors.muted.withValues(alpha: 0.45), shape: BoxShape.circle),
              child: const Icon(Icons.person_outline_rounded, color: AppColors.mutedForeground, size: 34),
            ),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 8),
            Text(description, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.mutedForeground)),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.name, required this.email, required this.onEdit});
  final String name;
  final String email;
  final VoidCallback onEdit;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadii.x2l),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
            ),
            child: const Icon(Icons.person_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 2),
                Text(email, style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
              ],
            ),
          ),
          TextButton(onPressed: onEdit, child: const Text('Đổi')),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.x2l),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.40),
            borderRadius: BorderRadius.circular(AppRadii.x2l),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
          ),
          child: Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(AppRadii.base),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
                ),
                child: Icon(icon, color: AppColors.mutedForeground),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.mutedForeground.withValues(alpha: 0.85)),
            ],
          ),
        ),
      ),
    );
  }
}

