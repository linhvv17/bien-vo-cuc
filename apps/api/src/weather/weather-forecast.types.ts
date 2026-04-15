/**
 * Payload `GET /weather/forecast` — cùng contract cho web end-user và app mobile (Open-Meteo qua backend).
 */
export type WeatherIcon = 'sunny' | 'partly' | 'cloudy' | 'rainy';

export interface WeatherForecastDay {
  /** YYYY-MM-DD (Asia/Ho_Chi_Minh) */
  date: string;
  tempMaxC: number | null;
  tempMinC: number | null;
  precipitationMm: number | null;
  windMaxKmh: number | null;
  humidityPct: number | null;
  /** WMO code (Open-Meteo) */
  weatherCode: number | null;
  icon: WeatherIcon;
  /** Mặt trời mọc (ISO8601, timezone Asia/Ho_Chi_Minh) — Open-Meteo. */
  sunrise: string | null;
  /** Mặt trời lặn */
  sunset: string | null;

  /**
   * Aliases for mobile/web clients that still expect legacy field names.
   * Keep them optional to avoid breaking strict typing.
   */
  tempMax?: number | null;
  tempMin?: number | null;
  precipitationSum?: number | null;
  windSpeedMax?: number | null;
}
