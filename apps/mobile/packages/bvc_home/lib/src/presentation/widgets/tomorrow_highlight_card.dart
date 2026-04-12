import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bvc_common/bvc_common.dart';
import 'package:bvc_network/bvc_network.dart';
import '../../domain/entities/tide_schedule.dart';
import '../../domain/entities/weather_day.dart';
import '../../domain/go_score.dart';

class TomorrowHighlightCard extends StatelessWidget {
  const TomorrowHighlightCard({
    super.key,
    required this.weather,
    required this.tide,
  });

  final WeatherDay? weather;
  final TideSchedule? tide;

  /// So khớp với [weather.date] / triều — không hard-code "Ngày mai".
  static String headlineFor({WeatherDay? weather, TideSchedule? tide}) {
    final today = ymdVietnamToday();
    final ymdData = weather?.date ??
        (tide != null ? ymd(tide.date) : null);
    if (ymdData == null) return 'Gợi ý ra biển';
    if (ymdData == today) return 'Hôm nay';
    final next = ymdAddCalendarDays(today, 1);
    if (ymdData == next) return 'Ngày mai';
    final p = parseYmd(ymdData);
    return p != null ? 'Ngày ${dmy(p)}' : ymdData;
  }

  String _hm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Future<void> _openMaps(BuildContext context) async {
    // Không dùng canLaunchUrl: trên Android 11+ thường false nếu thiếu <queries> → bấm không ra gì.
    final uri = Uri(
      scheme: 'https',
      host: 'www.google.com',
      path: '/maps/search/',
      queryParameters: <String, String>{
        'api': '1',
        'query': '${kBeachLat.toString()},${kBeachLng.toString()}',
      },
    );
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không mở được bản đồ. Kiểm tra app trình duyệt / Maps.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi mở bản đồ: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final go = computeGoScore(
      weather: weather,
      tide: tide,
    );
    final accent = go.accent();
    final headline = headlineFor(weather: weather, tide: tide);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.22),
            const Color(0xFF1A2D3E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
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
                        headline,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ưu tiên xuất phát sớm, bám điểm triều thấp',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: accent.withValues(alpha: 0.45)),
                        ),
                        child: Text(
                          go.verdict,
                          style: TextStyle(color: accent, fontWeight: FontWeight.w900, fontSize: 12),
                        ),
                      ),
                      Chip(
                        label: Text('Go ${go.score}'),
                        backgroundColor: Colors.black.withValues(alpha: 0.20),
                        side: BorderSide(color: accent.withValues(alpha: 0.35)),
                        labelStyle: TextStyle(color: accent, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (weather != null) ...[
              _RowInfo(
                icon: Icons.thermostat_rounded,
                label: 'Nhiệt độ',
                value:
                    '${weather!.tempMin?.toStringAsFixed(0) ?? '—'}°–${weather!.tempMax?.toStringAsFixed(0) ?? '—'}°',
              ),
              const SizedBox(height: 6),
              _RowInfo(
                icon: Icons.air_rounded,
                label: 'Gió tối đa',
                value: '${weather!.windSpeedMax?.toStringAsFixed(0) ?? '—'} km/h',
              ),
              const SizedBox(height: 6),
              _RowInfo(
                icon: Icons.water_drop_outlined,
                label: 'Mưa',
                value: '${weather!.precipitationSum?.toStringAsFixed(1) ?? '0'} mm',
              ),
            ] else
              const Text('Chưa có thời tiết cho ngày này.', style: TextStyle(color: Color(0xFFA0B4C8))),
            if (tide != null) ...[
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0x22FFFFFF)),
              const SizedBox(height: 10),
              _RowInfo(
                icon: Icons.waves_rounded,
                label: 'Triều thấp',
                value: '${_hm(tide!.lowTime1)} • ${tide!.lowHeight1.toStringAsFixed(2)} m',
              ),
              if (tide!.lowTime2 != null) ...[
                const SizedBox(height: 6),
                _RowInfo(
                  icon: Icons.waves_rounded,
                  label: 'Triều thấp 2',
                  value: '${_hm(tide!.lowTime2!)} • ${tide!.lowHeight2?.toStringAsFixed(2) ?? '—'} m',
                ),
              ],
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: go.reasons.take(4).map((r) {
                return Chip(
                  label: Text(r, style: const TextStyle(fontSize: 11)),
                  backgroundColor: Colors.black.withValues(alpha: 0.18),
                  side: BorderSide.none,
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () => _openMaps(context),
                icon: const Icon(Icons.map_rounded),
                label: const Text('Mở Google Maps (bãi)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RowInfo extends StatelessWidget {
  const _RowInfo({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF4A90C4)),
        const SizedBox(width: 8),
        SizedBox(width: 88, child: Text(label, style: const TextStyle(color: Color(0xFFA0B4C8), fontSize: 12))),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700))),
      ],
    );
  }
}
