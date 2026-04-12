/**
 * Khớp JSON `GET /weather/forecast` (backend → Open-Meteo).
 * Giữ đồng bộ với `apps/api/src/weather/weather-forecast.types.ts` cho web & app mobile.
 */
export type WeatherIcon = "sunny" | "partly" | "cloudy" | "rainy";

export type WeatherForecastDay = {
  date: string;
  tempMaxC: number | null;
  tempMinC: number | null;
  precipitationMm: number | null;
  windMaxKmh: number | null;
  humidityPct: number | null;
  weatherCode: number | null;
  icon: WeatherIcon;
  sunrise: string | null;
  sunset: string | null;
};
