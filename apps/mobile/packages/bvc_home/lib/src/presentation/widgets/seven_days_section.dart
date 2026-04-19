import 'package:flutter/material.dart';

import 'package:bvc_common/bvc_common.dart';
import '../../domain/entities/tide_schedule.dart';
import '../../domain/entities/weather_day.dart';
import '../../domain/go_score.dart';

const Color _kMuted = Color(0xFFA0B4C8);
const Color _kGold = Color(0xFFF2C94C);
const Color _kBlue = Color(0xFF4A90C4);

/// Kích thước cố định cho mỗi ô trong thanh 7 ngày (tránh lệch do border/badge).
const double _kDayChipWidth = 104;
const double _kDayChipHeight = 166;

/// Lịch 7 ngày: triều + thời tiết, điểm Go score, làm nổi bật ngày đẹp để gợi ý lên kế hoạch.
class SevenDaysSection extends StatelessWidget {
  const SevenDaysSection({super.key, required this.tides, required this.weather});

  final List<TideSchedule> tides;
  final List<WeatherDay> weather;

  static String _weekdayShort(DateTime d) {
    const names = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return names[d.weekday - 1];
  }

  static String _ddMm(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (tides.isEmpty && weather.isEmpty) {
      return const _EmptySeven();
    }

    // Luôn 7 ngày: bắt đầu từ hôm nay (VN), gộp triều/thời tiết theo từng ngày.
    final anchor = ymdVietnamToday();
    final rows = <_DayRow>[];
    for (var i = 0; i < 7; i++) {
      final dayYmd = ymdAddCalendarDays(anchor, i);
      final day = parseYmd(dayYmd)!;
      TideSchedule? tide;
      for (final t in tides) {
        if (ymd(t.date) == dayYmd) {
          tide = t;
          break;
        }
      }
      WeatherDay? w;
      for (final x in weather) {
        if (x.date == dayYmd) {
          w = x;
          break;
        }
      }
      rows.add(_DayRow(day: day, tide: tide, weather: w));
    }

    final maxScore = rows.map((e) => e.go.score).reduce((a, b) => a > b ? a : b);
    final firstMaxIndex = rows.indexWhere((e) => e.go.score == maxScore);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Điểm trên mỗi thẻ là gợi ý nhanh từ triều và thời tiết trong ngày (thang 0–100). Điểm càng cao thì càng thuận để ra bãi và canh bình minh.',
              style: TextStyle(color: _kMuted, fontSize: 12.5, height: 1.45),
            ),
            SizedBox(height: 8),
            Text(
              'Màu và dòng chữ trên thẻ trùng với từng mức ở bảng chú thích ngay bên dưới.',
              style: TextStyle(color: _kMuted, fontSize: 12, height: 1.4),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 180,
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              clipBehavior: Clip.none,
              itemCount: rows.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final r = rows[i];
                final isWeekPeak = i == firstMaxIndex && r.go.score == maxScore && maxScore >= 52;
                return SizedBox(
                  width: _kDayChipWidth,
                  height: _kDayChipHeight,
                  child: _DayChip(
                    row: r,
                    isWeekPeak: isWeekPeak,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        const _LegendRow(),
        const SizedBox(height: 14),
        const Text('Chi tiết từng ngày', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
        const SizedBox(height: 10),
        ...rows.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DayDetailCard(row: r, maxInWeek: maxScore),
            )),
      ],
    );
  }
}

class _DayRow {
  _DayRow({required this.day, required this.tide, required this.weather})
      : go = computeGoScore(weather: weather, tide: tide);

