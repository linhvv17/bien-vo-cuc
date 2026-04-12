class WeatherDay {
  WeatherDay({
    required this.date,
    required this.tempMin,
    required this.tempMax,
    required this.precipitationSum,
    required this.weatherCode,
    required this.windSpeedMax,
  });

  final String date;
  final num? tempMin;
  final num? tempMax;
  final num? precipitationSum;
  final num? weatherCode;
  final num? windSpeedMax;

  factory WeatherDay.fromJson(Map<String, dynamic> json) {
    return WeatherDay(
      date: json['date'] as String,
      tempMin: json['tempMin'] as num?,
      tempMax: json['tempMax'] as num?,
      precipitationSum: json['precipitationSum'] as num?,
      weatherCode: json['weatherCode'] as num?,
      windSpeedMax: json['windSpeedMax'] as num?,
    );
  }
}
