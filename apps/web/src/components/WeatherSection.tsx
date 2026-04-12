import { motion } from "framer-motion";
import {
  Sun,
  Cloud,
  CloudRain,
  CloudSun,
  Wind,
  Droplets,
  AlertCircle,
  RefreshCw,
  Waves,
  Sparkles,
  Sunrise,
  Sunset,
} from "lucide-react";
import { useCallback, useEffect, useMemo, useRef, useState, type ReactNode } from "react";
import useEmblaCarousel from "embla-carousel-react";

import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import { useTidesRange } from "@/hooks/api/useTides";
import { useWeatherForecast } from "@/hooks/api/useWeather";
import { dawnOutlook, formatClock, pickBestTripDate, suggestedArrivalWindow } from "@/lib/sunrise-dawn";
import {
  formatTideTime,
  isoToLocalYmd,
  lowestLowM,
  tripAdvice,
  type TripAdviceLevel,
} from "@/lib/weather-tide-advice";
import type { TideScheduleApi } from "@/types/tide-schedule";
import type { WeatherForecastDay, WeatherIcon } from "@/types/weather-forecast";

const icons: Record<WeatherIcon, ReactNode> = {
  sunny: <Sun className="text-dawn-gold" size={32} />,
  partly: <CloudSun className="text-dawn-gold" size={32} />,
  cloudy: <Cloud className="text-muted-foreground" size={32} />,
  rainy: <CloudRain className="text-sky-blue" size={32} />,
};

const dayNames = ["CN", "Thứ 2", "Thứ 3", "Thứ 4", "Thứ 5", "Thứ 6", "Thứ 7"];

function startOfLocalDay(d: Date): number {
  return new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime();
}

function parseYmdLocal(ymd: string): Date {
  const [y, m, d] = ymd.split("-").map(Number);
  return new Date(y, (m ?? 1) - 1, d ?? 1);
}

function formatDayRow(ymd: string): { day: string; dateLabel: string; isToday: boolean } {
  const d = parseYmdLocal(ymd);
  const today0 = startOfLocalDay(new Date());
  const row0 = startOfLocalDay(d);
  const diff = Math.round((row0 - today0) / 864e5);
  let day: string;
  if (diff === 0) day = "Hôm nay";
  else if (diff === 1) day = "Ngày mai";
  else day = dayNames[d.getDay()];
  const dateLabel = `${d.getDate()}/${d.getMonth() + 1}`;
  return { day, dateLabel, isToday: diff === 0 };
}

function fmtTemp(n: number | null | undefined): string {
  if (n == null || Number.isNaN(n)) return "—";
  return String(Math.round(n));
}

function fmtWindHum(n: number | null | undefined, suffix: string): string {
  if (n == null || Number.isNaN(n)) return "—";
  return `${Math.round(n)}${suffix}`;
}

function tideRowForDate(map: Map<string, TideScheduleApi>, ymd: string): TideScheduleApi | undefined {
  return map.get(ymd);
}

/** Ẩn ghi chú kỹ thuật / seed — không hiển thị cho khách. */
function tideNoteForGuests(note: string | null | undefined): string | null {
  if (!note?.trim()) return null;
  const t = note.trim();
  if (/stormglass|synced\s+from/i.test(t)) return null;
  if (/\bseed\b|\(seed\)/i.test(t)) return null;
  return t;
}

function verdictBarClass(level: TripAdviceLevel): string {
  if (level === "great") return "border-l-emerald-400/90 bg-emerald-500/[0.07]";
  if (level === "poor") return "border-l-rose-400/85 bg-rose-950/30";
  return "border-l-amber-400/45 bg-amber-500/[0.06]";
}

