import 'package:flutter/material.dart';

import 'entities/tide_schedule.dart';
import 'entities/weather_day.dart';

class GoScore {
  GoScore({
    required this.score,
    required this.verdict,
    required this.reasons,
  });

  final int score;
  final String verdict;
  final List<String> reasons;

  Color accent() {
    if (score >= 70) return const Color(0xFF2ECC71);
    if (score >= 45) return const Color(0xFFF2C94C);
    return const Color(0xFFE74C3C);
  }
}

GoScore computeGoScore({
  required WeatherDay? weather,
  required TideSchedule? tide,
}) {
  final reasons = <String>[];
  var s = 72;

  if (tide != null && tide.isGolden) {
    s += 10;
    reasons.add('Khung triều “vàng” trong ngày');
  }

  if (weather != null) {
    final p = (weather.precipitationSum ?? 0).toDouble();
    if (p >= 8) {
      s -= 35;
      reasons.add('Mưa lớn dự báo (${p.toStringAsFixed(1)} mm)');
    } else if (p >= 4) {
      s -= 18;
      reasons.add('Mưa vừa (${p.toStringAsFixed(1)} mm)');
    } else if (p >= 1) {
      s -= 8;
      reasons.add('Có mưa nhẹ');
    }

    final w = (weather.windSpeedMax ?? 0).toDouble();
    if (w >= 55) {
      s -= 22;
      reasons.add('Gió rất mạnh (${w.toStringAsFixed(0)} km/h)');
    } else if (w >= 40) {
      s -= 14;
      reasons.add('Gió khá mạnh');
    } else if (w >= 28) {
      s -= 7;
      reasons.add('Gió hơi mạnh');
    }

    final code = (weather.weatherCode ?? 0).toInt();
    if (code == 95 || code == 96 || code == 99) {
      s -= 28;
      reasons.add('Dông/sét (WMO $code)');
    } else if (code >= 80 && code <= 86) {
      s -= 10;
      reasons.add('Mưa rào');
    }
  } else {
    reasons.add('Chưa có dữ liệu thời tiết chi tiết');
  }

  reasons.add('Ưu tiên khung sáng sớm (bình minh)');

  s = s.clamp(0, 100);
  final verdict = s >= 70 ? 'NÊN ĐI' : (s >= 45 ? 'CÂN NHẮC' : 'KHÔNG NÊN');
  return GoScore(score: s, verdict: verdict, reasons: reasons);
}
