import {
  Injectable,
  HttpException,
  HttpStatus,
  InternalServerErrorException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import type { WeatherForecastDay } from './weather-forecast.types';
import { wmoCodeToIcon } from './wmo-icon.util';

/** Open-Meteo (không cần API key). Nguồn thật, cache có thể thêm sau. */
@Injectable()
export class WeatherService {
  constructor(private readonly config: ConfigService) {}

  // Simple in-memory cache to avoid hitting upstream rate limits.
  // Render free tier / small instances are fine with this for a single location.
  static readonly _cache = new Map<
    string,
    { expiresAtMs: number; value: WeatherForecastDay[] }
  >();

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

  private cacheKey(lat: number, lon: number): string {
    // Normalize to reduce key explosion from floats.
    return `${lat.toFixed(4)},${lon.toFixed(4)}`;
  }

  private getCached(lat: number, lon: number): WeatherForecastDay[] | null {
    const key = this.cacheKey(lat, lon);
    const hit = WeatherService._cache.get(key);
    if (!hit) return null;
    if (Date.now() >= hit.expiresAtMs) {
      WeatherService._cache.delete(key);
      return null;
    }
    return hit.value;
  }

  private setCached(lat: number, lon: number, value: WeatherForecastDay[]) {
    const ttlMs = 10 * 60 * 1000; // 10 minutes
    const key = this.cacheKey(lat, lon);
    WeatherService._cache.set(key, { expiresAtMs: Date.now() + ttlMs, value });
  }

  async getForecast7Days(params?: {
    lat?: number;
    lon?: number;
  }): Promise<WeatherForecastDay[]> {
    const def = this.defaultCoords();
    const lat = params?.lat ?? def.lat;
    const lon = params?.lon ?? def.lon;

    const cached = this.getCached(lat, lon);
    if (cached != null) return cached;

    const url = new URL('https://api.open-meteo.com/v1/forecast');
    url.searchParams.set('latitude', String(lat));
    url.searchParams.set('longitude', String(lon));
    url.searchParams.set(
      'daily',
      'temperature_2m_max,temperature_2m_min,precipitation_sum,weather_code,wind_speed_10m_max,relative_humidity_2m_max,sunrise,sunset',
    );
    url.searchParams.set('timezone', 'Asia/Ho_Chi_Minh');
    url.searchParams.set('forecast_days', '7');

    try {
      const f = globalThis.fetch;
      if (typeof f !== 'function') {
        throw new InternalServerErrorException(
          'Weather fetch() không khả dụng trên runtime hiện tại. Hãy đảm bảo Render dùng Node >= 18 (hoặc thêm polyfill fetch).',
        );
      }
      const controller = new AbortController();
      const t = setTimeout(() => controller.abort(), 12_000);
      const res = await f(url, {
        signal: controller.signal,
        headers: {
          Accept: 'application/json',
          // Some upstreams behave better when a UA is present.
          'User-Agent': 'bien-vo-cuc-api/1.0 (+https://bienvocuc.vn)',
        },
      }).finally(() => clearTimeout(t));
      if (!res.ok) {
        if (res.status === 429) {
          // If upstream rate-limits us, try to serve stale-ish data.
          const stale = this.getCached(lat, lon);
          if (stale != null) return stale;
          throw new HttpException(
            'Weather upstream đang giới hạn (429). Vui lòng thử lại sau.',
            HttpStatus.TOO_MANY_REQUESTS,
          );
        }
        throw new InternalServerErrorException(
          `Weather upstream error: ${res.status} ${res.statusText}`.trim(),
        );
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

      const out = daily.time.map((t: string, i: number) => {
        const weatherCode = daily.weather_code?.[i] ?? null;
        const tempMaxC = daily.temperature_2m_max?.[i] ?? null;
        const tempMinC = daily.temperature_2m_min?.[i] ?? null;
        const precipitationMm = daily.precipitation_sum?.[i] ?? null;
        const windMaxKmh = daily.wind_speed_10m_max?.[i] ?? null;
        const humidityPct = daily.relative_humidity_2m_max?.[i] ?? null;

        // NOTE: Mobile app currently expects `tempMin/tempMax/precipitationSum/windSpeedMax`.
        // Keep both naming styles for backwards/forwards compatibility.
        return {
          date: t,
          tempMaxC: tempMaxC,
          tempMinC: tempMinC,
          precipitationMm: precipitationMm,
          windMaxKmh: windMaxKmh,
          humidityPct: humidityPct,
          tempMax: tempMaxC,
          tempMin: tempMinC,
          precipitationSum: precipitationMm,
          windSpeedMax: windMaxKmh,
          weatherCode: weatherCode != null ? Number(weatherCode) : null,
          icon: wmoCodeToIcon(weatherCode != null ? Number(weatherCode) : null),
          sunrise: daily.sunrise?.[i] ?? null,
          sunset: daily.sunset?.[i] ?? null,
        } satisfies WeatherForecastDay;
      });
      this.setCached(lat, lon, out);
      return out;
    } catch (e) {
      if (e instanceof InternalServerErrorException) throw e;
      if (e instanceof HttpException) throw e;
      throw new InternalServerErrorException(
        `Weather request failed: ${e instanceof Error ? e.message : String(e)}`,
      );
    }
  }
}
