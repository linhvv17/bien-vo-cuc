import type { WeatherIcon } from './weather-forecast.types';

/** WMO Weather interpretation codes (Open-Meteo). */
export function wmoCodeToIcon(code: number | null | undefined): WeatherIcon {
  if (code == null || Number.isNaN(code)) return 'partly';
  if (code === 0) return 'sunny';
  if (code === 1 || code === 2) return 'partly';
  if (code === 3) return 'cloudy';
  if (code >= 45 && code <= 48) return 'cloudy';
  if (code >= 51 && code <= 67) return 'rainy';
  if (code >= 71 && code <= 77) return 'partly';
  if (code >= 80 && code <= 82) return 'rainy';
  if (code >= 85 && code <= 86) return 'rainy';
  if (code >= 95 && code <= 99) return 'rainy';
  return 'partly';
}
