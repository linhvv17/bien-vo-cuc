import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bvc_ui/bvc_ui.dart';

class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        const Positioned.fill(child: WavesBackground()),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Đặt dịch vụ'),
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            centerTitle: true,
          ),
          body: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              Text(
                'Chọn loại dịch vụ',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 0.2),
              ),
              const SizedBox(height: 8),
              const Text(
                'Gửi yêu cầu đặt chỗ — trạng thái sẽ được xác nhận sau.',
                style: TextStyle(color: Color(0xFFA0B4C8), height: 1.35),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _QuickBookingCard(
                      title: 'Ngủ nghỉ',
                      subtitle: 'Homestay / nhà nghỉ',
                      icon: Icons.hotel_rounded,
                      colors: const [Color(0x334A90C4), Color(0x221A2D3E)],
                      accent: const Color(0xFF4A90C4),
                      onTap: () => context.push('/book/hotel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickBookingCard(
                      title: 'Ăn uống',
                      subtitle: 'Đặt món / suất ăn',
                      icon: Icons.restaurant_rounded,
                      colors: const [Color(0x33E8834A), Color(0x221A2D3E)],
                      accent: const Color(0xFFE8834A),
                      onTap: () => context.push('/book/food'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _QuickBookingCard(
                      title: 'Xe xích',
                      subtitle: 'Di chuyển trên bãi',
                      icon: Icons.directions_car_rounded,
                      colors: const [Color(0x334A90C4), Color(0x221A2D3E)],
                      accent: const Color(0xFF4A90C4),
                      onTap: () => context.push('/book/vehicle'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickBookingCard(
                      title: 'Chụp ảnh',
                      subtitle: 'Flycam & ekip',
                      icon: Icons.photo_camera_rounded,
                      colors: const [Color(0x33E8834A), Color(0x221A2D3E)],
                      accent: const Color(0xFFE8834A),
                      onTap: () => context.push('/book/photo'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _LinkRow(
                icon: Icons.receipt_long_rounded,
                iconBg: const Color(0xFF4A90C4),
                title: 'Đặt chỗ của tôi',
                subtitle: 'Danh sách đơn theo tài khoản',
                onTap: () => context.push('/book/mine'),
              ),
              const SizedBox(height: 10),
              _LinkRow(
                icon: Icons.person_rounded,
                iconBg: const Color(0xFFE8834A),
                title: 'Tài khoản',
                subtitle: 'Thông tin & đăng xuất',
                onTap: () => context.push('/account'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickBookingCard extends StatelessWidget {
  const _QuickBookingCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 8))],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Colors.white.withValues(alpha: 0.95), size: 26),
                ),
                const SizedBox(height: 12),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Color(0xFFA0B4C8), fontSize: 12, height: 1.25)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withValues(alpha: 0.05),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBg.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconBg.withValues(alpha: 0.95), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(color: Color(0xFFA0B4C8), fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.45)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
