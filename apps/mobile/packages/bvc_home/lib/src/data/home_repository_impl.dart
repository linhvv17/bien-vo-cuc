import 'dart:async';

import 'package:bvc_common/bvc_common.dart';
import 'package:bvc_network/bvc_network.dart';
import '../domain/entities/home_data.dart';
import '../domain/entities/tide_schedule.dart';
import '../domain/entities/weather_day.dart';
import 'home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl(this._network);

  final NetworkService _network;

  @override
  Future<HomeData> fetchHomeData() async {
    return _fetchHomeDataInner().timeout(
      const Duration(seconds: 25),
      onTimeout: () => throw TimeoutException(
        'Tải dữ liệu Home quá lâu (triều/thời tiết). Kiểm tra API và mạng.',
      ),
    );
  }

  Future<HomeData> _fetchHomeDataInner() async {
    // Neo 7 ngày: hôm nay (VN) … +6 ngày — khớp lịch triều/thời tiết.
    final ymdToday = ymdVietnamToday();
    final ymdFrom = ymdToday;
    final ymdTo = ymdAddCalendarDays(ymdToday, 6);

    final tideTodayFut =
        _network.get<Map<String, dynamic>>('/tides', queryParameters: {'date': ymdToday});
    final tideRangeFut = _network.get<Map<String, dynamic>>(
      '/tides/range',
      queryParameters: {'from': ymdFrom, 'to': ymdTo},
    );
    final goldenFut = _network.get<Map<String, dynamic>>(
      '/tides/golden-hours',
      queryParameters: {'from': ymdFrom, 'to': ymdTo},
    );
    final weatherFut = _network.get<Map<String, dynamic>>(
      '/weather/forecast',
      queryParameters: {'lat': kBeachLat, 'lon': kBeachLng},
    );

    // Weather có thể bị upstream rate-limit (429). Không nên làm "sập" toàn Home;
    // vẫn render triều/golden-hours, còn weather để rỗng và có thể refresh sau.
    final results = await Future.wait(
      [tideTodayFut, tideRangeFut, goldenFut],
    );
    Map<String, dynamic>? weatherRaw;
    try {
      final w = await weatherFut;
      if (w.data is Map<String, dynamic>) weatherRaw = (w.data as Map<String, dynamic>);
    } catch (_) {
      weatherRaw = null;
    }

    TideSchedule? todayParsed;
    final r0 = results[0].data;
    if (r0 is Map<String, dynamic>) {
      final body = parseApiResponse<TideSchedule?>(
        r0,
        (data) => data == null ? null : TideSchedule.fromJson((data as Map).cast<String, dynamic>()),
      );
      todayParsed = body.data;
    }

    List<TideSchedule> parseTideList(dynamic raw) {
      if (raw is! Map<String, dynamic>) return [];
      final body = parseApiResponse<List<TideSchedule>>(
        raw,
        (data) => (data as List<dynamic>? ?? const [])
            .map((e) => TideSchedule.fromJson((e as Map).cast<String, dynamic>()))
            .toList(growable: false),
      );
      return body.data;
    }

    List<WeatherDay> parseWeatherList(dynamic raw) {
      if (raw is! Map<String, dynamic>) return [];
      final body = parseApiResponse<List<WeatherDay>>(
        raw,
        (data) => (data as List<dynamic>? ?? const [])
            .map((e) => WeatherDay.fromJson((e as Map).cast<String, dynamic>()))
            .toList(growable: false),
      );
      return body.data;
    }

    return HomeData(
      todayTide: todayParsed,
      tides7: parseTideList(results[1].data),
      golden7: parseTideList(results[2].data),
      weather7: parseWeatherList(weatherRaw),
    );
  }
}

