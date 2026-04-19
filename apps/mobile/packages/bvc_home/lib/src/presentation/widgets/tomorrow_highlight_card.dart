import 'dart:math' as math;

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
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
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
                      Tooltip(
                        message:
                            'Điểm gợi ý từ triều và thời tiết trong ngày (thang 0–100). Càng cao càng thuận để ra bãi, canh bình minh.',
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: accent.withValues(alpha: 0.35)),
                          ),
                          child: Text(
                            'Điểm ${go.score}/100',
                            style: TextStyle(color: accent, fontWeight: FontWeight.w800, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (weather != null) ...[
              _RowInfo(
                icon: Icons.thermostat_rounded,
                label: 'Nhiệt độ',
                value:
                    '${weather!.tempMin?.toStringAsFixed(0) ?? '—'}°–${weather!.tempMax?.toStringAsFixed(0) ?? '—'}°',
              ),
              const SizedBox(height: 5),
              _RowInfo(
                icon: Icons.air_rounded,
                label: 'Gió tối đa',
                value: '${weather!.windSpeedMax?.toStringAsFixed(0) ?? '—'} km/h',
              ),
              const SizedBox(height: 5),
              _RowInfo(
                icon: Icons.water_drop_outlined,
                label: 'Mưa',
                value: '${weather!.precipitationSum?.toStringAsFixed(1) ?? '0'} mm',
              ),
            ] else
              const Text('Chưa có thời tiết cho ngày này.', style: TextStyle(color: Color(0xFFA0B4C8))),
            if (tide != null) ...[
              const SizedBox(height: 8),
              const Divider(height: 1, color: Color(0x22FFFFFF)),
              const SizedBox(height: 8),
              _CompactTideAndHints(tide: tide!, reasons: go.reasons),
            ] else ...[
              const SizedBox(height: 8),
              _ReasonChipsOnly(reasons: go.reasons),
            ],
            const SizedBox(height: 10),
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

/// Triều gọn + lưu ý + chip lý do trong **một** khối để không chiếm cả màn.
class _CompactTideAndHints extends StatelessWidget {
  const _CompactTideAndHints({required this.tide, required this.reasons});

  final TideSchedule tide;
  final List<String> reasons;

  static const _muted = Color(0xFFA0B4C8);
  static const _blue = Color(0xFF4A90C4);

  static String _hm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  static String _fmtM(double x) => x.toStringAsFixed(2).replaceFirst('.', ',');

  @override
  Widget build(BuildContext context) {
    final lows = <({DateTime time, double h})>[
      (time: tide.lowTime1, h: tide.lowHeight1),
      if (tide.lowTime2 != null && tide.lowHeight2 != null) (time: tide.lowTime2!, h: tide.lowHeight2!),
    ]..sort((a, b) => a.time.compareTo(b.time));

    final hs = lows.map((e) => e.h).toList();
    final minH = hs.reduce(math.min);
    final maxH = hs.reduce(math.max);
    final hasTwo = lows.length > 1;

    final morningLows = lows.where((e) {
      final hour = e.time.hour;
      return hour >= 4 && hour < 13;
    }).toList();
    const lead = Duration(hours: 2, minutes: 30);

    String? arrivalHm;
    String arrivalShort;
    if (morningLows.isNotEmpty) {
      final ref = morningLows.first;
      final arrive = ref.time.subtract(lead);
      arrivalHm = _hm(arrive);
      arrivalShort =
          'Canh ~2h30 trước triều thấp sáng (${_hm(ref.time)}). Mực so với mốc trung bình — không phải độ sâu tại bãi.';
    } else {
      final ref = lows.first;
      arrivalShort =
          'Không có triều thấp buổi sáng trong dữ liệu; đợt sớm nhất ${_hm(ref.time)}. Canh bình minh: đối chiếu thêm lịch triều (Hòn Dáu).';
    }

    final tideLines = <Widget>[
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.waves_rounded, size: 17, color: _blue),
          const SizedBox(width: 6),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: const TextStyle(color: _muted, fontSize: 12, height: 1.3),
                children: [
                  const TextSpan(text: 'Triều thấp: ', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFCFD8E6))),
                  TextSpan(
                    text: '${_fmtM(lows.first.h)} m · ${_hm(lows.first.time)}',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  if (hasTwo) ...[
                    const TextSpan(text: '  ·  ', style: TextStyle(color: _muted)),
                    TextSpan(
                      text: '${_fmtM(lows[1].h)} m · ${_hm(lows[1].time)}',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white70),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Tooltip(
            message:
                'Độ cao mực so với mốc trung bình (có thể âm). Không phải độ sâu tại chỗ trên bãi.',
            child: Icon(Icons.info_outline_rounded, size: 18, color: Colors.white.withValues(alpha: 0.45)),
          ),
        ],
      ),
    ];
    if (hasTwo && (minH - maxH).abs() > 0.001) {
      tideLines.add(
        Padding(
          padding: const EdgeInsets.only(top: 4, left: 23),
          child: Text(
            'Khoảng mực tại các điểm thấp: ${_fmtM(minH)} – ${_fmtM(maxH)} m.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 10.5, height: 1.25),
          ),
        ),
      );
    }

    final chipReasons = reasons.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...tideLines,
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline_rounded, size: 15, color: Colors.amber.shade200),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (morningLows.isNotEmpty && arrivalHm != null)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                'Nên đến khoảng ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11.5,
                                  color: Colors.amber.shade100,
                                ),
                              ),
                              Text(
                                arrivalHm,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            'Lưu ý',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 11.5,
                              color: Colors.amber.shade100,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          arrivalShort,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontSize: 11, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (chipReasons.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: chipReasons.map((r) {
                    return Chip(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      label: Text(
                        r,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10.5, height: 1.2),
                      ),
                      backgroundColor: Colors.black.withValues(alpha: 0.2),
                      side: BorderSide.none,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ReasonChipsOnly extends StatelessWidget {
  const _ReasonChipsOnly({required this.reasons});

  final List<String> reasons;

  @override
  Widget build(BuildContext context) {
    final chipReasons = reasons.take(3).toList();
    if (chipReasons.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: chipReasons.map((r) {
        return Chip(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          label: Text(
            r,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10.5, height: 1.2),
          ),
          backgroundColor: Colors.black.withValues(alpha: 0.18),
          side: BorderSide.none,
        );
      }).toList(),
    );
  }
}