function WeatherDayCard({
  w,
  day,
  dateLabel,
  isToday,
  isBestPick,
  isFocused,
  tide,
  tideLoading,
  advice,
  index,
}: {
  w: WeatherForecastDay;
  day: string;
  dateLabel: string;
  isToday: boolean;
  isBestPick: boolean;
  /** Trong carousel: chỉ thẻ giữa được phóng to — hover nhẹ khi đang focus */
  isFocused?: boolean;
  tide: TideScheduleApi | undefined;
  tideLoading: boolean;
  advice: ReturnType<typeof tripAdvice>;
  index: number;
}) {
  const dawn = dawnOutlook(w);
  const arrive = suggestedArrivalWindow(w.sunrise);
  const dawnTone =
    dawn.level === "good"
      ? "text-emerald-300/95"
      : dawn.level === "mixed"
        ? "text-amber-200/95"
        : "text-rose-300/95";

  const guestNote = tide ? tideNoteForGuests(tide.note) : null;
  const rainLabel =
    w.precipitationMm != null && w.precipitationMm > 0
      ? `Mưa ~${w.precipitationMm < 1 ? w.precipitationMm.toFixed(1) : Math.round(w.precipitationMm)} mm`
      : "Không mưa";

  const focused = isFocused !== false;

  return (
    <motion.div
      id={`weather-day-${w.date}`}
      initial={{ opacity: 0, y: 16 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true }}
      transition={{ delay: index * 0.04 }}
      whileHover={focused ? { scale: 1.01 } : undefined}
      className={cn(
        "card-surface relative flex w-full max-w-lg scroll-mt-24 flex-col gap-2.5 p-3.5 sm:p-4",
        isBestPick && "ring-1 ring-amber-400/40 shadow-md shadow-black/25",
        focused && "shadow-lg shadow-black/40",
        !focused && "shadow-none",
        isToday && !isBestPick && "border-l-[3px] border-l-primary",
        isToday && isBestPick && "border-l-[3px] border-l-amber-400/70",
      )}
    >
      {isBestPick ? (
        <div className="absolute -top-2 left-1/2 z-10 flex -translate-x-1/2 items-center gap-1 rounded-full bg-amber-500 px-2 py-0.5 text-[10px] font-bold uppercase tracking-wide text-amber-950">
          <Sparkles className="h-3 w-3" aria-hidden />
          Nên đi nhất
        </div>
      ) : null}

      {/* Hàng 1: ngày + icon + nhiệt độ — một tầng thông tin */}
      <div className="flex items-start justify-between gap-2 pt-0.5">
        <div>
          <p className={`font-semibold leading-tight text-ocean-foreground ${isBestPick ? "text-[15px]" : "text-sm"}`}>{day}</p>
          <p className="text-xs text-surface-foreground/60">{dateLabel}</p>
        </div>
        <div className="flex shrink-0 items-center gap-2">
          <p className={`tabular-nums font-bold text-ocean-foreground ${isBestPick ? "text-xl" : "text-lg"}`}>
            {fmtTemp(w.tempMaxC)}°<span className="text-surface-foreground/45">/</span>
            {fmtTemp(w.tempMinC)}°
          </p>
          <div className="[&_svg]:h-8 [&_svg]:w-8">{icons[w.icon]}</div>
        </div>
      </div>

      {/* Bình minh — gọn, icon, không khối vàng */}
      <div className="rounded-lg border border-white/[0.07] bg-white/[0.03] px-2.5 py-2">
        <div className="flex gap-2">
          <Sunrise className="mt-0.5 h-4 w-4 shrink-0 text-dawn-gold" aria-hidden />
          <div className="min-w-0 flex-1 space-y-1">
            <p className={`text-[11px] font-medium leading-snug ${dawnTone}`}>{dawn.short}</p>
            <p className="font-display text-base font-bold tabular-nums text-dawn-gold">Mọc {formatClock(w.sunrise)}</p>
            {arrive ? (
              <p className="text-[11px] leading-snug text-surface-foreground/88">
                Nên tới ~{" "}
                <span className="font-semibold text-sky-200/95">
                  {arrive.from} – {arrive.to}
                </span>
              </p>
            ) : (
              <p className="text-[10px] text-muted-foreground">Chưa có giờ mọc.</p>
            )}
          </div>
        </div>
        {w.sunset ? (
          <div className="mt-2 flex items-center gap-1.5 border-t border-white/[0.06] pt-2 text-[10px] text-muted-foreground/85">
            <Sunset className="h-3.5 w-3.5 shrink-0 opacity-70" aria-hidden />
            Lặn {formatClock(w.sunset)}
          </div>
        ) : null}
      </div>

      {/* Thời tiết — một dòng */}
      <p className="text-[11px] leading-snug text-surface-foreground/75">
        <Wind className="mr-1 inline h-3.5 w-3.5 opacity-70" aria-hidden />
        {fmtWindHum(w.windMaxKmh, " km/h")}
        <span className="mx-1.5 text-white/20">·</span>
        <Droplets className="mr-1 inline h-3.5 w-3.5 opacity-70" aria-hidden />
        {fmtWindHum(w.humidityPct, "%")}
        <span className="mx-1.5 text-white/20">·</span>
        {w.precipitationMm != null && w.precipitationMm > 0 ? (
          <span className="text-sky-300/90">{rainLabel}</span>
        ) : (
          <span className="text-muted-foreground/80">{rainLabel}</span>
        )}
      </p>

      {/* Triều — luôn mở (không dùng details: tránh click làm nhảy carousel / đổi focus) */}
      {tideLoading && !tide ? (
        <p className="text-[11px] text-muted-foreground/90">Đang tải triều…</p>
      ) : tide ? (
        <div className="rounded-lg border border-sky-500/20 bg-sky-950/25 px-2.5 py-2">
          <div className="flex items-center gap-1.5 text-[11px] font-medium text-sky-200/95">
            <Waves className="h-3.5 w-3.5 shrink-0 opacity-90" aria-hidden />
            <span>Triều</span>
            <span className="font-normal text-surface-foreground/80">
              — thấp nhất <span className="tabular-nums font-semibold text-sky-100/95">{lowestLowM(tide).toFixed(2)} m</span>
            </span>
          </div>
          <p className="mt-1 text-[10px] leading-snug text-surface-foreground/65">
            {tide.isGolden ? "Mức cạn thuận chụp / đi bãi." : "Triều cao hơn — chụp “vô cực” kém lý tưởng hơn."}
          </p>
          <div className="mt-2 space-y-1 border-t border-white/10 pt-2 text-[10px] text-surface-foreground/85">
            <p className="tabular-nums">
              Đợt 1: <span className="text-ocean-foreground/95">{formatTideTime(tide.lowTime1)}</span>
              <span className="text-muted-foreground"> · </span>
              {tide.lowHeight1.toFixed(2)} m
            </p>
            {tide.lowTime2 != null && tide.lowHeight2 != null ? (
              <p className="tabular-nums">
                Đợt 2: <span className="text-ocean-foreground/95">{formatTideTime(tide.lowTime2)}</span>
                <span className="text-muted-foreground"> · </span>
                {tide.lowHeight2.toFixed(2)} m
              </p>
            ) : null}
            {guestNote ? <p className="pt-1 text-center text-[10px] leading-snug text-surface-foreground/70">{guestNote}</p> : null}
          </div>
        </div>
      ) : (
        <p className="text-[11px] text-muted-foreground/90">Chưa có triều cho ngày này.</p>
      )}

      {/* Một dòng kết luận — thay cho pill vàng + pill xanh chồng nhau */}
      <div className={`rounded-r-md border-l-[3px] py-2 pl-2.5 pr-1 ${verdictBarClass(advice.level)}`}>
        <p className="text-[11px] leading-snug text-surface-foreground/92">{advice.label}</p>
      </div>
    </motion.div>
  );
}

