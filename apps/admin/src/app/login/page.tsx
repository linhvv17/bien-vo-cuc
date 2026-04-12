"use client";

import { useRouter, useSearchParams } from "next/navigation";
import { FormEvent, Suspense, useState } from "react";

import { loginRequest, saveAuth } from "@/lib/api";

function LoginForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const next = searchParams.get("next") ?? "";

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      const { accessToken, user } = await loginRequest(email, password);
      saveAuth(accessToken, user);

      if (next && next.startsWith("/")) {
        router.replace(next);
        return;
      }
      if (user.role === "ADMIN") {
        router.replace("/bookings");
      } else if (user.role === "MERCHANT") {
        router.replace("/merchant/bookings");
      } else {
        router.replace("/services");
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : "Đăng nhập thất bại");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="w-full max-w-sm rounded-xl border border-white/10 bg-zinc-900/60 p-6 shadow-xl backdrop-blur">
      <h1 className="text-lg font-semibold">Biển Vô Cực</h1>
      <p className="mt-1 text-sm text-zinc-400">Đăng nhập Admin / Nhà cung cấp</p>

      <form onSubmit={onSubmit} className="mt-6 space-y-4">
        <div>
          <label className="block text-xs text-zinc-400">Email hoặc tên đăng nhập (NCC)</label>
          <input
            type="text"
            autoComplete="username"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="mt-1 w-full rounded-md border border-white/10 bg-zinc-950 px-3 py-2 text-sm outline-none focus:border-sky-500/60"
            required
          />
        </div>
        <div>
          <label className="block text-xs text-zinc-400">Mật khẩu</label>
          <input
            type="password"
            autoComplete="current-password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            className="mt-1 w-full rounded-md border border-white/10 bg-zinc-950 px-3 py-2 text-sm outline-none focus:border-sky-500/60"
            required
          />
        </div>
        {error ? <p className="text-sm text-rose-400">{error}</p> : null}
        <button
          type="submit"
          disabled={loading}
          className="w-full rounded-md bg-sky-600 py-2 text-sm font-medium text-white hover:bg-sky-500 disabled:opacity-50"
        >
          {loading ? "Đang đăng nhập…" : "Đăng nhập"}
        </button>
      </form>
      <p className="mt-4 text-xs text-zinc-500">
        Demo: admin@bienvocuc.local / demo1234 — NCC: tên đăng nhập (không @) hoặc email đã gắn với tài khoản.
      </p>
    </div>
  );
}

export default function LoginPage() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-zinc-950 px-4 text-zinc-100">
      <Suspense
        fallback={
          <div className="w-full max-w-sm rounded-xl border border-white/10 bg-zinc-900/60 p-6 text-sm text-zinc-400">
            Đang tải…
          </div>
        }
      >
        <LoginForm />
      </Suspense>
    </div>
  );
}
