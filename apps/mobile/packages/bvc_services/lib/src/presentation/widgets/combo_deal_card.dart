import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bvc_common/bvc_common.dart';
import '../../domain/entities/combo_deal.dart';

class ComboDealCard extends StatelessWidget {
  const ComboDealCard({super.key, required this.combo});

  final ComboDeal combo;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final discounted = formatVnd(combo.discountedTotal);
    final original = formatVnd(combo.originalTotal);
    final saved = formatVnd(combo.saved);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF2C94C).withValues(alpha: 0.18),
            const Color(0xFFE8834A).withValues(alpha: 0.10),
            const Color(0xFF1A2D3E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _DiscountBadge(percent: combo.discountPercent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tiết kiệm $saved',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFFA0B4C8), fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  discounted,
                  style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ComboMiniCard(
                    accent: const Color(0xFF4A90C4),
                    icon: Icons.hotel_rounded,
                    title: 'Khách sạn',
                    name: combo.hotel.name,
                    subtitle: 'Phòng nghỉ • xuất phát sớm',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ComboMiniCard(
                    accent: const Color(0xFFE8834A),
                    icon: Icons.restaurant_rounded,
                    title: 'Ăn uống',
                    name: combo.food.name,
                    subtitle: 'Món gọn • mang theo',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Giá gốc $original',
                  style: const TextStyle(
                    color: Color(0xFFA0B4C8),
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => context.push('/book/combo/${combo.id}'),
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: const Text('Chọn combo'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscountBadge extends StatelessWidget {
  const _DiscountBadge({required this.percent});
  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF2C94C).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFF2C94C).withValues(alpha: 0.30)),
      ),
      child: Text(
        '-$percent%',
        style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFF2C94C)),
      ),
    );
  }
}

class _ComboMiniCard extends StatelessWidget {
  const _ComboMiniCard({
    required this.accent,
    required this.icon,
    required this.title,
    required this.name,
    required this.subtitle,
  });

  final Color accent;
  final IconData icon;
  final String title;
  final String name;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.black.withValues(alpha: 0.16),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Color(0xFFA0B4C8), fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFA0B4C8), fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

