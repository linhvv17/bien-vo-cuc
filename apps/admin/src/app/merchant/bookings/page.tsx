"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useCallback, useEffect, useState } from "react";

import {
  BookingRequestCard,
  BOOKING_STATUSES,
  type BookingRequestRow,
} from "@/components/booking-request-card";
import { apiAuth, loadAuth, type AuthUser } from "@/lib/api";

type ListData = {
  items: BookingRequestRow[];
  total: number;
};

type MerchantStats = {
  total: number;
  byStatus: { pending: number; confirmed: number; cancelled: number };
};

const STATUS_FILTERS: { value: (typeof BOOKING_STATUSES)[number] | null; label: string }[] = [
  { value: null, label: "Tất cả" },
  { value: "PENDING", label: "Chờ xử lý" },
  { value: "CONFIRMED", label: "Đã xác nhận" },
  { value: "CANCELLED", label: "Đã hủy" },
];

export default function MerchantBookingsPage() {
  const router = useRouter();
  const [user, setUser] = useState<AuthUser | null>(null);
  const [token, setToken] = useState<string | null>(null);
  const [stats, setStats] = useState<MerchantStats | null>(null);
  const [list, setList] = useState<ListData | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [updating, setUpdating] = useState<string | null>(null);
  const [statusFilter, setStatusFilter] = useState<(typeof BOOKING_STATUSES)[number] | null>(null);

  const load = useCallback(async (t: string) => {
    setError(null);
    const params = new URLSearchParams({ take: "50" });
    if (statusFilter) params.set("status", statusFilter);
    const [s, l] = await Promise.all([
      apiAuth<MerchantStats>("/merchant/bookings/stats", t),
      apiAuth<ListData>(`/merchant/bookings?${params.toString()}`, t),
    ]);
    setStats(s.data);
    setList(l.data);
  }, [statusFilter]);

  useEffect(() => {
    const a = loadAuth();
    if (!a) {
      router.replace("/login?next=/merchant/bookings");
      return;
    }
    if (a.user.role !== "MERCHANT") {
      router.replace("/login");
      return;
    }
    if (!a.user.providerId) {
      setError("Tài khoản chưa gắn nhà cung cấp (provider). Liên hệ admin.");
      setUser(a.user);
      setToken(a.token);
      return;
    }
    setUser(a.user);
    setToken(a.token);
  }, [router]);

  useEffect(() => {
    if (!token || !user?.providerId) return;
    load(token).catch((e) => setError(e instanceof Error ? e.message : "Lỗi tải dữ liệu"));
  }, [token, user?.providerId, load]);

  async function patchStatus(
    id: string,
    status: (typeof BOOKING_STATUSES)[number],
    cancelMeta?: { preset: string; detail: string },
  ) {
    if (!token) return;
    setUpdating(id);
    setError(null);
    try {
      const body: Record<string, unknown> = { status };
      if (status === "CANCELLED" && cancelMeta) {
        body.merchantCancelPreset = cancelMeta.preset;
        body.merchantCancelDetail = cancelMeta.detail;
      }
      await apiAuth(`/merchant/bookings/${id}/status`, token, {
        method: "PATCH",
        body: JSON.stringify(body),
      });
      await load(token);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Cập nhật thất bại");
    } finally {
      setUpdating(null);
    }
  }

  if (!user || !token) {
    return (
      <div className="text-sm text-zinc-400">
        Đang kiểm tra phiên… <Link href="/login">Đăng nhập</Link>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-xl font-semibold text-white">Đặt chỗ — Nhà cung cấp</h1>
        <p className="text-sm text-zinc-400">
          {user.name} · {user.email} — đủ ảnh & ghi chú khách để chuẩn bị phòng / món kịp thời.
        </p>
      </div>

      {error ? <p className="text-sm text-rose-400">{error}</p> : null}

      {stats ? (
        <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
          <StatCard label="Tổng (dịch vụ của bạn)" value={stats.total} />
          <StatCard label="Chờ xử lý" value={stats.byStatus.pending} accent="amber" />
          <StatCard label="Đã xác nhận" value={stats.byStatus.confirmed} accent="emerald" />
          <StatCard label="Đã hủy" value={stats.byStatus.cancelled} accent="rose" />
        </div>
      ) : null}

      {user.providerId ? (
        <div className="flex flex-col gap-2 sm:flex-row sm:flex-wrap sm:items-center">
          <span className="text-xs font-medium text-zinc-500">Lọc theo trạng thái</span>
          <div className="flex flex-wrap gap-2">
            {STATUS_FILTERS.map((f) => {
              const active = statusFilter === f.value;
              return (
                <button
                  key={f.label}
                  type="button"
                  onClick={() => setStatusFilter(f.value)}
                  className={`rounded-full border px-3 py-1.5 text-xs font-medium transition-colors ${
                    active
                      ? "border-sky-500/60 bg-sky-500/15 text-sky-200"
                      : "border-white/10 bg-zinc-950 text-zinc-400 hover:border-white/20 hover:text-zinc-200"
                  }`}
                >
                  {f.label}
                </button>
              );
            })}
          </div>
        </div>
      ) : null}

      <div className="space-y-4">
        {(list?.items ?? []).map((b) => (
          <BookingRequestCard
            key={b.id}
            booking={b}
            merchantUi
            updating={updating === b.id}
            onStatusChange={patchStatus}
          />
        ))}
      </div>
      {list && list.total > list.items.length ? (
        <div className="text-xs text-zinc-500">
          Hiển thị {list.items.length} / {list.total}
          {statusFilter ? " (đã lọc)" : ""} — tối đa 50 mục mỗi lần tải
        </div>
      ) : null}
    </div>
  );
}

function StatCard({
  label,
  value,
  accent,
}: {
  label: string;
  value: number;
  accent?: "amber" | "emerald" | "rose";
}) {
  const ring =
    accent === "amber"
      ? "border-amber-500/30"
      : accent === "emerald"
        ? "border-emerald-500/30"
        : accent === "rose"
          ? "border-rose-500/30"
          : "border-white/10";
  return (
    <div className={`rounded-lg border bg-zinc-900/40 p-4 ${ring}`}>
      <div className="text-xs text-zinc-500">{label}</div>
      <div className="mt-1 text-2xl font-semibold text-white">{value}</div>
    </div>
  );
}
