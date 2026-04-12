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

type ServiceTypeRow = {
  type: string;
  pending: number;
  confirmed: number;
  cancelled: number;
  total: number;
};

type AdminStats = {
  total: number;
  byStatus: { pending: number; confirmed: number; cancelled: number };
  byServiceType: { type: string; count: number }[];
  byServiceTypeDetail: ServiceTypeRow[];
};

/** Khớp enum `ServiceType` API */
const SERVICE_TYPES = ["ACCOMMODATION", "FOOD", "VEHICLE", "TOUR"] as const;

const SERVICE_TYPE_LABEL: Record<(typeof SERVICE_TYPES)[number], string> = {
  ACCOMMODATION: "Lưu trú",
  FOOD: "Ăn uống",
  VEHICLE: "Xe / vận chuyển",
  TOUR: "Tour / chụp ảnh",
};

const SERVICE_TYPE_FILTERS: { value: (typeof SERVICE_TYPES)[number] | null; label: string }[] = [
  { value: null, label: "Tất cả loại" },
  ...SERVICE_TYPES.map((t) => ({ value: t, label: SERVICE_TYPE_LABEL[t] })),
];

const STATUS_FILTERS: { value: (typeof BOOKING_STATUSES)[number] | null; label: string }[] = [
  { value: null, label: "Mọi trạng thái" },
  { value: "PENDING", label: "Chờ xử lý" },
  { value: "CONFIRMED", label: "Đã xác nhận" },
  { value: "CANCELLED", label: "Đã hủy" },
];

export default function AdminBookingsPage() {
  const router = useRouter();
  const [user, setUser] = useState<AuthUser | null>(null);
  const [token, setToken] = useState<string | null>(null);
  const [stats, setStats] = useState<AdminStats | null>(null);
  const [list, setList] = useState<ListData | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [updating, setUpdating] = useState<string | null>(null);
  const [serviceTypeFilter, setServiceTypeFilter] = useState<(typeof SERVICE_TYPES)[number] | null>(null);
  const [statusFilter, setStatusFilter] = useState<(typeof BOOKING_STATUSES)[number] | null>(null);

  const load = useCallback(
    async (t: string) => {
      setError(null);
      const params = new URLSearchParams({ take: "50" });
      if (statusFilter) params.set("status", statusFilter);
      if (serviceTypeFilter) params.set("serviceType", serviceTypeFilter);
      const [s, l] = await Promise.all([
        apiAuth<AdminStats>("/admin/bookings/stats", t),
        apiAuth<ListData>(`/admin/bookings?${params.toString()}`, t),
      ]);
      setStats(s.data);
      setList(l.data);
    },
    [statusFilter, serviceTypeFilter],
  );

  useEffect(() => {
    const a = loadAuth();
    if (!a) {
      router.replace("/login?next=/bookings");
      return;
    }
    if (a.user.role !== "ADMIN") {
      router.replace("/login");
      return;
    }
    setUser(a.user);
    setToken(a.token);
  }, [router]);

  useEffect(() => {
    if (!token) return;
    load(token).catch((e) => setError(e instanceof Error ? e.message : "Lỗi tải dữ liệu"));
  }, [token, load]);

  async function patchStatus(id: string, status: (typeof BOOKING_STATUSES)[number]) {
    if (!token) return;
    setUpdating(id);
    setError(null);
    try {
      await apiAuth(`/admin/bookings/${id}/status`, token, {
        method: "PATCH",
        body: JSON.stringify({ status }),
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
        <h1 className="text-xl font-semibold text-white">Đặt chỗ — Tổng quan</h1>
        <p className="text-sm text-zinc-400">
          Lọc theo loại dịch vụ và trạng thái; bảng dưới tóm tắt số đơn theo từng loại (chờ / đã xác nhận / đã hủy).
        </p>
      </div>

      {error ? <p className="text-sm text-rose-400">{error}</p> : null}

      {stats ? (
        <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
          <StatCard label="Tổng" value={stats.total} />
          <StatCard label="Chờ xử lý" value={stats.byStatus.pending} accent="amber" />
          <StatCard label="Đã xác nhận" value={stats.byStatus.confirmed} accent="emerald" />
          <StatCard label="Đã hủy" value={stats.byStatus.cancelled} accent="rose" />
        </div>
      ) : null}

      {stats?.byServiceTypeDetail?.length ? (
        <div className="overflow-x-auto rounded-lg border border-white/10 bg-zinc-900/40">
          <table className="w-full min-w-[520px] text-left text-sm">
            <thead>
              <tr className="border-b border-white/10 text-xs text-zinc-500">
                <th className="px-4 py-3 font-medium">Loại dịch vụ</th>
                <th className="px-4 py-3 font-medium text-amber-200/90">Chờ xử lý</th>
                <th className="px-4 py-3 font-medium text-emerald-200/90">Đã xác nhận</th>
                <th className="px-4 py-3 font-medium text-rose-200/90">Đã hủy</th>
                <th className="px-4 py-3 font-medium text-zinc-400">Tổng</th>
              </tr>
            </thead>
            <tbody>
              {stats.byServiceTypeDetail.map((row) => (
                <tr key={row.type} className="border-b border-white/5 text-zinc-200 last:border-0">
                  <td className="px-4 py-2.5 font-medium">
                    {SERVICE_TYPE_LABEL[row.type as (typeof SERVICE_TYPES)[number]] ?? row.type}
                  </td>
                  <td className="px-4 py-2.5 tabular-nums">{row.pending}</td>
                  <td className="px-4 py-2.5 tabular-nums">{row.confirmed}</td>
                  <td className="px-4 py-2.5 tabular-nums">{row.cancelled}</td>
                  <td className="px-4 py-2.5 tabular-nums text-zinc-400">{row.total}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : null}

      <div className="space-y-3 rounded-xl border border-white/10 bg-zinc-900/30 p-4">
        <div className="text-xs font-medium text-zinc-400">Lọc danh sách đơn</div>
        <div className="flex flex-col gap-3">
          <div className="flex flex-wrap items-center gap-2">
            <span className="text-xs text-zinc-500 w-full sm:w-auto">Loại dịch vụ</span>
            <div className="flex flex-wrap gap-2">
              {SERVICE_TYPE_FILTERS.map((f) => {
                const active = serviceTypeFilter === f.value;
                return (
                  <button
                    key={f.label}
                    type="button"
                    onClick={() => setServiceTypeFilter(f.value)}
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
          <div className="flex flex-wrap items-center gap-2">
            <span className="text-xs text-zinc-500 w-full sm:w-auto">Trạng thái</span>
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
                        ? "border-violet-500/60 bg-violet-500/15 text-violet-200"
                        : "border-white/10 bg-zinc-950 text-zinc-400 hover:border-white/20 hover:text-zinc-200"
                    }`}
                  >
                    {f.label}
                  </button>
                );
              })}
            </div>
          </div>
        </div>
      </div>

      <div className="space-y-4">
        {(list?.items ?? []).map((b) => (
          <BookingRequestCard
            key={b.id}
            booking={b}
            updating={updating === b.id}
            onStatusChange={patchStatus}
          />
        ))}
      </div>
      {list && list.total > list.items.length ? (
        <div className="text-xs text-zinc-500">
          Hiển thị {list.items.length} / {list.total}
          {serviceTypeFilter || statusFilter ? " (đã lọc)" : ""} — tối đa 50 mục mỗi lần tải
        </div>
      ) : null}
      {list && list.total === 0 ? (
        <p className="text-sm text-zinc-500">Không có đơn nào khớp bộ lọc.</p>
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