type ForecastRow = {
  w: WeatherForecastDay;
  day: string;
  dateLabel: string;
  isToday: boolean;
  tide: TideScheduleApi | undefined;
  advice: ReturnType<typeof tripAdvice>;
};

/** Embla Carousel — snap/kéo ổn định hơn native overflow (đã có sẵn embla-carousel-react). */
function WeatherForecastCarousel({
  rows,
  bestDate,
  tideLoading,
  data,
  registerScrollTo,
}: {
  rows: ForecastRow[];
  bestDate: string | null;
  tideLoading: boolean;
  data: WeatherForecastDay[] | undefined;
  registerScrollTo: (scrollTo: (index: number) => void) => void;
}) {
  const [emblaRef, emblaApi] = useEmblaCarousel({
    align: "center",
    // false: cho phép kéo tới đủ để slide cuối vẫn căn giữa (trimSnaps hay cắt snap khiến 1–2 ngày cuối không “trúng” center).
    containScroll: false,
    loop: false,
    dragFree: false,
  });
  const [selectedIndex, setSelectedIndex] = useState(0);

  useEffect(() => {
    if (!emblaApi) return;
    const sync = () => setSelectedIndex(emblaApi.selectedScrollSnap());
    emblaApi.on("select", sync);
    emblaApi.on("reInit", sync);
    sync();
    return () => {
      emblaApi.off("select", sync);
      emblaApi.off("reInit", sync);
    };
  }, [emblaApi]);

  useEffect(() => {
    emblaApi?.reInit();
  }, [emblaApi, rows.length]);

  const scrollToIndex = useCallback(
    (index: number) => {
      emblaApi?.scrollTo(index);
    },
    [emblaApi],
  );

  useEffect(() => {
    registerScrollTo(scrollToIndex);
  }, [registerScrollTo, scrollToIndex]);

  const didInitialBestScroll = useRef(false);
  useEffect(() => {
    if (!emblaApi || didInitialBestScroll.current || !bestDate || !data?.length) return;
    const idx = data.findIndex((w) => w.date === bestDate);
    if (idx < 0) return;
    emblaApi.scrollTo(idx, true);
    didInitialBestScroll.current = true;
  }, [emblaApi, bestDate, data]);

  return (
    <>
      <p className="mb-2 text-center text-[13px] text-ocean-foreground/70">
        Kéo hoặc vuốt ngang — thẻ giữa nổi bật.
      </p>
      <div
        ref={emblaRef}
        className="overflow-hidden py-8 [-webkit-overflow-scrolling:touch]"
        role="region"
        aria-roledescription="carousel"
        aria-label="Dự báo 7 ngày, cuộn ngang"
      >
        {/* Padding đối xứng = (½ viewport − ½ độ rộng slide): mọi ngày đều có thể nằm giữa → phóng to đúng cả 2 ngày cuối */}
        <div className="flex touch-pan-y pl-[max(1rem,calc(50%-min(42.5vw,9.25rem)))] pr-[max(1rem,calc(50%-min(42.5vw,9.25rem)))]">
          {rows.map(({ w, day, dateLabel, isToday, tide, advice }, i) => (
            <div
              key={w.date}
              className={cn(
                "min-w-0 shrink-0 px-2.5 transition-[transform,opacity] duration-300 ease-out [flex:0_0_min(85vw,18.5rem)] will-change-transform",
                selectedIndex === i ? "z-20 scale-105 opacity-100" : "z-0 scale-[0.9] opacity-[0.58]",
              )}
            >
              <WeatherDayCard
                w={w}
                day={day}
                dateLabel={dateLabel}
                isToday={isToday}
                isBestPick={bestDate === w.date}
                isFocused={selectedIndex === i}
                tide={tide}
                tideLoading={tideLoading}
                advice={advice}
                index={i}
              />
            </div>
          ))}
        </div>
      </div>
      <div className="mt-2 flex flex-wrap items-center justify-center gap-2" role="tablist" aria-label="Chọn nhanh ngày">
        {rows.map(({ w, day, dateLabel }, i) => (
          <button
            key={w.date}
            type="button"
            role="tab"
            aria-selected={selectedIndex === i}
            className={cn(
              "min-h-[36px] min-w-[36px] rounded-full px-2.5 text-[11px] font-medium transition-colors",
              selectedIndex === i
                ? "bg-primary text-primary-foreground shadow-md"
                : "bg-white/10 text-ocean-foreground/80 hover:bg-white/15",
            )}
            onClick={() => scrollToIndex(i)}
          >
            {day === "Hôm nay" || day === "Ngày mai" ? day : dateLabel}
          </button>
        ))}
      </div>
    </>
  );
}

