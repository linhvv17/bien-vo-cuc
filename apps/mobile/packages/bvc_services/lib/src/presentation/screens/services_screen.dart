import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bvc_network/bvc_network.dart';
import 'package:bvc_ui/bvc_ui.dart';
import '../providers/services_providers.dart';
import '../widgets/combo_deal_card.dart';
import '../widgets/service_card.dart';

class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baseUrl = ref.watch(apiBaseUrlProvider);
    final hotelsAsync = ref.watch(hotelsProvider);
    final foodAsync = ref.watch(foodProvider);
    final combosAsync = ref.watch(comboDealsProvider);

    return DefaultTabController(
      length: 3,
      child: Stack(
        children: [
          const Positioned.fill(child: WavesBackground()),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: const Text('Ăn & Ở'),
              backgroundColor: Colors.transparent,
              bottom: const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.hotel_rounded), text: 'Khách sạn'),
                  Tab(icon: Icon(Icons.restaurant_rounded), text: 'Ăn uống'),
                  Tab(icon: Icon(Icons.auto_awesome_mosaic_rounded), text: 'Combo'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                // Hotels
                RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(hotelsProvider);
                    await ref.read(hotelsProvider.future);
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      const _CatalogHeader(
                        title: 'Khách sạn gần biển',
                        subtitle: 'Ưu tiên: gần điểm gửi xe, tiện xuất phát sớm, có chỗ tắm rửa.',
                        icon: Icons.hotel_rounded,
                      ),
                      const SizedBox(height: 12),
                      hotelsAsync.when(
                        loading: () => const _LoadingBlock(),
                        error: (e, _) => _InlineError(message: '$e', baseUrl: baseUrl, onRetry: () => ref.invalidate(hotelsProvider)),
                        data: (items) => items.isEmpty
                            ? const _EmptyHint(text: 'Chưa có dữ liệu khách sạn. (Sẽ nhập từ Admin)')
                            : Column(
                                children: items
                                    .map((e) => Padding(
                                          padding: const EdgeInsets.only(bottom: 10),
                                          child: ServiceCard(item: e),
                                        ))
                                    .toList(),
                              ),
                      ),
                    ],
                  ),
                ),

                // Food
                RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(foodProvider);
                    await ref.read(foodProvider.future);
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      const _CatalogHeader(
                        title: 'Ăn uống',
                        subtitle: 'Tip: ưu tiên món nóng, gọn, tránh đồ dễ bẩn khi xuống bãi.',
                        icon: Icons.restaurant_rounded,
                      ),
                      const SizedBox(height: 12),
                      foodAsync.when(
                        loading: () => const _LoadingBlock(),
                        error: (e, _) => _InlineError(message: '$e', baseUrl: baseUrl, onRetry: () => ref.invalidate(foodProvider)),
                        data: (items) => items.isEmpty
                            ? const _EmptyHint(text: 'Chưa có dữ liệu ăn uống. (Sẽ nhập từ Admin)')
                            : Column(
                                children: items
                                    .map((e) => Padding(
                                          padding: const EdgeInsets.only(bottom: 10),
                                          child: ServiceCard(item: e),
                                        ))
                                    .toList(),
                              ),
                      ),
                    ],
                  ),
                ),

                // Combo
                RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(comboDealsProvider);
                    await ref.read(comboDealsProvider.future);
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      const _CatalogHeader(
                        title: 'Combo gợi ý',
                        subtitle: '1 khách sạn + 1 món ăn để tối ưu đi săn bình minh.',
                        icon: Icons.auto_awesome_mosaic_rounded,
                      ),
                      const SizedBox(height: 12),
                      combosAsync.when(
                        loading: () => const _LoadingBlock(),
                        error: (e, _) => _InlineError(message: '$e', baseUrl: baseUrl, onRetry: () => ref.invalidate(comboDealsProvider)),
                        data: (items) => items.isEmpty
                            ? const _EmptyHint(text: 'Chưa có combo để gợi ý.')
                            : Column(
                                children: items
                                    .map((c) => Padding(
                                          padding: const EdgeInsets.only(bottom: 10),
                                          child: ComboDealCard(combo: c),
                                        ))
                                    .toList(),
                              ),
                      ),
                    ],
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

class _CatalogHeader extends StatelessWidget {
  const _CatalogHeader({required this.title, required this.subtitle, required this.icon});

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            scheme.primary.withValues(alpha: 0.22),
            const Color(0xFF1A2D3E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
              ),
              child: Icon(icon, color: scheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Color(0xFFA0B4C8), height: 1.25)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: LinearProgressIndicator(),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.baseUrl, required this.onRetry});
  final String message;
  final String baseUrl;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.25)),
        color: Colors.redAccent.withValues(alpha: 0.10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Lỗi tải dữ liệu', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(message, style: const TextStyle(color: Color(0xFFA0B4C8))),
          const SizedBox(height: 10),
          Text('API: $baseUrl', style: const TextStyle(color: Color(0xFFA0B4C8), fontSize: 12)),
          const SizedBox(height: 10),
          FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Thử lại')),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        color: Colors.white.withValues(alpha: 0.04),
      ),
      child: Text(text, style: const TextStyle(color: Color(0xFFA0B4C8))),
    );
  }
}
