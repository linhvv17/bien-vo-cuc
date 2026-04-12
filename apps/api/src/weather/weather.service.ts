import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import type { WeatherForecastDay } from './weather-forecast.types';
import { wmoCodeToIcon } from './wmo-icon.util';

/** Open-Meteo (không cần API key). Nguồn thật, cache có thể thêm sau. */
@Injectable()
export class WeatherService {
  constructor(private readonly config: ConfigService) {}

  private defaultCoords(): { lat: number; lon: number } {
    const latRaw = this.config.get<string>('BEACH_LAT') ?? '20.5774021';
    const lonRaw = this.config.get<string>('BEACH_LNG') ?? '106.6192557';
    const lat = Number.parseFloat(latRaw);
    const lon = Number.parseFloat(lonRaw);
    return {
      lat: Number.isFinite(lat) ? lat : 20.5774021,
      lon: Number.isFinite(lon) ? lon : 106.6192557,
    };
  }

  async getForecast7Days(params?: {
    lat?: number;
    lon?: number;
  }): Promise<WeatherForecastDay[]> {
    const def = this.defaultCoords();
    const lat = params?.lat ?? def.lat;
    const lon = params?.lon ?? def.lon;

    const url = new URL('https://api.open-meteo.com/v1/forecast');
    url.searchParams.set('latitude', String(lat));
    url.searchParams.set('longitude', String(lon));
    url.searchParams.set(
      'daily',
      'temperature_2m_max,temperature_2m_min,precipitation_sum,weather_code,wind_speed_10m_max,relative_humidity_2m_max,sunrise,sunset',
    );
    url.searchParams.set('timezone', 'Asia/Ho_Chi_Minh');
    url.searchParams.set('forecast_days', '7');

    const res = await fetch(url);
    if (!res.ok) {
      throw new Error(`Weather upstream error: ${res.status}`);
    }
    const json = (await res.json()) as {
      daily?: {
        time?: string[];
        temperature_2m_max?: (number | null)[];
        temperature_2m_min?: (number | null)[];
        precipitation_sum?: (number | null)[];
        weather_code?: (number | null)[];
        wind_speed_10m_max?: (number | null)[];
        relative_humidity_2m_max?: (number | null)[];
        sunrise?: (string | null)[];
        sunset?: (string | null)[];
      };
    };

    const daily = json?.daily;
    if (!daily?.time || !Array.isArray(daily.time)) return [];

    return daily.time.map((t: string, i: number) => {
      const weatherCode = daily.weather_code?.[i] ?? null;
      return {
        date: t,
        tempMaxC: daily.temperature_2m_max?.[i] ?? null,
        tempMinC: daily.temperature_2m_min?.[i] ?? null,
        precipitationMm: daily.precipitation_sum?.[i] ?? null,
        windMaxKmh: daily.wind_speed_10m_max?.[i] ?? null,
        humidityPct: daily.relative_humidity_2m_max?.[i] ?? null,
        weatherCode: weatherCode != null ? Number(weatherCode) : null,
        icon: wmoCodeToIcon(weatherCode != null ? Number(weatherCode) : null),
        sunrise: daily.sunrise?.[i] ?? null,
        sunset: daily.sunset?.[i] ?? null,
      } satisfies WeatherForecastDay;
    });
  }
}
