import { AdminLoadError } from "@/components/admin-load-error";
import { apiGet, describeFetchFailure } from "@/lib/api";
import { SyncTidesButton } from "./sync-button";

type TideSchedule = {
  id: string;
  date: string;
  lowTime1: string;
  lowHeight1: number;
  lowTime2?: string | null;
  lowHeight2?: number | null;
  isGolden: boolean;
  note?: string | null;
};

export default async function TidesPage() {
  const today = new Date();
  const from = ymd(today);
  const to = ymd(new Date(today.getTime() + 6 * 86400_000));

  let data: TideSchedule[] = [];
  let loadError: string | null = null;
  try {
    const res = await apiGet<TideSchedule[]>(`/tides/range?from=${from}&to=${to}`);
    data = res.data;
  } catch (e) {
    loadError = describeFetchFailure(e);
  }

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-xl font-semibold">Thủy triều</h1>
          <p className="text-sm text-zinc-400">Xem 7 ngày, sync từ nguồn ngoài về DB</p>
        </div>
        <SyncTidesButton />
      </div>

      {loadError && <AdminLoadError message={loadError} />}

      <div className="rounded-xl border border-white/10 bg-white/5">
        <div className="overflow-x-auto">
          <table className="min-w-full text-sm">
            <thead className="text-left text-zinc-400">
              <tr className="border-t border-white/10">
                <th className="px-4 py-3">Ngày</th>
                <th className="px-4 py-3">Low 1</th>
                <th className="px-4 py-3">Low 2</th>
                <th className="px-4 py-3">Ghi chú</th>
              </tr>
            </thead>
            <tbody>
              {data.map((t) => (
                <tr key={t.id} className="border-t border-white/10">
                  <td className="px-4 py-3">
                    <div className="font-medium">{t.date.slice(0, 10)}</div>
                    {t.isGolden && (
                      <span className="mt-1 inline-block rounded-full bg-yellow-400/15 px-2 py-0.5 text-xs text-yellow-200">
                        Golden
                      </span>
                    )}
                  </td>
                  <td className="px-4 py-3 text-zinc-200">
                    {hm(t.lowTime1)} · {t.lowHeight1.toFixed(2)}m
                  </td>
                  <td className="px-4 py-3 text-zinc-200">
                    {t.lowTime2 && t.lowHeight2 != null ? `${hm(t.lowTime2)} · ${t.lowHeight2.toFixed(2)}m` : "—"}
                  </td>
                  <td className="px-4 py-3 text-zinc-400">{t.note ?? "—"}</td>
                </tr>
              ))}
              {data.length === 0 && (
                <tr>
                  <td className="px-4 py-6 text-zinc-400" colSpan={4}>
                    Chưa có dữ liệu.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}

function ymd(d: Date) {
  const y = String(d.getFullYear()).padStart(4, "0");
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
}

function hm(iso: string) {
  const d = new Date(iso);
  const h = String(d.getHours()).padStart(2, "0");
  const m = String(d.getMinutes()).padStart(2, "0");
  return `${h}:${m}`;
}

