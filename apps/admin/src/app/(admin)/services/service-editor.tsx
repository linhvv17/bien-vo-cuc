"use client";

import { useMemo, useState } from "react";

import { apiPost, apiUrl } from "@/lib/api";

type ServiceType = "ACCOMMODATION" | "FOOD" | "TOUR" | "VEHICLE";

export type ServiceItem = {
  id: string;
  type: ServiceType;
  name: string;
  description: string;
  price: number;
  maxCapacity: number;
  isActive: boolean;
  createdAt: string;
};

export function ServiceEditor({
  type,
  initialItems,
}: {
  type: ServiceType;
  initialItems: ServiceItem[];
}) {
  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState<ServiceItem | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const defaults = useMemo(
    () => ({
      type,
      name: "",
      description: "",
      price: 0,
      maxCapacity: 2,
      isActive: true,
    }),
    [type]
  );

  function startCreate() {
    setEditing(null);
    setError(null);
    setOpen(true);
  }

  function startEdit(item: ServiceItem) {
    setEditing(item);
    setError(null);
    setOpen(true);
  }

  async function onSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setBusy(true);
    setError(null);

    const form = new FormData(e.currentTarget);
    const payload = {
      type: String(form.get("type")) as ServiceType,
      name: String(form.get("name") ?? ""),
      description: String(form.get("description") ?? ""),
      price: Number(form.get("price") ?? 0),
      maxCapacity: Number(form.get("maxCapacity") ?? 1),
      isActive: String(form.get("isActive") ?? "true") === "true",
    };

    try {
      if (editing) {
        const res = await fetch(apiUrl(`/services/${editing.id}`), {
          method: "PUT",
          headers: { "Content-Type": "application/json", Accept: "application/json" },
          body: JSON.stringify(payload),
        });
        const json = await res.json();
        if (!res.ok || !json.success) throw new Error(json.message || "Update failed");
      } else {
        await apiPost("/services", {
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload),
        });
      }
      window.location.reload();
    } catch (err) {
      setError(String(err));
    } finally {
      setBusy(false);
    }
  }

  async function onDelete(item: ServiceItem) {
    if (!confirm(`Xóa (disable) \"${item.name}\"?`)) return;
    setBusy(true);
    setError(null);
    try {
      const res = await fetch(apiUrl(`/services/${item.id}`), {
        method: "DELETE",
        headers: { Accept: "application/json" },
      });
      const json = await res.json();
      if (!res.ok || !json.success) throw new Error(json.message || "Delete failed");
      window.location.reload();
    } catch (err) {
      setError(String(err));
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="space-y-3">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="text-xs text-zinc-500">
          Thao tác trực tiếp DB qua Backend API (MVP chưa có Auth).
        </div>
        <button
          onClick={startCreate}
          className="rounded-lg bg-white/10 px-4 py-2 text-sm font-medium text-white hover:bg-white/15"
        >
          + Thêm
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
              <th className="px-4 py-3">Tên</th>
              <th className="px-4 py-3">Giá</th>
              <th className="px-4 py-3">Sức chứa</th>
              <th className="px-4 py-3">Trạng thái</th>
              <th className="px-4 py-3 text-right">Actions</th>
            </tr>
          </thead>
          <tbody>
            {initialItems.map((s) => (
              <tr key={s.id} className="border-t border-white/10">
                <td className="px-4 py-3">
                  <div className="font-medium text-zinc-100">{s.name}</div>
                  <div className="text-xs text-zinc-400 line-clamp-2">{s.description}</div>
                </td>
                <td className="px-4 py-3 text-zinc-200">{formatVnd(s.price)}</td>
                <td className="px-4 py-3 text-zinc-200">{s.maxCapacity}</td>
                <td className="px-4 py-3">
                  {s.isActive ? (
                    <span className="rounded-full bg-emerald-500/15 px-2 py-1 text-xs text-emerald-200">
                      Active
                    </span>
                  ) : (
                    <span className="rounded-full bg-zinc-500/20 px-2 py-1 text-xs text-zinc-300">
                      Inactive
                    </span>
                  )}
                </td>
                <td className="px-4 py-3 text-right">
                  <div className="flex justify-end gap-2">
                    <button
                      disabled={busy}
                      onClick={() => startEdit(s)}
                      className="rounded-md bg-white/10 px-3 py-1.5 text-xs hover:bg-white/15 disabled:opacity-50"
                    >
                      Sửa
                    </button>
                    <button
                      disabled={busy}
                      onClick={() => onDelete(s)}
                      className="rounded-md bg-red-500/15 px-3 py-1.5 text-xs text-red-200 hover:bg-red-500/20 disabled:opacity-50"
                    >
                      Xóa
                    </button>
                  </div>
                </td>
              </tr>
            ))}
            {initialItems.length === 0 && (
              <tr>
                <td className="px-4 py-6 text-zinc-400" colSpan={5}>
                  Chưa có dữ liệu.
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
              <div className="text-lg font-semibold">{editing ? "Sửa dịch vụ" : "Thêm dịch vụ"}</div>
              <button onClick={() => setOpen(false)} className="rounded-md px-2 py-1 text-zinc-300 hover:bg-white/5">
                ✕
              </button>
            </div>
            <form className="mt-4 space-y-3" onSubmit={onSubmit}>
              <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
                <Field label="Type">
                  <select
                    name="type"
                    defaultValue={editing?.type ?? defaults.type}
                    className="w-full rounded-lg bg-white/5 px-3 py-2 outline-none ring-1 ring-white/10 focus:ring-white/20"
                  >
                    <option value="ACCOMMODATION">ACCOMMODATION</option>
                    <option value="FOOD">FOOD</option>
                    <option value="TOUR">TOUR</option>
                    <option value="VEHICLE">VEHICLE</option>
                  </select>
                </Field>
                <Field label="Active">
                  <select
                    name="isActive"
                    defaultValue={String(editing?.isActive ?? defaults.isActive)}
                    className="w-full rounded-lg bg-white/5 px-3 py-2 outline-none ring-1 ring-white/10 focus:ring-white/20"
                  >
                    <option value="true">true</option>
                    <option value="false">false</option>
                  </select>
                </Field>
              </div>

              <Field label="Name">
                <input
                  name="name"
                  required
                  defaultValue={editing?.name ?? defaults.name}
                  className="w-full rounded-lg bg-white/5 px-3 py-2 outline-none ring-1 ring-white/10 focus:ring-white/20"
                />
              </Field>

              <Field label="Description">
                <textarea
                  name="description"
                  required
                  defaultValue={editing?.description ?? defaults.description}
                  rows={3}
                  className="w-full rounded-lg bg-white/5 px-3 py-2 outline-none ring-1 ring-white/10 focus:ring-white/20"
                />
              </Field>

              <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
                <Field label="Price (VND)">
                  <input
                    name="price"
                    type="number"
                    min={0}
                    required
                    defaultValue={editing?.price ?? defaults.price}
                    className="w-full rounded-lg bg-white/5 px-3 py-2 outline-none ring-1 ring-white/10 focus:ring-white/20"
                  />
                </Field>
                <Field label="Max capacity">
                  <input
                    name="maxCapacity"
                    type="number"
                    min={1}
                    required
                    defaultValue={editing?.maxCapacity ?? defaults.maxCapacity}
                    className="w-full rounded-lg bg-white/5 px-3 py-2 outline-none ring-1 ring-white/10 focus:ring-white/20"
                  />
                </Field>
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
                  {busy ? "Đang lưu..." : "Lưu"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <label className="block">
      <div className="mb-1 text-xs text-zinc-400">{label}</div>
      {children}
    </label>
  );
}

function formatVnd(v: number) {
  try {
    return new Intl.NumberFormat("vi-VN").format(v) + " đ";
  } catch {
    return `${v} đ`;
  }
}

