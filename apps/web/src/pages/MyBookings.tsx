import { useAuth } from "@/contexts/AuthContext";
import {
  useCancelMyBooking,
  useMyBookings,
  type MyBookingsStatusFilter,
  type WebBookingMine,
} from "@/hooks/api/useMyBookings";
import StickyNav from "@/components/StickyNav";
import { Button } from "@/components/ui/button";
import { Separator } from "@/components/ui/separator";
import { Link, Navigate } from "react-router-dom";
import {
  ArrowLeft,
  Banknote,
  CalendarDays,
  Loader2,
  PackageOpen,
  Phone,
  Sparkles,
  Tag,
  User,
  AlertCircle,
  RefreshCw,
} from "lucide-react";
import { toast } from "sonner";
import { motion } from "framer-motion";
import { useState } from "react";

const STATUS_FILTERS: { value: MyBookingsStatusFilter; label: string }[] = [
  { value: null, label: "Tất cả" },
  { value: "PENDING", label: "Chờ xác nhận" },
  { value: "CONFIRMED", label: "Đã xác nhận" },
  { value: "CANCELLED", label: "Đã hủy" },
];

function statusMeta(s: WebBookingMine["status"]): { label: string; dot: string; pill: string } {
  switch (s) {
    case "PENDING":
      return {
        label: "Chờ xác nhận",
        dot: "bg-amber-400 shadow-[0_0_8px_rgba(251,191,36,0.5)]",
        pill: "bg-amber-500/15 text-amber-100 border border-amber-400/25",
      };
    case "CONFIRMED":
      return {
        label: "Đã xác nhận",
        dot: "bg-emerald-400 shadow-[0_0_8px_rgba(52,211,153,0.45)]",
        pill: "bg-emerald-500/15 text-emerald-100 border border-emerald-400/25",
      };
    case "CANCELLED":
      return {
        label: "Đã hủy",
        dot: "bg-zinc-500",
        pill: "bg-zinc-500/20 text-zinc-300 border border-zinc-500/30",
      };
    default:
      return { label: s, dot: "bg-zinc-400", pill: "bg-white/10 text-zinc-200 border border-white/10" };
  }
}

function formatDay(iso: string): string {
  try {
    return new Date(iso).toLocaleDateString("vi-VN", {
      weekday: "long",
      day: "numeric",
      month: "long",
      year: "numeric",
    });
  } catch {
    return iso;
  }
}

