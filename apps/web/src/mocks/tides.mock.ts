import type { TideScheduleApi } from "@/types/tide-schedule";

export interface TideData {
  date: string;
  isLowTide: boolean;
  lowTideTime?: string;
  highTideTime?: string;
  isGolden: boolean;
  goldenStart?: string;
  goldenEnd?: string;
}

const today = new Date();

export const mockTides: TideData[] = Array.from({ length: 7 }, (_, i) => {
  const d = new Date(today);
  d.setDate(d.getDate() + i);
  const dateStr = d.toISOString().split("T")[0];
  const isGolden = [0, 1, 4, 6].includes(i);
  return {
    date: dateStr,
    isLowTide: isGolden,
    lowTideTime: isGolden ? `0${5 + (i % 2)}:${20 + i * 5}` : undefined,
    highTideTime: !isGolden ? `0${6 + (i % 2)}:${10 + i * 3}` : undefined,
    isGolden,
    goldenStart: isGolden ? `0${5 + (i % 2)}:${20 + i * 5}` : undefined,
    goldenEnd: isGolden ? "07:30" : undefined,
  };
});

export const mockGoldenHours = mockTides.filter((t) => t.isGolden);

function parseYmdLocal(ymd: string): Date {
  const [y, m, d] = ymd.split("-").map(Number);
  return new Date(y, (m ?? 1) - 1, d ?? 1);
}

/** Lịch triều giả theo khoảng ngày — dùng khi `VITE_USE_MOCK=true`, khớp shape API. */
export function mockTideRange(fromYmd: string, toYmd: string): TideScheduleApi[] {
  const out: TideScheduleApi[] = [];
  const cur = parseYmdLocal(fromYmd);
  const end = parseYmdLocal(toYmd);
  let i = 0;
  while (cur.getTime() <= end.getTime()) {
    const y = cur.getFullYear();
    const mo = String(cur.getMonth() + 1).padStart(2, "0");
    const da = String(cur.getDate()).padStart(2, "0");
    const ymd = `${y}-${mo}-${da}`;
    const isGolden = [0, 1, 4, 6].includes(i % 7);
    const lowH = isGolden ? 0.35 + (i % 3) * 0.08 : 1.05 + (i % 2) * 0.12;
    out.push({
      id: `mock-tide-${ymd}`,
      date: `${ymd}T12:00:00.000Z`,
      lowTime1: new Date(y, cur.getMonth(), cur.getDate(), 5, 18 + (i % 8)).toISOString(),
      lowHeight1: lowH,
      lowTime2: null,
      lowHeight2: null,
      isGolden,
      note: null,
    });
    cur.setDate(cur.getDate() + 1);
    i += 1;
  }
  return out;
}