export default function WeatherSection() {
  const { data, isLoading, isError, error, refetch, isFetching } = useWeatherForecast();

  const range = useMemo(() => {
    if (!data?.length) return { from: undefined as string | undefined, to: undefined as string | undefined };
    return { from: data[0].date, to: data[data.length - 1].date };
  }, [data]);

  const { data: tideRows, isLoading: tideLoading } = useTidesRange(range.from, range.to);

  const tideByDate = useMemo(() => {
    const m = new Map<string, TideScheduleApi>();
    for (const t of tideRows ?? []) {
      m.set(isoToLocalYmd(t.date), t);
    }
    return m;
  }, [tideRows]);

  const rows = useMemo(() => {
    if (!data?.length) return [];
    return data.map((w) => {
      const { day, dateLabel, isToday } = formatDayRow(w.date);
      const tide = tideRowForDate(tideByDate, w.date);
      const advice = tripAdvice(w, tide);
      return { w, day, dateLabel, isToday, tide, advice };
    });
  }, [data, tideByDate]);

  const bestDate = useMemo(() => {
    if (!rows.length) return null;
    return pickBestTripDate(rows.map((r) => ({ w: r.w, tide: r.tide, advice: r.advice })));
  }, [rows]);

  const bestRow = bestDate ? rows.find((r) => r.w.date === bestDate) : undefined;

  const emblaScrollToRef = useRef<(index: number) => void>(() => {});
  const registerEmblaScroll = useCallback((fn: (index: number) => void) => {
    emblaScrollToRef.current = fn;
  }, []);

  return (
    <section id="thoi-tiet" className="section-dark py-12 sm:py-16 md:py-24">
      <div className="container max-w-7xl px-4 sm:px-6">
        <motion.h2
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="font-display text-3xl md:text-4xl font-bold text-ocean-foreground text-center mb-4"
        >
          Dự Báo Thời Tiết 7 Ngày
        </motion.h2>
        <p className="mx-auto mb-6 max-w-lg text-center text-sm leading-relaxed text-ocean-foreground/65 sm:mb-8">
          <strong className="text-ocean-foreground/90">Kéo ngang</strong> — thẻ ở giữa nổi bật; trong thẻ: bình minh →
          thời tiết → triều → gợi ý cuối.
        </p>
        <p className="mb-6 text-center text-[11px] text-ocean-foreground/40 sm:mb-8">
          Dữ liệu: Open-Meteo + triều theo tọa độ bãi
          {isFetching && !isLoading ? " · Đang cập nhật…" : ""}
          {tideLoading && rows.length > 0 ? " · Đang tải triều…" : ""}
        </p>

        {!isLoading && !isError && bestRow && bestDate ? (
          <motion.div
            initial={{ opacity: 0, y: 8 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="mb-6 rounded-xl border border-amber-400/35 bg-amber-500/[0.08] px-4 py-4 sm:mb-8 sm:px-5"
          >
            <div className="flex flex-col items-center gap-3 text-center sm:flex-row sm:justify-between sm:text-left">
              <div className="flex items-center gap-2.5">
                <Sparkles className="h-5 w-5 shrink-0 text-amber-200/90" aria-hidden />
                <div>
                  <p className="text-sm font-semibold text-ocean-foreground">
                    Gợi ý trong 7 ngày:{" "}
                    <span className="text-white">
                      {bestRow.day} {bestRow.dateLabel}
                    </span>
                  </p>
                  <p className="mt-0.5 text-[11px] text-ocean-foreground/55">
                    Ngày đẹp nhất có nhãn &quot;Nên đi nhất&quot;.
                  </p>
                </div>
              </div>
              <Button
                type="button"
                variant="outline"
                size="sm"
                className="min-h-[40px] shrink-0 border-amber-400/30 bg-ocean/40 text-amber-50 hover:bg-ocean/60"
                onClick={() => {
                  const idx = data?.findIndex((w) => w.date === bestDate) ?? -1;
                  if (idx >= 0) emblaScrollToRef.current(idx);
                }}
              >
                Xem ngày đẹp nhất
              </Button>
            </div>
          </motion.div>
        ) : null}

        {isLoading ? (
          <>
            <p className="mb-3 text-center text-xs text-ocean-foreground/55">Đang tải…</p>
            <div className="flex snap-x snap-mandatory gap-5 overflow-x-auto py-6 [-webkit-overflow-scrolling:touch] scroll-pl-[max(1rem,calc(50vw-9.25rem))] scroll-pr-[max(1rem,calc(50vw-9.25rem))]">
              {[1, 2, 3, 4, 5, 6, 7].map((i) => (
                <div
                  key={i}
                  className="w-[min(85vw,18.5rem)] shrink-0 snap-center"
                  style={{ animationDelay: `${i * 40}ms` }}
                >
                  <div className="card-surface min-h-[16rem] scale-95 animate-pulse rounded-2xl bg-surface/40 opacity-60" />
                </div>
              ))}
            </div>
          </>
        ) : isError ? (
          <div className="rounded-2xl border border-rose-400/25 bg-rose-950/30 px-6 py-10 text-center">
            <AlertCircle className="mx-auto h-10 w-10 text-rose-300" aria-hidden />
            <p className="mt-3 text-sm text-rose-100/90">{error instanceof Error ? error.message : "Không tải được dự báo"}</p>
            <Button
              type="button"
              variant="outline"
              size="sm"
              className="mt-4 border-rose-400/40"
              onClick={() => void refetch()}
            >
              <RefreshCw className="mr-2 h-4 w-4" />
              Thử lại
            </Button>
          </div>
        ) : rows.length === 0 ? (
          <p className="text-center text-sm text-muted-foreground">Chưa có dữ liệu dự báo.</p>
        ) : (
          <WeatherForecastCarousel
            rows={rows}
            bestDate={bestDate}
            tideLoading={tideLoading}
            data={data}
            registerScrollTo={registerEmblaScroll}
          />
        )}

        <div className="mt-8 max-w-2xl mx-auto space-y-3 border-t border-white/10 pt-6 text-center text-[11px] leading-relaxed text-muted-foreground/95">
          <p>
            <strong className="text-ocean-foreground/90">Trách nhiệm và độ chính xác:</strong> Giờ mặt trời
            mọc/lặn do Open-Meteo tính theo tọa độ bãi (cùng hệ với dự báo). Dự báo mưa/mây là cho{" "}
            <em>cả ngày</em> — tại chỗ lúc bình minh có thể khác (mây cục bộ, sương mù, gió biển). Không thay thế
            quan sát trực tiếp, bản đồ hàng hải hay ý kiến người địa phương. Với chuyến quan trọng, hãy xác nhận
            lại sáng sớm trong ngày.
          </p>
          <p className="text-muted-foreground/80">
            Câu &quot;Nên có mặt tại bãi&quot; là gợi ý quy ước (15–50 phút trước giờ mọc), phù hợp ánh sáng vàng —
            không phải cam kết thời điểm chụp đẹp nhất.
          </p>
        </div>
      </div>
    </section>
  );
}
