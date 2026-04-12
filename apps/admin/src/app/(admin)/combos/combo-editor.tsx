"use client";

import { useMemo, useState } from "react";

import { apiPost, apiUrl } from "@/lib/api";

type ServiceItem = {
  id: string;
  type: "ACCOMMODATION" | "FOOD" | "TOUR" | "VEHICLE";
  name: string;
  price: number;
  isActive: boolean;
};

type Combo = {
  id: string;
  title?: string | null;
  discountPercent: number;
  isActive: boolean;
  hotel: ServiceItem;
  food: ServiceItem;
  createdAt: string;
};

export function ComboEditor({
  combos,
  hotels,
  foods,
}: {
  combos: Combo[];
  hotels: ServiceItem[];
  foods: ServiceItem[];
}) {
  const [open, setOpen] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [editId, setEditId] = useState<string | null>(null);

  const defaults = useMemo(
    () => ({
      hotelServiceId: hotels[0]?.id ?? "",
      foodServiceId: foods[0]?.id ?? "",
      title: "",
      discountPercent: 10,
    }),
    [hotels, foods]
  );

  async function onCreate(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setBusy(true);
    setError(null);
    try {
      const fd = new FormData(e.currentTarget);
      const payload = {
        hotelServiceId: String(fd.get("hotelServiceId")),
        foodServiceId: String(fd.get("foodServiceId")),
        title: String(fd.get("title") ?? ""),
        discountPercent: Number(fd.get("discountPercent") ?? 10),
      };
      await apiPost("/combos", {
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });
      window.location.reload();
    } catch (e) {
      setError(String(e));
    } finally {
      setBusy(false);
    }
  }

  async function onUpdate(id: string, discountPercent: number) {
    setBusy(true);
    setError(null);
    try {
      const res = await fetch(apiUrl(`/combos/${id}`), {
        method: "PUT",
        headers: { "Content-Type": "application/json", Accept: "application/json" },
        body: JSON.stringify({ discountPercent }),
      });
      const json = await res.json();
      if (!res.ok || !json.success) throw new Error(json.message || "Update failed");
      window.location.reload();
    } catch (e) {
      setError(String(e));
    } finally {
      setBusy(false);
    }
  }

  async function onDelete(id: string) {
    if (!confirm("Disable combo này?")) return;
    setBusy(true);
    setError(null);
    try {
      const res = await fetch(apiUrl(`/combos/${id}`), {
        method: "DELETE",
        headers: { Accept: "application/json" },
      });
      const json = await res.json();
      if (!res.ok || !json.success) throw new Error(json.message || "Delete failed");
      window.location.reload();
    } catch (e) {
      setError(String(e));
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="space-y-3">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="text-xs text-zinc-500">Combo ghép từ 2 đầu mối độc lập (hotel + food).</div>
        <button
          onClick={() => {
            setOpen(true);
            setEditId(null);
          }}
          className="rounded-lg bg-white/10 px-4 py-2 text-sm font-medium text-white hover:bg-white/15"
        >
          + Tạo combo
        </button>
      </div>

      {error && (
        <div className="rounded-lg border border-red-500/30 bg-red-500/10 px-3 py-2 text-sm text-red-200">
          {error}
        </div>
      )}

      <div className="overflow-x-auto rounded-xl border border-white/10 bg-white/5">
        <table className="min-w-full text-sm">
          <thead className="text-left text-zinc-400">
            <tr className="border-t border-white/10">
              <th className="px-4 py-3">Combo</th>
              <th className="px-4 py-3">Discount</th>
              <th className="px-4 py-3 text-right">Actions</th>
            </tr>
          </thead>
          <tbody>
            {combos.map((c) => (
              <tr key={c.id} className="border-t border-white/10 align-top">
                <td className="px-4 py-3">
                  <div className="font-medium text-zinc-100">{c.title || "Combo"}</div>
                  <div className="text-xs text-zinc-400">
                    KS: {c.hotel.name} ({formatVnd(c.hotel.price)}) • Ăn: {c.food.name} ({formatVnd(c.food.price)})
                  </div>
                </td>
                <td className="px-4 py-3">
                  {editId === c.id ? (
                    <div className="flex items-center gap-2">
                      <input
                        type="number"
                        min={0}
                        max={100}
                        defaultValue={c.discountPercent}
                        id={`disc_${c.id}`}
                        className="w-24 rounded-md bg-white/5 px-2 py-1 ring-1 ring-white/10"
                      />
                      <button
                        disabled={busy}
                        onClick={() => {
                          const el = document.getElementById(`disc_${c.id}`) as HTMLInputElement | null;
                          const v = Number(el?.value ?? c.discountPercent);
                          onUpdate(c.id, v);
                        }}
                        className="rounded-md bg-white/10 px-3 py-1.5 text-xs hover:bg-white/15 disabled:opacity-50"
                      >
                        Lưu
                      </button>
                      <button
                        onClick={() => setEditId(null)}
                        className="rounded-md bg-white/5 px-3 py-1.5 text-xs hover:bg-white/10"
                      >
                        Hủy
                      </button>
                    </div>
                  ) : (
                    <span className="rounded-full bg-yellow-400/15 px-2 py-1 text-xs text-yellow-200">
                      {c.discountPercent}%
                    </span>
                  )}
                </td>
                <td className="px-4 py-3 text-right">
                  <div className="flex justify-end gap-2">
                    <button
                      disabled={busy}
                      onClick={() => setEditId(c.id)}
                      className="rounded-md bg-white/10 px-3 py-1.5 text-xs hover:bg-white/15 disabled:opacity-50"
                    >
                      Sửa discount
                    </button>
                    <button
                      disabled={busy}
                      onClick={() => onDelete(c.id)}
                      className="rounded-md bg-red-500/15 px-3 py-1.5 text-xs text-red-200 hover:bg-red-500/20 disabled:opacity-50"
                    >
                      Disable
                    </button>
                  </div>
                </td>
              </tr>
            ))}
            {combos.length === 0 && (
              <tr>
                <td className="px-4 py-6 text-zinc-400" colSpan={3}>
                  Chưa có combo.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {open && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4">
          <div className="w-full max-w-xl rounded-2xl border border-white/10 bg-zinc-950 p-4">
            <div className="flex items-center justify-between">
              <div className="text-lg font-semibold">Tạo combo</div>
              <button onClick={() => setOpen(false)} className="rounded-md px-2 py-1 text-zinc-300 hover:bg-white/5">
                ✕
              </button>
            </div>
            <form className="mt-4 space-y-3" onSubmit={onCreate}>
              <label className="block">
                <div className="mb-1 text-xs text-zinc-400">Khách sạn</div>
                <select
                  name="hotelServiceId"
                  defaultValue={defaults.hotelServiceId}
                  className="w-full rounded-lg bg-white/5 px-3 py-2 outline-none ring-1 ring-white/10 focus:ring-white/20"
                >
                  {hotels.map((h) => (
                    <option key={h.id} value={h.id}>
                      {h.name} ({formatVnd(h.price)})
                    </option>
                  ))}
                </select>
              </label>

              <label className="block">
                <div className="mb-1 text-xs text-zinc-400">Ăn uống</div>
                <select
                  name="foodServiceId"
                  defaultValue={defaults.foodServiceId}
                  className="w-full rounded-lg bg-white/5 px-3 py-2 outline-none ring-1 ring-white/10 focus:ring-white/20"
                >
                  {foods.map((f) => (
                    <option key={f.id} value={f.id}>
                      {f.name} ({formatVnd(f.price)})
                    </option>
                  ))}
                </select>
              </label>

              <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
                <label className="block">
                  <div className="mb-1 text-xs text-zinc-400">Title (optional)</div>
                  <input
                    name="title"
                    defaultValue={defaults.title}
                    className="w-full rounded-lg bg-white/5 px-3 py-2 outline-none ring-1 ring-white/10 focus:ring-white/20"
                  />
                </label>

                <label className="block">
                  <div className="mb-1 text-xs text-zinc-400">Discount %</div>
                  <input
                    name="discountPercent"
                    type="number"
                    min={0}
                    max={100}
                    defaultValue={defaults.discountPercent}
                    className="w-full rounded-lg bg-white/5 px-3 py-2 outline-none ring-1 ring-white/10 focus:ring-white/20"
                  />
                </label>
              </div>

              <div className="flex items-center justify-end gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setOpen(false)}
                  className="rounded-lg bg-white/5 px-4 py-2 text-sm text-zinc-200 hover:bg-white/10"
                >
                  Hủy
                </button>
                <button
                  disabled={busy}
                  type="submit"
                  className="rounded-lg bg-white/10 px-4 py-2 text-sm font-medium text-white hover:bg-white/15 disabled:opacity-50"
                >
                  {busy ? "Đang tạo..." : "Tạo"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}

function formatVnd(v: number) {
  try {
    return new Intl.NumberFormat("vi-VN").format(v) + " đ";
  } catch {
    return `${v} đ`;
  }
}

