import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'package:bvc_common/bvc_common.dart';
import 'package:bvc_ui/bvc_ui.dart';

import '../../domain/entities/service_item.dart';

class ServiceCard extends StatelessWidget {
  const ServiceCard({super.key, required this.item});

  final ServiceItem item;

  @override
  Widget build(BuildContext context) {
    final icon = switch (item.type) {
      'ACCOMMODATION' => Icons.hotel_rounded,
      'FOOD' => Icons.restaurant_rounded,
      _ => Icons.local_offer_rounded,
    };

    final scheme = Theme.of(context).colorScheme;
    final accent = item.type == 'ACCOMMODATION'
        ? const Color(0xFF4A90C4)
        : item.type == 'FOOD'
            ? const Color(0xFFE8834A)
            : scheme.primary;

    final priceText = formatVnd(item.price);
    final unit = item.type == 'ACCOMMODATION' ? '/đêm' : item.type == 'FOOD' ? '/suất' : '';
    final tagline = item.type == 'ACCOMMODATION'
        ? 'Phòng nghỉ • tắm rửa • ngủ sớm dậy sớm'
        : item.type == 'FOOD'
            ? 'Đặt trước • món gọn • mang theo'
            : 'Dịch vụ';
    final heroLabel = item.type == 'ACCOMMODATION'
        ? 'KHÁCH SẠN'
        : item.type == 'FOOD'
            ? 'NHÀ HÀNG'
            : 'DỊCH VỤ';

    void openPrimaryDetail() {
      if (item.type == 'ACCOMMODATION') {
        Modular.to.pushNamed('/services/accommodation/${item.id}');
        return;
      }
      if (item.type == 'FOOD') {
        Modular.to.pushNamed(
          Uri(
            path: '/book/service/${item.id}',
            queryParameters: <String, String>{
              'title': 'Đặt: ${item.name}',
              'type': item.type,
              'name': item.name,
            },
          ).toString(),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có màn chi tiết cho loại dịch vụ này.')),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [
              accent.withValues(alpha: 0.18),
              const Color(0xFF1A2D3E),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: accent.withValues(alpha: 0.22)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: openPrimaryDetail,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ServiceHero(
                      accent: accent,
                      label: heroLabel,
                      imageUrl: item.images.isNotEmpty ? item.images.first : null,
                      fallbackIcon: icon,
                    ),
                    if (item.images.length > 1)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                        child: SizedBox(
                          height: 58,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: item.images.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, i) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SafeNetworkImage(
                                  url: item.images[i],
                                  width: 88,
                                  height: 58,
                                  fit: BoxFit.cover,
                                  errorWidget: Container(
                                    width: 88,
                                    height: 58,
                                    color: const Color(0xFF1A2D3E),
                                    alignment: Alignment.center,
                                    child: Icon(Icons.image_not_supported_outlined, size: 22, color: accent.withValues(alpha: 0.45)),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(tagline, style: const TextStyle(color: Color(0xFFA0B4C8), fontSize: 12)),
                                    if (item.providerName != null && item.providerName!.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.storefront_rounded, size: 15, color: accent.withValues(alpha: 0.95)),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              item.providerName!,
                                              style: const TextStyle(
                                                color: Color(0xFF8FA8C0),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.20),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: accent.withValues(alpha: 0.22)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      priceText,
                                      style: const TextStyle(color: Color(0xFFF2C94C), fontWeight: FontWeight.w900),
                                    ),
                                    if (unit.isNotEmpty)
                                      Text(
                                        unit,
                                        style: const TextStyle(color: Color(0xFFA0B4C8), fontSize: 11, height: 1.1),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (item.description.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              item.description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Color(0xFFA0B4C8), height: 1.25),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _PillChip(
                                accent: accent,
                                icon: item.type == 'ACCOMMODATION' ? Icons.bed_rounded : Icons.restaurant_menu_rounded,
                                label: item.type == 'ACCOMMODATION' ? 'Nghỉ ngơi' : 'Ăn uống',
                              ),
                              _PillChip(
                                accent: accent,
                                icon: Icons.groups_rounded,
                                label: 'Sức chứa ${item.maxCapacity}',
                              ),
                              if (item.images.isNotEmpty)
                                _PillChip(
                                  accent: accent,
                                  icon: Icons.photo_library_rounded,
                                  label: '${item.images.length} ảnh',
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (item.type == 'ACCOMMODATION') {
                          Modular.to.pushNamed('/services/accommodation/${item.id}');
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('MVP: sẽ thêm liên hệ/đặt chỗ sau.')),
                        );
                      },
                      icon: Icon(item.type == 'ACCOMMODATION' ? Icons.info_outline_rounded : Icons.bookmark_add_outlined),
                      label: Text(item.type == 'ACCOMMODATION' ? 'Chi tiết' : 'Lưu'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        if (item.type == 'ACCOMMODATION') {
                          final d = ymd(DateTime.now().add(const Duration(days: 1)));
                          Modular.to.pushNamed('/book/accommodation/${item.id}?date=$d');
                          return;
                        }
                        Modular.to.pushNamed(
                          Uri(
                            path: '/book/service/${item.id}',
                            queryParameters: <String, String>{
                              'title': 'Đặt: ${item.name}',
                              'type': item.type,
                              'name': item.name,
                            },
                          ).toString(),
                        );
                      },
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(item.type == 'ACCOMMODATION' ? 'Đặt phòng' : 'Đặt chỗ'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceHero extends StatelessWidget {
  const _ServiceHero({
    required this.accent,
    required this.label,
    required this.imageUrl,
    required this.fallbackIcon,
  });

  final Color accent;
  final String label;
  final String? imageUrl;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    const height = 108.0;

    Widget background;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      background = SafeNetworkImage(
        url: imageUrl!,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorWidget: _HeroFallback(height: height, accent: accent, icon: fallbackIcon),
      );
    } else {
      background = _HeroFallback(height: height, accent: accent, icon: fallbackIcon);
    }

    return Stack(
      children: [
        background,
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.05),
                  Colors.black.withValues(alpha: 0.55),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        Positioned(
          left: 12,
          top: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 8,
                  width: 8,
                  decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.6)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroFallback extends StatelessWidget {
  const _HeroFallback({required this.height, required this.accent, required this.icon});
  final double height;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.30),
            const Color(0xFF0F2232),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(icon, size: 44, color: Colors.white.withValues(alpha: 0.92)),
      ),
    );
  }
}

class _PillChip extends StatelessWidget {
  const _PillChip({required this.accent, required this.icon, required this.label});
  final Color accent;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: accent.withValues(alpha: 0.95)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

