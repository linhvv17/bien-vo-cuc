"use client";

import { useState } from "react";

import { apiPost } from "@/lib/api";

export function SyncTidesButton() {
  const [loading, setLoading] = useState(false);
  const [msg, setMsg] = useState<string | null>(null);

  async function onClick() {
    setLoading(true);
    setMsg(null);
    try {
      const res = await apiPost<{ upserted: number; skipped: number }>("/sync/tides");
      setMsg(`OK · upserted=${res.data.upserted} skipped=${res.data.skipped}`);
      // Best effort refresh by reloading page.
      window.location.reload();
    } catch (e) {
      const text = e instanceof Error ? e.message : String(e);
      setMsg(text);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="flex items-center gap-3">
      <button
        onClick={onClick}
        disabled={loading}
        className="rounded-lg bg-white/10 px-4 py-2 text-sm font-medium text-white hover:bg-white/15 disabled:opacity-50"
      >
        {loading ? "Đang sync..." : "Sync ngay"}
      </button>
      {msg ? (
        <span
          className={`text-xs max-w-xl ${msg.startsWith("OK") ? "text-emerald-400" : "text-rose-400"}`}
        >
          {msg}
        </span>
      ) : null}
    </div>
  );
}

