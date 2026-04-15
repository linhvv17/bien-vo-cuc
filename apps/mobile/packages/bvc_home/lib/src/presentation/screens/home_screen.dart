import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    final baseUrl = ref.watch(apiBaseUrlProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Biển Vô Cực'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
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
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorPane(
              message: formatDioError(e),
              baseUrl: baseUrl,
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
                  _ApiHintCard(baseUrl: baseUrl),
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) {
                      final todayYmd = ymdVietnamToday();
                      final tomorrowYmd = ymdAddCalendarDays(todayYmd, 1);

                      TideSchedule? tideToday = data.todayTide;
                      if (tideToday == null) {
                        for (final t in data.tides7) {
                          if (ymd(t.date) == todayYmd) {
                            tideToday = t;
                            break;
                          }
                        }
                      }

                      TideSchedule? tideTomorrow;
                      for (final t in data.tides7) {
                        if (ymd(t.date) == tomorrowYmd) {
                          tideTomorrow = t;
                          break;
                        }
                      }

                      WeatherDay? weatherTomorrow;
                      for (final w in data.weather7) {
                        if (w.date == tomorrowYmd) {
                          weatherTomorrow = w;
                          break;
                        }
                      }

                      WeatherDay? weatherToday;
                      for (final w in data.weather7) {
                        if (w.date == todayYmd) {
                          weatherToday = w;
                          break;
                        }
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SectionTitle(icon: Icons.star_rounded, label: 'Hôm nay (ưu tiên)'),
                          const SizedBox(height: 8),
                          if (data.weather7.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: _EmptyHint(
                                text:
                                    'Thời tiết đang tạm không có dữ liệu (có thể do upstream giới hạn). Bạn vẫn xem được lịch triều; thử tải lại sau.',
                              ),
                            ),
                          if (tideToday == null && weatherToday == null)
                            const _EmptyHint(text: 'Chưa có dữ liệu hôm nay. Kiểm tra backend / sync triều.')
                          else
                            TomorrowHighlightCard(
                              weather: weatherToday,
                              tide: tideToday,
                            ),
                          const SizedBox(height: 8),
                          if (tideToday == null && weatherToday == null)
                            const SizedBox.shrink()
                          else
                            Text(
                              'Go score = “đi săn bình minh”: triều + mưa + gió + dông (MVP).',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12),
                            ),
                          const SizedBox(height: 12),
                          _SectionTitle(icon: Icons.wb_twilight_rounded, label: 'Ngày mai (chuẩn bị sớm)'),
                          const SizedBox(height: 8),
                          if (tideTomorrow == null && weatherTomorrow == null)
                            const _EmptyHint(text: 'Chưa có dữ liệu ngày mai.')
                          else
                            TomorrowHighlightCard(
                              weather: weatherTomorrow,
                              tide: tideTomorrow,
                            ),
                          const SizedBox(height: 16),
                          _SectionTitle(icon: Icons.calendar_view_week_rounded, label: '7 ngày (từ hôm nay)'),
                          const SizedBox(height: 8),
                          SevenDaysSection(
                            tides: data.tides7,
                            weather: data.weather7,
                          ),
                          const SizedBox(height: 16),
                          _SectionTitle(icon: Icons.bolt_rounded, label: 'Đặt nhanh'),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: _QuickCard(
                              title: 'Ăn & Ở',
                              subtitle: 'Khách sạn • món ăn • combo',
                              icon: Icons.storefront_rounded,
                              colors: const [Color(0x334A90C4), Color(0x221A2D3E)],
                              onTap: () => context.go('/services'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _QuickCard(
                                  title: 'Xe xích',
                                  subtitle: 'Không lội bùn 1–3km',
                                  icon: Icons.directions_car_rounded,
                                  colors: const [Color(0x334A90C4), Color(0x221A2D3E)],
                                  onTap: () => context.go('/book/vehicle'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _QuickCard(
                                  title: 'Chụp ảnh + Flycam',
                                  subtitle: 'Ekip hỗ trợ pose',
                                  icon: Icons.photo_camera_rounded,
                                  colors: const [Color(0x33E8834A), Color(0x221A2D3E)],
                                  onTap: () => context.go('/book/photo'),
                                ),
                              ),
                            ],
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _ApiHintCard extends StatelessWidget {
  const _ApiHintCard({required this.baseUrl});

  final String baseUrl;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'API: $baseUrl',
          style: const TextStyle(color: Color(0xFFA0B4C8), fontSize: 12),
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(text, style: const TextStyle(color: Color(0xFFA0B4C8))),
      ),
    );
  }
}

class _ErrorPane extends StatelessWidget {
  const _ErrorPane({required this.message, required this.baseUrl, required this.onRetry});

  final String message;
  final String baseUrl;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('API: $baseUrl', style: const TextStyle(color: Color(0xFFA0B4C8), fontSize: 12)),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
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
            gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: Colors.white.withValues(alpha: 0.92)),
                const SizedBox(height: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Color(0xFFA0B4C8), fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
