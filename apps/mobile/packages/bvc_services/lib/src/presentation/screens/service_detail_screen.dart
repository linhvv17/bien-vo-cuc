import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'package:bvc_common/bvc_common.dart';
import 'package:bvc_ui/bvc_ui.dart';
import '../../domain/entities/service_item.dart';

class ServiceDetailScreen extends StatelessWidget {
  const ServiceDetailScreen({super.key, required this.item});

  final ServiceItem item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = item.type == 'ACCOMMODATION' ? AppColors.secondary : cs.primary;
    final unit = item.type == 'ACCOMMODATION' ? '/đêm' : '/người';

    return Stack(
      children: [
        const Positioned.fill(child: WavesBackground()),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Modular.to.pop(),
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadii.x2l),
                        child: item.images.isNotEmpty
                            ? SafeNetworkImage(
                                url: item.images.first,
                                height: 220,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorWidget: _HeroFallback(accent: accent),
                              )
                            : _HeroFallback(accent: accent),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Rating from API not available yet; keep UI but neutral.
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.muted.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(AppRadii.xl),
                              border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star_rounded, color: AppColors.primary, size: 18),
                                SizedBox(width: 4),
                                Text('—', style: TextStyle(fontWeight: FontWeight.w900)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Tag(text: item.type == 'FOOD' ? 'Hải sản' : 'Lưu trú', accent: accent),
                          const _Tag(text: 'View biển', accent: AppColors.mutedForeground),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        item.description.isEmpty ? 'Dịch vụ tại Biển Vô Cực, Thái Bình.' : item.description,
                        style: const TextStyle(color: AppColors.mutedForeground, height: 1.35),
                      ),
                      const SizedBox(height: 18),
                      if (item.addressLine != null && item.addressLine!.isNotEmpty)
                        _InfoRow(icon: Icons.place_rounded, text: item.addressLine!)
                      else
                        const _InfoRow(icon: Icons.place_rounded, text: 'Biển Vô Cực, Thái Bình'),
                      if (item.locationSummary != null && item.locationSummary!.isNotEmpty)
                        _InfoRow(icon: Icons.info_outline_rounded, text: item.locationSummary!),
                      if (item.providerName != null && item.providerName!.isNotEmpty)
                        _InfoRow(icon: Icons.storefront_rounded, text: item.providerName!),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: AppColors.card.withValues(alpha: 0.95),
                border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.55))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${formatVnd(item.price)} VND$unit',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    child: FilledButton(
                      onPressed: () {
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
                      child: const Text('Đặt ngay'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroFallback extends StatelessWidget {
  const _HeroFallback({required this.accent});
  final Color accent;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withValues(alpha: 0.22), AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.waves_rounded, color: AppColors.mutedForeground.withValues(alpha: 0.65), size: 48),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.accent});
  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Text(text, style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w800)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: AppColors.card.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(AppRadii.base),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
            ),
            child: Icon(icon, color: AppColors.mutedForeground),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

