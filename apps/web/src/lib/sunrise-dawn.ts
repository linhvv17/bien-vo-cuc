import type { TripAdvice } from "@/lib/weather-tide-advice";
import type { TideScheduleApi } from "@/types/tide-schedule";
import type { WeatherForecastDay } from "@/types/weather-forecast";

/** Hiển thị giờ phút từ chuỗi Open-Meteo (local, không Z). */
export function formatClock(iso: string | null | undefined): string {
  if (!iso) return "—";
  try {
    const d = new Date(iso);
    if (Number.isNaN(d.getTime())) return "—";
    return d.toLocaleTimeString("vi-VN", { hour: "2-digit", minute: "2-digit", hour12: false });
  } catch {
    return "—";
  }
}

export type DawnOutlookLevel = "good" | "mixed" | "bad";

/** Đánh giá thận trọng cho buổi bình minh (chỉ dựa trên dự báo cả ngày — không thay thế quan sát tại chỗ). */
export function dawnOutlook(w: WeatherForecastDay): {
  level: DawnOutlookLevel;
  short: string;
  detail: string;
} {
  const p = w.precipitationMm ?? 0;
  if (p >= 8 || w.icon === "rainy") {
    return {
      level: "bad",
      short: "Kém cho bình minh",
      detail: "Dự báo mưa đáng kể — nên đổi ngày hoặc xác nhận lại trong ngày.",
    };
  }
  if (p >= 2 || w.icon === "cloudy") {
    return {
      level: "mixed",
      short: "Tạm ổn — nhiều mây / mưa nhẹ có thể xảy ra",
      detail: "Có thể vẫn chụp được; ánh sáng phụ thuộc mây cục bộ lúc mặt trời mọc.",
    };
  }
  return {
    level: "good",
    short: "Khá tốt cho bình minh",
    detail: "Ít mưa trên dự báo ngày — vẫn nên xem trời thực tế lúc sáng sớm.",
  };
}

/**
 * Gợi ý khung giờ có mặt tại bãi (check-in sớm để bắt ánh sáng vàng trước mặt trời mọc).
 * Không cam kết tuyệt đối — chỉ quy ước 45–15 phút trước sunrise.
 */
export function suggestedArrivalWindow(sunriseIso: string | null): { from: string; to: string } | null {
  if (!sunriseIso) return null;
  const sr = new Date(sunriseIso);
  if (Number.isNaN(sr.getTime())) return null;
  const from = new Date(sr.getTime() - 50 * 60 * 1000);
  const to = new Date(sr.getTime() - 12 * 60 * 1000);
  return {
    from: from.toLocaleTimeString("vi-VN", { hour: "2-digit", minute: "2-digit", hour12: false }),
    to: to.toLocaleTimeString("vi-VN", { hour: "2-digit", minute: "2-digit", hour12: false }),
  };
}

/** Điểm càng cao càng nên ưu tiên (bình minh + triều + mưa). */
export function scoreTripDay(
  w: WeatherForecastDay,
  tide: TideScheduleApi | undefined,
  advice: TripAdvice,
  dawn: { level: DawnOutlookLevel },
): number {
  let s = 0;
  if (dawn.level === "good") s += 5;
  else if (dawn.level === "mixed") s += 2;
  else s -= 4;

  if (advice.level === "great") s += 4;
  else if (advice.level === "ok") s += 1;
  else s -= 5;

  if (tide?.isGolden) s += 3;
  if (!tide) s -= 1;

  const p = w.precipitationMm ?? 0;
  s -= Math.min(p, 20) * 0.12;

  if (w.icon === "sunny") s += 2;
  else if (w.icon === "partly") s += 1;
  else if (w.icon === "rainy") s -= 4;

  return s;
}

export function pickBestTripDate(
  items: { w: WeatherForecastDay; tide: TideScheduleApi | undefined; advice: TripAdvice }[],
): string | null {
  if (!items.length) return null;
  let bestDate = items[0].w.date;
  let bestScore = -Infinity;
  for (const it of items) {
    const dawn = dawnOutlook(it.w);
    const sc = scoreTripDay(it.w, it.tide, it.advice, dawn);
    if (sc > bestScore) {
      bestScore = sc;
      bestDate = it.w.date;
    }
  }
  return bestDate;
}