  final DateTime day;
  final TideSchedule? tide;
  final WeatherDay? weather;
  final GoScore go;
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.row,
    required this.isWeekPeak,
  });

  final _DayRow row;
  final bool isWeekPeak;

  @override
  Widget build(BuildContext context) {
    final d = row.day;
    final accent = row.go.accent();
    final good = row.go.score >= 70;
    final ok = row.go.score >= 45 && row.go.score < 70;

    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: good
                  ? [accent.withValues(alpha: 0.35), const Color(0xFF1A2D3E)]
                  : ok
                      ? [accent.withValues(alpha: 0.22), const Color(0xFF1A2D3E)]
                      : [Colors.white.withValues(alpha: 0.06), const Color(0xFF1A2D3E)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border.all(
              color: isWeekPeak
                  ? _kGold.withValues(alpha: 0.85)
                  : good
                      ? accent.withValues(alpha: 0.65)
                      : Colors.white.withValues(alpha: 0.12),
              width: isWeekPeak ? 2.0 : 1,
            ),
            boxShadow: isWeekPeak
                ? [
                    BoxShadow(
                      color: _kGold.withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : good
                    ? [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  SevenDaysSection._weekdayShort(d),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
                Text(
                  SevenDaysSection._ddMm(d),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _kMuted, fontSize: 11),
                ),
                const SizedBox(height: 8),
                Text(
                  '${row.go.score}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                    height: 1,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  row.go.verdict,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: accent.withValues(alpha: 0.95)),
                ),
                const Spacer(),
                if (row.tide?.isGolden == true)
                  Align(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: _kGold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Triều vàng', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: _kGold)),
                    ),
                  )
                else
                  const SizedBox(height: 18),
              ],
            ),
          ),
        ),
        if (isWeekPeak && row.go.score >= 50)
          Positioned(
            top: -6,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: _kGold,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 6)],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 12, color: Color(0xFF0D1B2A)),
                  SizedBox(width: 3),
                  Text('Tuần này', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF0D1B2A))),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _LegendDot(color: const Color(0xFF2ECC71), label: 'Từ 70 · Nên đi'),
        _LegendDot(color: const Color(0xFFF2C94C), label: '45–69 · Cân nhắc'),
        _LegendDot(color: const Color(0xFFE74C3C), label: 'Dưới 45 · Không nên'),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_rounded, size: 14, color: _kGold.withValues(alpha: 0.9)),
            const SizedBox(width: 4),
            const Text('Viền vàng · Điểm cao nhất 7 ngày', style: TextStyle(color: _kMuted, fontSize: 11)),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: _kMuted, fontSize: 11)),
      ],
    );
  }
}

class _DayDetailCard extends StatelessWidget {
  const _DayDetailCard({required this.row, required this.maxInWeek});

  final _DayRow row;
  final int maxInWeek;

  String _hm(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final d = row.day;
    final y = ymd(d);
    final w = row.weather;
    final accent = row.go.accent();
    final isTop = row.go.score == maxInWeek;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(
          color: isTop ? _kGold.withValues(alpha: 0.45) : Colors.white.withValues(alpha: 0.10),
          width: isTop ? 1.4 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${row.go.score} · ${row.go.verdict}',
                    style: TextStyle(fontWeight: FontWeight.w900, color: accent, fontSize: 12),
                  ),
                ),
                if (isTop) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _kGold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Điểm cao nhất tuần', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _kGold)),
                  ),
                ],
                const Spacer(),
                Text(
                  '${SevenDaysSection._weekdayShort(d)} · ${SevenDaysSection._ddMm(d)}',
                  style: const TextStyle(color: _kMuted, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(y, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12)),
            const SizedBox(height: 10),
            if (w != null) ...[
              _DetailLine(icon: Icons.thermostat_rounded, label: 'Nhiệt độ', value: '${w.tempMin?.toStringAsFixed(0) ?? '—'}° – ${w.tempMax?.toStringAsFixed(0) ?? '—'}°'),
              _DetailLine(icon: Icons.water_drop_outlined, label: 'Mưa', value: '${w.precipitationSum?.toStringAsFixed(1) ?? '0'} mm'),
              _DetailLine(icon: Icons.air_rounded, label: 'Gió tối đa', value: '${w.windSpeedMax?.toStringAsFixed(0) ?? '—'} km/h'),
            ] else
              const Text('Chưa có dữ liệu thời tiết chi tiết.', style: TextStyle(color: _kMuted, fontSize: 12)),
            const SizedBox(height: 8),
            if (row.tide != null)
              _DetailLine(
                icon: Icons.waves_rounded,
                label: 'Triều thấp',
                value:
                    '${_hm(row.tide!.lowTime1)} · ${row.tide!.lowHeight1.toStringAsFixed(2)} m${row.tide!.lowTime2 != null ? '  ·  ${_hm(row.tide!.lowTime2!)}' : ''}',
              )
            else
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text('Chưa có lịch triều cho ngày này.', style: TextStyle(color: _kMuted, fontSize: 12)),
              ),
            if (row.tide?.isGolden == true)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.star_rounded, size: 18, color: _kGold.withValues(alpha: 0.95)),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Khung triều “vàng” trong ngày — thường thuận cho bình minh.',
                        style: TextStyle(color: _kGold, fontSize: 12, height: 1.3, fontWeight: FontWeight.w600),
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

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: _kBlue.withValues(alpha: 0.85)),
          const SizedBox(width: 8),
          SizedBox(
            width: 88,
            child: Text(label, style: const TextStyle(color: _kMuted, fontSize: 12)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
        ],
      ),
    );
  }
}

class _EmptySeven extends StatelessWidget {
  const _EmptySeven();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Chưa có lịch triều 7 ngày. Đồng bộ dữ liệu từ backend.', style: TextStyle(color: _kMuted)),
      ),
    );
  }
}