function BookingCard({
  b,
  mockOnly,
  cancellingId,
  onCancel,
}: {
  b: WebBookingMine;
  mockOnly: boolean;
  cancellingId: string | null;
  onCancel: (id: string) => void;
}) {
  const meta = statusMeta(b.status);
  const canCancel = (b.status === "PENDING" || b.status === "CONFIRMED") && !mockOnly;

  return (
    <article className="group relative overflow-hidden rounded-2xl border border-white/[0.08] bg-gradient-to-br from-surface/95 to-surface/80 shadow-lg shadow-black/20 backdrop-blur-sm transition duration-300 hover:border-primary/25 hover:shadow-xl hover:shadow-primary/5">
      <div className="absolute left-0 top-0 h-full w-1 rounded-l-2xl bg-gradient-to-b from-primary via-primary/80 to-accent/90 opacity-90" />
      <div className="relative p-5 pl-6 sm:p-6 sm:pl-7">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
          <div className="min-w-0 flex-1 space-y-2">
            <h2 className="font-display text-xl font-semibold tracking-tight text-ocean-foreground md:text-[1.35rem]">
              {b.service.name}
            </h2>
            {b.service.provider?.name ? (
              <p className="flex items-center gap-2 text-sm text-muted-foreground">
                <span className="inline-flex h-6 w-6 shrink-0 items-center justify-center rounded-lg bg-white/5 text-sky-300/90">
                  <Tag className="h-3.5 w-3.5" aria-hidden />
                </span>
                <span className="truncate">{b.service.provider.name}</span>
              </p>
            ) : null}
            {b.combo ? (
              <div className="inline-flex max-w-full flex-wrap items-center gap-2 rounded-lg border border-sky-500/20 bg-sky-500/10 px-3 py-2 text-xs text-sky-100/95">
                <Sparkles className="h-3.5 w-3.5 shrink-0 text-sky-300" aria-hidden />
                <span>
                  Combo
                  {b.combo.title ? ` · ${b.combo.title}` : ""}
                  {b.combo.hotel && b.combo.food ? ` · ${b.combo.hotel.name} + ${b.combo.food.name}` : ""}
                </span>
              </div>
            ) : null}
          </div>
          <div
            className={`inline-flex shrink-0 items-center gap-2 self-start rounded-full px-3.5 py-1.5 text-xs font-medium ${meta.pill}`}
          >
            <span className={`h-2 w-2 rounded-full ${meta.dot}`} aria-hidden />
            {meta.label}
          </div>
        </div>

        <Separator className="my-5 bg-white/10" />

        <dl className="grid gap-4 sm:grid-cols-2">
          <div className="flex gap-3">
            <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-primary/15 text-primary">
              <CalendarDays className="h-5 w-5" aria-hidden />
            </div>
            <div>
              <dt className="text-xs font-medium uppercase tracking-wide text-muted-foreground/90">Ngày</dt>
              <dd className="mt-0.5 text-sm font-medium leading-snug text-ocean-foreground">{formatDay(b.date)}</dd>
            </div>
          </div>
          <div className="flex gap-3">
            <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-accent/15 text-accent">
              <User className="h-5 w-5" aria-hidden />
            </div>
            <div>
              <dt className="text-xs font-medium uppercase tracking-wide text-muted-foreground/90">Số lượng</dt>
              <dd className="mt-0.5 text-sm font-semibold text-ocean-foreground">{b.quantity}</dd>
            </div>
          </div>
          <div className="flex gap-3">
            <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-emerald-500/15 text-emerald-300">
              <Banknote className="h-5 w-5" aria-hidden />
            </div>
            <div>
              <dt className="text-xs font-medium uppercase tracking-wide text-muted-foreground/90">Thành tiền</dt>
              <dd className="mt-0.5 font-display text-lg font-semibold text-gradient-sunrise">
                {b.totalPrice.toLocaleString("vi-VN")} <span className="text-sm font-normal text-muted-foreground">VNĐ</span>
              </dd>
            </div>
          </div>
          <div className="flex gap-3 sm:col-span-2">
            <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-white/10 text-ocean-foreground/90">
              <Phone className="h-5 w-5" aria-hidden />
            </div>
            <div className="min-w-0 flex-1">
              <dt className="text-xs font-medium uppercase tracking-wide text-muted-foreground/90">Liên hệ trên đơn</dt>
              <dd className="mt-0.5 text-sm text-ocean-foreground">
                <span className="font-medium">{b.customerName}</span>
                <span className="text-muted-foreground"> · </span>
                <a href={`tel:${b.customerPhone.replace(/\s/g, "")}`} className="text-sky-300 underline-offset-2 hover:text-sky-200 hover:underline">
                  {b.customerPhone}
                </a>
              </dd>
            </div>
          </div>
        </dl>

        {b.customerNote ? (
          <div className="mt-5 rounded-xl border border-white/6 bg-black/20 px-4 py-3">
            <p className="text-xs font-medium uppercase tracking-wide text-muted-foreground/90">Ghi chú</p>
            <p className="mt-1.5 text-sm leading-relaxed text-ocean-foreground/90">{b.customerNote}</p>
          </div>
        ) : null}

        {canCancel ? (
          <div className="mt-5 flex flex-wrap items-center justify-end gap-2 border-t border-white/6 pt-4">
            <Button
              variant="outline"
              size="sm"
              className="border-rose-400/35 bg-rose-950/20 text-rose-100 transition hover:border-rose-400/55 hover:bg-rose-950/40"
              disabled={cancellingId === b.id}
              onClick={() => onCancel(b.id)}
            >
              {cancellingId === b.id ? "Đang xử lý…" : "Hủy đơn"}
            </Button>
          </div>
        ) : null}
      </div>
    </article>
  );
}

