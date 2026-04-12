import { useQuery } from "@tanstack/react-query";
import { guestApiClient } from "@/lib/api-client";
import { mockWeatherForecast } from "@/mocks/weather.mock";
import type { WeatherForecastDay } from "@/types/weather-forecast";

/** `true` chỉ khi `.env` đặt `VITE_USE_MOCK=true` — mặc định gọi API thật (cùng nguồn với app mobile). */
const useMock = import.meta.env.VITE_USE_MOCK === "true";

export type UseWeatherForecastParams = {
  /** Gửi lên `GET /weather/forecast?lat=&lon=`. Bỏ qua thì backend dùng BEACH_LAT / BEACH_LNG. */
  lat?: number;
  lon?: number;
};

export const useWeatherForecast = (params?: UseWeatherForecastParams) =>
  useQuery<WeatherForecastDay[]>({
    queryKey: ["weather", "forecast", params?.lat ?? null, params?.lon ?? null],
    queryFn: async () => {
      if (useMock) return mockWeatherForecast;
      const q: Record<string, string> = {};
      if (params?.lat != null) q.lat = String(params.lat);
      if (params?.lon != null) q.lon = String(params.lon);
      const res = await guestApiClient.get<WeatherForecastDay[]>("weather/forecast", {
        params: Object.keys(q).length ? q : undefined,
      });
      return res.data;
    },
    staleTime: 30 * 60 * 1000,
  });
