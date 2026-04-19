"use client";

import { useCallback, useEffect, useState } from "react";

import { apiUrl } from "@/lib/api";

const ROOM_TYPES = [
  "SINGLE",
  "DOUBLE",
  "TWIN",
  "FAMILY",
  "DORM",
  "SUITE",
  "QUAD",
] as const;

export type AdminRoom = {
  id: string;
  serviceId: string;
  code: string;
  name: string;
  roomType: string;
  maxGuests: number;
  floor: number | null;
  sortOrder: number;
  pricePerNight: number | null;
  isActive: boolean;
  images: string[];
};

function formatVnd(v: number) {
  try {
    return new Intl.NumberFormat("vi-VN").format(v) + " đ";
  } catch {
    return `${v} đ`;
  }
}

export function AccommodationRoomsPanel({
  serviceId,
  serviceName,
  basePriceVnd,
  onClose,
}: {
  serviceId: string;
  serviceName: string;
  basePriceVnd: number;
  onClose: () => void;
}) {
  const [rooms, setRooms] = useState<AdminRoom[]>([]);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoadError(null);
    try {
      const res = await fetch(apiUrl(`/services/${serviceId}/rooms`), {
        headers: { Accept: "application/json" },
      });
      const json = (await res.json()) as { success?: boolean; data?: AdminRoom[]; message?: string };
      if (!res.ok || !json.success) throw new Error(json.message || "Không tải được danh sách phòng");
      setRooms(json.data ?? []);
    } catch (e) {
      setLoadError(String(e));
    }
  }, [serviceId]);

  useEffect(() => {
    void load();
  }, [load]);

  async function onCreate(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setFormError(null);
    setBusy(true);
    const fd = new FormData(e.currentTarget);
    const priceRaw = String(fd.get("pricePerNight") ?? "").trim();
    const payload: Record<string, unknown> = {
      code: String(fd.get("code") ?? "").trim(),
      name: String(fd.get("name") ?? "").trim(),
      roomType: String(fd.get("roomType") ?? "DOUBLE"),
      maxGuests: Number(fd.get("maxGuests") ?? 2),
      sortOrder: Number(fd.get("sortOrder") ?? 0),
    };
    const floorRaw = String(fd.get("floor") ?? "").trim();
    if (floorRaw !== "") payload.floor = Number(floorRaw);
    if (priceRaw !== "") payload.pricePerNight = Number(priceRaw);
    try {
      const res = await fetch(apiUrl(`/services/${serviceId}/rooms`), {
        method: "POST",
        headers: { "Content-Type": "application/json", Accept: "application/json" },
        body: JSON.stringify(payload),
      });
      const json = (await res.json()) as { success?: boolean; message?: string };
      if (!res.ok || !json.success) throw new Error(json.message || "Tạo phòng thất bại");
      e.currentTarget.reset();
      await load();
    } catch (err) {
      setFormError(String(err));
    } finally {
      setBusy(false);
    }
  }

  async function toggleActive(room: AdminRoom) {
    if (!confirm(room.isActive ? "Ẩn phòng này? (soft delete)" : "Bật lại phòng?")) return;
    setBusy(true);
    setFormError(null);
    try {
      const res = await fetch(apiUrl(`/services/${serviceId}/rooms/${room.id}`), {
        method: "PUT",
        headers: { "Content-Type": "application/json", Accept: "application/json" },
        body: JSON.stringify({ isActive: !room.isActive }),
      });
      const json = (await res.json()) as { success?: boolean; message?: string };
      if (!res.ok || !json.success) throw new Error(json.message || "Cập nhật thất bại");
      await load();
    } catch (err) {
      setFormError(String(err));
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="fixed inset-0 z-[60] flex items-center justify-center bg-black/70 p-4">
      <div className="flex max-h-[90vh] w-full max-w-3xl flex-col overflow-hidden rounded-2xl border border-white/10 bg-zinc-950 shadow-xl">
        <div className="flex shrink-0 items-start justify-between gap-3 border-b border-white/10 px-4 py-3">
          <div>
            <div className="text-lg font-semibold text-white">Phòng — {serviceName}</div>
            <p className="mt-1 text-xs text-zinc-400">
              Giá cơ sở (khi để trống giá phòng): <span className="font-semibold text-zinc-200">{formatVnd(basePriceVnd)}</span>{" "}
              / đêm. Mỗi phòng = 1 inventory; khách đặt theo loại phòng (giống OTA).
            </p>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="rounded-md px-2 py-1 text-zinc-300 hover:bg-white/5"
          >
            ✕
          </button>
        </div>

        <div className="min-h-0 flex-1 overflow-y-auto px-4 py-3">
          {loadError && (
            <div className="mb-3 rounded-lg border border-red-500/30 bg-red-500/10 px-3 py-2 text-sm text-red-200">{loadError}</div>
          )}
          {formError && (
            <div className="mb-3 rounded-lg border border-amber-500/30 bg-amber-500/10 px-3 py-2 text-sm text-amber-100">{formError}</div>
          )}

          <div className="overflow-x-auto rounded-xl border border-white/10">
            <table className="min-w-full text-sm">
              <thead className="text-left text-zinc-400">
                <tr className="border-b border-white/10">
                  <th className="px-3 py-2">Mã</th>
                  <th className="px-3 py-2">Tên</th>
                  <th className="px-3 py-2">Loại</th>
                  <th className="px-3 py-2">Max khách</th>
                  <th className="px-3 py-2">Giá/đêm</th>
                  <th className="px-3 py-2">Trạng thái</th>
                  <th className="px-3 py-2 text-right">Thao tác</th>
                </tr>
              </thead>
              <tbody>
                {rooms.map((r) => (
                  <tr key={r.id} className="border-t border-white/10">
                    <td className="px-3 py-2 font-mono text-zinc-200">{r.code}</td>
                    <td className="px-3 py-2 text-zinc-100">{r.name}</td>
                    <td className="px-3 py-2 text-zinc-300">{r.roomType}</td>
                    <td className="px-3 py-2 text-zinc-300">{r.maxGuests}</td>
                    <td className="px-3 py-2 text-zinc-200">
                      {r.pricePerNight != null ? formatVnd(r.pricePerNight) : <span className="text-zinc-500">(theo cơ sở)</span>}
                    </td>
                    <td className="px-3 py-2">
                      {r.isActive ? (
                        <span className="rounded-full bg-emerald-500/15 px-2 py-0.5 text-xs text-emerald-200">Hiển thị</span>
                      ) : (
                        <span className="rounded-full bg-zinc-500/25 px-2 py-0.5 text-xs text-zinc-400">Đã ẩn</span>
                      )}
                    </td>
                    <td className="px-3 py-2 text-right">
                      <button
                        type="button"
                        disabled={busy}
                        onClick={() => void toggleActive(r)}
                        className="rounded-md bg-white/10 px-2 py-1 text-xs hover:bg-white/15 disabled:opacity-50"
                      >
                        {r.isActive ? "Ẩn" : "Bật"}
                      </button>
                    </td>
                  </tr>
                ))}
                {rooms.length === 0 && !loadError && (
                  <tr>
                    <td className="px-3 py-6 text-zinc-500" colSpan={7}>
                      Chưa có phòng. Thêm phòng bên dưới — không có phòng thì app chỉ đặt theo giá cơ sở (legacy).
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>

          <form className="mt-4 space-y-2 rounded-xl border border-white/10 bg-white/[0.03] p-3" onSubmit={onCreate}>
            <div className="text-sm font-semibold text-zinc-200">Thêm phòng</div>
            <div className="grid grid-cols-1 gap-2 sm:grid-cols-2 lg:grid-cols-3">
              <label className="block text-xs text-zinc-400">
                Mã phòng *
                <input
                  name="code"
                  required
                  placeholder="101"
                  className="mt-1 w-full rounded-lg bg-white/5 px-2 py-1.5 text-sm text-white outline-none ring-1 ring-white/10"
                />
              </label>
              <label className="block text-xs text-zinc-400">
                Tên *
                <input
                  name="name"
                  required
                  placeholder="Phòng đôi ban công"
                  className="mt-1 w-full rounded-lg bg-white/5 px-2 py-1.5 text-sm text-white outline-none ring-1 ring-white/10"
                />
              </label>
              <label className="block text-xs text-zinc-400">
                Loại *
                <select
                  name="roomType"
                  className="mt-1 w-full rounded-lg bg-white/5 px-2 py-1.5 text-sm text-white outline-none ring-1 ring-white/10"
                >
                  {ROOM_TYPES.map((t) => (
                    <option key={t} value={t}>
                      {t}
                    </option>
                  ))}
                </select>
              </label>
              <label className="block text-xs text-zinc-400">
                Số khách tối đa *
                <input
                  name="maxGuests"
                  type="number"
                  min={1}
                  max={20}
                  defaultValue={2}
                  className="mt-1 w-full rounded-lg bg-white/5 px-2 py-1.5 text-sm text-white outline-none ring-1 ring-white/10"
                />
              </label>
              <label className="block text-xs text-zinc-400">
                Giá/đêm (VND, tuỳ chọn)
                <input
                  name="pricePerNight"
                  type="number"
                  min={0}
                  placeholder={`Trống = ${basePriceVnd}`}
                  className="mt-1 w-full rounded-lg bg-white/5 px-2 py-1.5 text-sm text-white outline-none ring-1 ring-white/10"
                />
              </label>
              <label className="block text-xs text-zinc-400">
                Thứ tự
                <input
                  name="sortOrder"
                  type="number"
                  defaultValue={0}
                  className="mt-1 w-full rounded-lg bg-white/5 px-2 py-1.5 text-sm text-white outline-none ring-1 ring-white/10"
                />
              </label>
              <label className="block text-xs text-zinc-400">
                Tầng (tuỳ chọn)
                <input name="floor" type="number" className="mt-1 w-full rounded-lg bg-white/5 px-2 py-1.5 text-sm text-white outline-none ring-1 ring-white/10" />
              </label>
            </div>
            <button
              type="submit"
              disabled={busy}
              className="rounded-lg bg-emerald-600/80 px-4 py-2 text-sm font-medium text-white hover:bg-emerald-600 disabled:opacity-50"
            >
              {busy ? "Đang lưu…" : "Thêm phòng"}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
}