export default function MyBookings() {
  const { session, ready } = useAuth();
  const [statusFilter, setStatusFilter] = useState<MyBookingsStatusFilter>(null);
  const { data: rows, isLoading, isError, error, refetch } = useMyBookings(!!session, statusFilter);
  const cancelMu = useCancelMyBooking();
  const [cancellingId, setCancellingId] = useState<string | null>(null);

  if (!ready) {
    return (
      <div className="min-h-screen bg-ocean flex items-center justify-center">
        <div className="flex flex-col items-center gap-3">
          <Loader2 className="h-11 w-11 animate-spin text-primary" />
          <p className="text-sm text-muted-foreground">Đang tải…</p>
        </div>
      </div>
    );
  }

  if (!session) {
    return <Navigate to="/login?next=/don-cua-toi" replace />;
  }

  const list = rows ?? [];
  const mockOnly = import.meta.env.VITE_USE_MOCK === "true";

  async function onCancel(id: string) {
    if (!window.confirm("Bạn có chắc muốn hủy đơn này? (Đơn combo / nhiều phòng có thể hủy cả nhóm.)")) return;
    setCancellingId(id);
    try {
      await cancelMu.mutateAsync(id);
      toast.success("Đã gửi yêu cầu hủy");
    } catch (e) {
      toast.error(e instanceof Error ? e.message : "Không hủy được đơn");
    } finally {
      setCancellingId(null);
    }
  }

  return (
    <div className="relative min-h-screen bg-ocean">
      {/* Decor tách layer, pointer-events-none + z-0 để không chặn click lên nav/main */}
      <div
        className="pointer-events-none absolute inset-0 z-0 overflow-hidden"
        aria-hidden
      >
        <div className="absolute -left-32 top-0 h-72 w-72 rounded-full bg-primary/20 blur-[100px]" />
        <div className="absolute -right-20 top-40 h-64 w-64 rounded-full bg-accent/15 blur-[90px]" />
        <div className="absolute bottom-0 left-1/2 h-48 w-[min(100%,48rem)] -translate-x-1/2 rounded-full bg-secondary/10 blur-[80px]" />
      </div>

      <StickyNav />
      <main className="relative z-10 container max-w-3xl mx-auto px-4 pt-28 pb-20 pointer-events-auto">
        <motion.header
          initial={{ opacity: 0, y: -8 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.45, ease: [0.22, 1, 0.36, 1] }}
          className="mb-10 text-center sm:text-left"
        >
          <div className="inline-flex items-center gap-2 rounded-full border border-white/10 bg-white/5 px-3 py-1 text-xs font-medium text-ocean-foreground/80 backdrop-blur-sm">
            <PackageOpen className="h-3.5 w-3.5 text-primary" aria-hidden />
            Khách hàng
          </div>
          <h1 className="mt-4 font-display text-3xl font-bold tracking-tight md:text-4xl">
            <span className="text-gradient-sunrise">Đơn của tôi</span>
          </h1>
          <p className="mt-2 max-w-lg text-sm leading-relaxed text-muted-foreground md:text-base">
            Theo dõi trạng thái đặt chỗ và liên hệ đã ghi trên đơn. Bạn có thể hủy khi đơn còn ở trạng thái phù hợp.
          </p>
        </motion.header>

        {mockOnly && (
          <div className="mb-8 flex gap-3 rounded-2xl border border-amber-400/25 bg-amber-500/10 px-4 py-4 text-sm text-amber-50 backdrop-blur-sm">
            <Sparkles className="mt-0.5 h-5 w-5 shrink-0 text-amber-300" aria-hidden />
            <p>
              Đang bật <code className="rounded bg-black/25 px-1.5 py-0.5 text-xs">VITE_USE_MOCK=true</code> — không gọi API;
              danh sách trống.
            </p>
          </div>
        )}

        {!mockOnly ? (
          <motion.div
            initial={{ opacity: 0, y: 6 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.35 }}
            className="mb-8 flex flex-col gap-3 sm:flex-row sm:flex-wrap sm:items-center"
          >
            <span className="text-xs font-medium uppercase tracking-wide text-muted-foreground">Lọc theo trạng thái</span>
            <div className="flex flex-wrap gap-2">
              {STATUS_FILTERS.map((f) => {
                const active = statusFilter === f.value;
                return (
                  <button
                    key={f.label}
                    type="button"
                    onClick={() => setStatusFilter(f.value)}
                    className={`rounded-full border px-3.5 py-1.5 text-xs font-medium transition-colors ${
                      active
                        ? "border-primary/50 bg-primary/15 text-primary"
                        : "border-white/10 bg-surface/60 text-muted-foreground hover:border-white/20 hover:text-ocean-foreground"
                    }`}
                  >
                    {f.label}
                  </button>
                );
              })}
            </div>
          </motion.div>
        ) : null}

        {isLoading ? (
          <div className="space-y-4 py-6">
            {[1, 2, 3].map((i) => (
              <div
                key={i}
                className="h-40 animate-pulse rounded-2xl border border-white/5 bg-surface/40"
                style={{ animationDelay: `${i * 80}ms` }}
              />
            ))}
          </div>
        ) : isError ? (
          <div className="rounded-2xl border border-rose-400/25 bg-gradient-to-br from-rose-950/50 to-rose-950/20 p-8 text-center shadow-lg">
            <AlertCircle className="mx-auto h-12 w-12 text-rose-300/90" aria-hidden />
            <p className="mt-4 font-display text-lg font-semibold text-rose-100">Không tải được đơn</p>
            <p className="mt-2 text-sm text-rose-200/75">{error instanceof Error ? error.message : String(error)}</p>
            <Button
              variant="outline"
              className="mt-6 border-rose-400/40 text-rose-100 hover:bg-rose-950/50"
              onClick={() => void refetch()}
            >
              <RefreshCw className="mr-2 h-4 w-4" />
              Thử lại
            </Button>
          </div>
        ) : list.length === 0 ? (
          <motion.div
            initial={{ opacity: 0, scale: 0.98 }}
            animate={{ opacity: 1, scale: 1 }}
            className="rounded-2xl border border-white/10 bg-gradient-to-b from-surface/80 to-surface/40 px-8 py-16 text-center shadow-inner"
          >
            <div className="mx-auto flex h-20 w-20 items-center justify-center rounded-2xl border border-white/10 bg-gradient-to-br from-primary/20 to-accent/10 shadow-lg">
              <PackageOpen className="h-9 w-9 text-primary" strokeWidth={1.5} />
            </div>
            {statusFilter ? (
              <>
                <p className="mt-6 font-display text-xl font-semibold text-ocean-foreground">Không có đơn ở trạng thái này</p>
                <p className="mx-auto mt-2 max-w-sm text-sm text-muted-foreground">
                  Thử chọn trạng thái khác hoặc xem tất cả đơn.
                </p>
                <Button
                  type="button"
                  variant="outline"
                  className="mt-8 rounded-xl border-white/15"
                  onClick={() => setStatusFilter(null)}
                >
                  Xem tất cả đơn
                </Button>
              </>
            ) : (
              <>
                <p className="mt-6 font-display text-xl font-semibold text-ocean-foreground">Chưa có đơn nào</p>
                <p className="mx-auto mt-2 max-w-sm text-sm text-muted-foreground">
                  Khám phá dịch vụ và đặt chỗ — đơn sẽ hiện tại đây sau khi bạn đặt thành công.
                </p>
                <Button asChild className="mt-8 rounded-xl px-8 font-semibold shadow-lg shadow-primary/20">
                  <Link to={{ pathname: "/", hash: "#dich-vu" }}>Đặt dịch vụ</Link>
                </Button>
              </>
            )}
          </motion.div>
        ) : (
          <ul className="space-y-6">
            {list.map((b) => (
              <li key={b.id} className="list-none">
                <BookingCard
                  b={b}
                  mockOnly={mockOnly}
                  cancellingId={cancellingId}
                  onCancel={onCancel}
                />
              </li>
            ))}
          </ul>
        )}

        <motion.p
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.2 }}
          className="mt-14 flex justify-center"
        >
          <Link
            to="/"
            className="inline-flex items-center gap-2 text-sm font-medium text-muted-foreground transition hover:text-primary"
          >
            <ArrowLeft className="h-4 w-4" />
            Về trang chủ
          </Link>
        </motion.p>
      </main>
    </div>
  );
}
