import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bvc_common/bvc_common.dart';
import 'package:bvc_ui/bvc_ui.dart';
import '../providers/services_providers.dart';
import '../../domain/entities/service_item.dart';

class ServicesScreen extends ConsumerStatefulWidget {
  const ServicesScreen({super.key});

  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen> {
  String _tab = 'ALL';
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hotelsAsync = ref.watch(hotelsProvider);
    final foodAsync = ref.watch(foodProvider);

    final items = <ServiceItem>[
      ...hotelsAsync.maybeWhen(data: (v) => v, orElse: () => const <ServiceItem>[]),
      ...foodAsync.maybeWhen(data: (v) => v, orElse: () => const <ServiceItem>[]),
    ];

    final q = _q.text.trim().toLowerCase();
    final filtered = items.where((x) {
      if (_tab == 'ALL') return true;
      return x.type == _tab;
    }).where((x) {
      if (q.isEmpty) return true;
      return x.name.toLowerCase().contains(q) || x.description.toLowerCase().contains(q);
    }).toList(growable: false);

    return Stack(
      children: [
        const Positioned.fill(child: WavesBackground()),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Ăn & Ở'),
            centerTitle: false,
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(hotelsProvider);
              ref.invalidate(foodProvider);
              await Future.wait([
                ref.read(hotelsProvider.future),
                ref.read(foodProvider.future),
              ]);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _SearchBar(
                  controller: _q,
                  hint: 'Tìm dịch vụ...',
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                _CategoryRow(
                  active: _tab,
                  onChanged: (v) => setState(() => _tab = v),
                ),
                const SizedBox(height: 14),
                if (hotelsAsync.isLoading || foodAsync.isLoading)
                  const _ServicesSkeleton()
                else if (hotelsAsync.hasError || foodAsync.hasError)
                  _ErrorState(
                    title: 'Hệ thống đang bận',
                    description: 'Chúng tôi đang xử lý, vui lòng thử lại sau ít phút.',
                    onRetry: () {
                      ref.invalidate(hotelsProvider);
                      ref.invalidate(foodProvider);
                    },
                  )
                else if (filtered.isEmpty)
                  const _EmptyState(
                    title: 'Chưa có dữ liệu',
                    description: 'Dữ liệu sẽ được cập nhật sớm.',
                  )
                else
                  ...filtered.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ServiceMockCard(item: s),
                      )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.hint, required this.onChanged});
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: AppColors.card.withValues(alpha: 0.55),
        hintStyle: const TextStyle(color: AppColors.mutedForeground),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.base)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.base),
          borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.55)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.base),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.active, required this.onChanged});
  final String active;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget chip(String value, String label) {
      final isActive = value == active;
      return InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(AppRadii.xl),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary.withValues(alpha: 0.18) : AppColors.card.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(AppRadii.xl),
            border: Border.all(
              color: isActive ? AppColors.primary.withValues(alpha: 0.55) : AppColors.border.withValues(alpha: 0.55),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isActive ? AppColors.primary : AppColors.mutedForeground,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip('ALL', 'Tất cả'),
          const SizedBox(width: 10),
          chip('FOOD', 'Ẩm thực'),
          const SizedBox(width: 10),
          chip('ACCOMMODATION', 'Lưu trú'),
        ],
      ),
    );
  }
}

class _ServiceMockCard extends StatelessWidget {
  const _ServiceMockCard({required this.item});
  final ServiceItem item;

  double _rating() {
    final seed = item.id.hashCode;
    final r = 4.4 + (seed.abs() % 5) * 0.1; // 4.4 .. 4.8
    return double.parse(r.toStringAsFixed(1));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = item.type == 'ACCOMMODATION' ? AppColors.secondary : cs.primary;
    final category = item.type == 'ACCOMMODATION' ? 'Lưu trú' : 'Ẩm thực';
    final unit = item.type == 'ACCOMMODATION' ? '/đêm' : '/người';
    final tag1 = item.type == 'ACCOMMODATION' ? 'Gần biển' : 'Gần biển';
    final tag2 = item.type == 'ACCOMMODATION' ? 'Giá tốt' : 'Giá rẻ';
    final rating = _rating();

    void open() {
      // Mock detail per screenshot: use booking detail-like screen for FOOD too.
      context.push('/services/detail/${item.id}', extra: item);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: open,
        borderRadius: BorderRadius.circular(AppRadii.x2l),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.x2l),
            gradient: LinearGradient(
              colors: [AppColors.card.withValues(alpha: 0.70), AppColors.surface.withValues(alpha: 0.60)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(AppRadii.xl),
                      border: Border.all(color: accent.withValues(alpha: 0.28)),
                    ),
                    child: Text(category, style: TextStyle(color: accent, fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: AppColors.primary, size: 18),
                      const SizedBox(width: 4),
                      Text('$rating', style: const TextStyle(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(item.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 6),
              Text(
                item.description.isEmpty ? 'Dịch vụ tại Biển Vô Cực.' : item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.mutedForeground, height: 1.25),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(formatVnd(item.price), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(width: 6),
                  Text('VND$unit', style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
                  const Spacer(),
                  _MiniTag(text: tag1),
                  const SizedBox(width: 8),
                  _MiniTag(text: tag2),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.muted.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground, fontWeight: FontWeight.w700)),
    );
  }
}

class _ServicesSkeleton extends StatelessWidget {
  const _ServicesSkeleton();
  @override
  Widget build(BuildContext context) {
    Widget box(double h) => Container(
          height: h,
          decoration: BoxDecoration(
            color: AppColors.muted.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(AppRadii.x2l),
          ),
        );
    return Column(
      children: [
        box(110),
        const SizedBox(height: 12),
        box(110),
        const SizedBox(height: 12),
        box(110),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.title, required this.description, required this.onRetry});
  final String title;
  final String description;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 72,
              width: 72,
              decoration: BoxDecoration(color: AppColors.destructive.withValues(alpha: 0.18), shape: BoxShape.circle),
              child: const Icon(Icons.error_rounded, color: AppColors.destructive, size: 34),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 8),
            Text(description, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.mutedForeground, height: 1.3)),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.description});
  final String title;
  final String description;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 72,
              width: 72,
              decoration: BoxDecoration(color: AppColors.muted.withValues(alpha: 0.45), shape: BoxShape.circle),
              child: const Icon(Icons.inbox_rounded, color: AppColors.mutedForeground, size: 34),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 8),
            Text(description, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.mutedForeground, height: 1.3)),
          ],
        ),
      ),
    );
  }
}
