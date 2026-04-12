import type { TideScheduleApi } from "@/types/tide-schedule";
import type { WeatherForecastDay } from "@/types/weather-forecast";

/**
 * Prisma trả `date` dạng ISO UTC — cắt chuỗi `YYYY-MM-DD` sai múi (VN +7).
 * Dùng key này để khớp với `w.date` từ Open-Meteo (ngày theo lịch địa phương).
 */
export function isoToLocalYmd(iso: string): string {
  const d = new Date(iso);
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
}

export type TripAdviceLevel = "great" | "ok" | "poor";

export type TripAdvice = {
  level: TripAdviceLevel;
  /** Một dòng gợi ý cho khách */
  label: string;
};

/** Kết hợp thời tiết (Open-Meteo) + lịch triều (DB) để gợi ý có nên đi không. */
export function tripAdvice(w: WeatherForecastDay, tide: TideScheduleApi | undefined): TripAdvice {
  const precip = w.precipitationMm ?? 0;
  const heavyRain = precip >= 10 || (w.icon === "rainy" && precip >= 3);

  if (!tide) {
    return { level: "ok", label: "Chưa có dữ liệu triều cho ngày này." };
  }

  if (heavyRain) {
    return { level: "poor", label: "Mưa nhiều — nên đổi ngày hoặc chờ hết mưa." };
  }

  const fairSky = w.icon === "sunny" || w.icon === "partly";

  if (tide.isGolden && fairSky && precip < 3) {
    return { level: "great", label: "Triều cạn + trời khá đẹp — thuận đi chơi/chụp." };
  }

  if (tide.isGolden) {
    return { level: "great", label: "Triều cạn — nhớ xem lại mưa sáng hôm đó." };
  }

  if (w.icon === "rainy" || precip >= 5) {
    return { level: "poor", label: "Mưa hoặc triều không thuận — cân nhắc đổi ngày." };
  }

  return { level: "ok", label: "Tạm ổn — nên xác nhận tại bãi." };
}

export function lowestLowM(t: TideScheduleApi): number {
  const a = t.lowHeight1;
  const b = t.lowHeight2;
  if (b == null) return a;
  return Math.min(a, b);
}

export function formatTideTime(iso: string): string {
  try {
    return new Date(iso).toLocaleTimeString("vi-VN", { hour: "2-digit", minute: "2-digit" });
  } catch {
    return "—";
  }
}
