import 'tide_schedule.dart';
import 'weather_day.dart';

class HomeData {
  HomeData({
    required this.todayTide,
    required this.tides7,
    required this.golden7,
    required this.weather7,
  });

  final TideSchedule? todayTide;
  final List<TideSchedule> tides7;
  final List<TideSchedule> golden7;
  final List<WeatherDay> weather7;
}
