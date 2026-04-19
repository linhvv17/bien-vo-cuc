import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'package:bvc_common/bvc_common.dart';
import 'package:bvc_network/bvc_network.dart';
import 'package:bvc_ui/bvc_ui.dart';
import '../../domain/entities/tide_schedule.dart';
import '../../domain/entities/weather_day.dart';
import '../providers/home_providers.dart';
import '../widgets/seven_days_section.dart';
import '../widgets/tomorrow_highlight_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(homeDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Biển Vô Cực'),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Vị trí',
          onPressed: () {},
          icon: const Icon(Icons.place_rounded),
        ),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: () => ref.invalidate(homeDataProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: WavesBackground()),
          async.when(
            loading: () => const _HomeSkeleton(),
            error: (e, _) => _FullErrorState(
              message: formatDioError(e),
              onRetry: () => ref.invalidate(homeDataProvider),
            ),
            data: (data) => RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(homeDataProvider);
                await ref.read(homeDataProvider.future);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  Builder(
                    builder: (context) {
                      final todayYmd = ymdVietnamToday();

                      TideSchedule? tideToday = data.todayTide;
                      if (tideToday == null) {
                        for (final t in data.tides7) {
                          if (ymd(t.date) == todayYmd) {
                            tideToday = t;
                            break;
                          }
                        }
                      }

                      WeatherDay? weatherToday;
                      for (final w in data.weather7) {
                        if (w.date == todayYmd) {
                          weatherToday = w;
                          break;
                        }
                      }

                      final showWeatherBanner = data.weather7.isEmpty;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Ưu tiên thẻ "Hôm nay" để người dùng thấy ngay giá trị app (triều + gợi ý Go).
                          if (tideToday != null || weatherToday != null) ...[
                            TomorrowHighlightCard(weather: weatherToday, tide: tideToday),
                            const SizedBox(height: 14),
                          ] else ...[
                            const _InlineHint(text: 'Chưa có dữ liệu hôm nay.'),
                            const SizedBox(height: 14),
                          ],
                          if (showWeatherBanner) ...[
                            const _WeatherPartialBanner(),
                            const SizedBox(height: 14),
                          ],
                          const _SectionLabel(text: 'DỊCH VỤ NHANH'),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _QuickSquare(
                                  icon: Icons.restaurant_rounded,
                                  label: 'Ăn & Ở',
                                  onTap: () => ref.read(shellTabIndexProvider.notifier).setTab(1),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _QuickSquare(
                                  icon: Icons.directions_car_rounded,
                                  label: 'Xe xích',
                                  onTap: () {
                                    ref.read(shellTabIndexProvider.notifier).setTab(2);
                                    Modular.to.pushNamed('/book/vehicle');
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _QuickSquare(
                                  icon: Icons.photo_camera_rounded,
                                  label: 'Chụp ảnh',
                                  onTap: () {
                                    ref.read(shellTabIndexProvider.notifier).setTab(2);
                                    Modular.to.pushNamed('/book/photo');
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          const _SectionLabel(text: '7 NGÀY TỚI'),
                          const SizedBox(height: 10),
                          SevenDaysSection(
                            tides: data.tides7,
                            weather: data.weather7,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
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

class _QuickSquare extends StatelessWidget {
  const _QuickSquare({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        child: Ink(
          height: 76,
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(AppRadii.xl),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: cs.primary),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeatherPartialBanner extends StatelessWidget {
  const _WeatherPartialBanner();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.destructive.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.destructive.withValues(alpha: 0.35)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_rounded, color: AppColors.destructive),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Thời tiết tạm không có', style: TextStyle(fontWeight: FontWeight.w900)),
                SizedBox(height: 2),
                Text(
                  'Dữ liệu thời tiết đang được cập nhật. Thông tin triều vẫn chính xác.',
                  style: TextStyle(color: AppColors.mutedForeground, height: 1.25),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineHint extends StatelessWidget {
  const _InlineHint({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
      ),
      child: Text(text, style: const TextStyle(color: AppColors.mutedForeground)),
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();
  @override
  Widget build(BuildContext context) {
    Widget box({double? h, double? w, BorderRadius? r}) => Container(
          height: h,
          width: w,
          decoration: BoxDecoration(
            color: AppColors.muted.withValues(alpha: 0.55),
            borderRadius: r ?? BorderRadius.circular(AppRadii.xl),
          ),
        );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        box(h: 200, r: BorderRadius.circular(AppRadii.x2l)),
        const SizedBox(height: 16),
        box(h: 18, w: 140, r: BorderRadius.circular(8)),
        const SizedBox(height: 10),
        Row(children: [Expanded(child: box(h: 76)), const SizedBox(width: 10), Expanded(child: box(h: 76)), const SizedBox(width: 10), Expanded(child: box(h: 76))]),
        const SizedBox(height: 18),
        box(h: 18, w: 120, r: BorderRadius.circular(8)),
        const SizedBox(height: 10),
        Row(children: List.generate(5, (i) => Expanded(child: Padding(padding: EdgeInsets.only(right: i == 4 ? 0 : 10), child: box(h: 70))))),
        const SizedBox(height: 18),
        const Center(child: Text('Đang tải dữ liệu...', style: TextStyle(color: AppColors.mutedForeground))),
      ],
    );
  }
}

class _FullErrorState extends StatelessWidget {
  const _FullErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isOffline = message.toLowerCase().contains('không kết nối') || message.toLowerCase().contains('mạng');
    final title = isOffline ? 'Mất kết nối mạng' : 'Hệ thống đang bận';
    final desc = isOffline
        ? 'Vui lòng kiểm tra kết nối internet và thử lại.'
        : 'Chúng tôi đang xử lý, vui lòng thử lại sau ít phút.';
    final icon = isOffline ? Icons.wifi_off_rounded : Icons.error_rounded;
    final iconBg = isOffline ? AppColors.destructive.withValues(alpha: 0.18) : AppColors.destructive.withValues(alpha: 0.18);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 72,
              width: 72,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.destructive, size: 34),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 8),
            Text(desc, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.mutedForeground, height: 1.3)),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}
