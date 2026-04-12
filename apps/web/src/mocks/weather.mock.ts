import type { WeatherForecastDay } from "@/types/weather-forecast";

const today = new Date();
const dayNames = ["CN", "Thứ 2", "Thứ 3", "Thứ 4", "Thứ 5", "Thứ 6", "Thứ 7"];

function ymd(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
}

const patterns: Pick<
  WeatherForecastDay,
  "icon" | "tempMaxC" | "tempMinC" | "windMaxKmh" | "humidityPct" | "precipitationMm" | "weatherCode"
>[] = [
  { icon: "sunny", tempMaxC: 33, tempMinC: 26, windMaxKmh: 10, humidityPct: 68, precipitationMm: 0, weatherCode: 0 },
  { icon: "partly", tempMaxC: 32, tempMinC: 27, windMaxKmh: 12, humidityPct: 72, precipitationMm: 0.2, weatherCode: 2 },
  { icon: "sunny", tempMaxC: 34, tempMinC: 26, windMaxKmh: 8, humidityPct: 65, precipitationMm: 0, weatherCode: 1 },
  { icon: "cloudy", tempMaxC: 30, tempMinC: 25, windMaxKmh: 15, humidityPct: 80, precipitationMm: 1, weatherCode: 3 },
  { icon: "partly", tempMaxC: 31, tempMinC: 26, windMaxKmh: 11, humidityPct: 74, precipitationMm: 0, weatherCode: 2 },
  { icon: "rainy", tempMaxC: 29, tempMinC: 25, windMaxKmh: 18, humidityPct: 85, precipitationMm: 8, weatherCode: 65 },
  { icon: "sunny", tempMaxC: 33, tempMinC: 27, windMaxKmh: 9, humidityPct: 70, precipitationMm: 0, weatherCode: 0 },
];

export const mockWeatherForecast: WeatherForecastDay[] = patterns.map((p, i) => {
  const d = new Date(today);
  d.setDate(d.getDate() + i);
  const y = d.getFullYear();
  const mo = String(d.getMonth() + 1).padStart(2, "0");
  const da = String(d.getDate()).padStart(2, "0");
  const h = 5 + (i % 2);
  const mi = 20 + i * 2;
  return {
    date: ymd(d),
    tempMaxC: p.tempMaxC,
    tempMinC: p.tempMinC,
    precipitationMm: p.precipitationMm,
    windMaxKmh: p.windMaxKmh,
    humidityPct: p.humidityPct,
    weatherCode: p.weatherCode,
    icon: p.icon,
    sunrise: `${y}-${mo}-${da}T${String(h).padStart(2, "0")}:${String(mi).padStart(2, "0")}`,
    sunset: `${y}-${mo}-${da}T18:15`,
  };
});
