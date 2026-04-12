import type { Metadata } from "next";
import Link from "next/link";

import { LogoutButton } from "@/components/logout-button";
import { apiBase } from "@/lib/api";

export const metadata: Metadata = {
  title: "Biển Vô Cực · NCC",
};

export default function MerchantLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex min-h-screen bg-zinc-950 text-zinc-100">
      <aside className="w-64 border-r border-white/10 bg-zinc-950/60 backdrop-blur">
        <div className="px-4 py-4">
          <div className="text-lg font-semibold">Biển Vô Cực</div>
          <div className="text-xs text-zinc-400">Nhà cung cấp</div>
        </div>
        <nav className="px-2 py-2 text-sm">
          <Link
            href="/merchant/bookings"
            className="block rounded-md px-3 py-2 text-zinc-200 hover:bg-white/5 hover:text-white"
          >
            Đặt chỗ của tôi
          </Link>
          <Link
            href="/login"
            className="mt-1 block rounded-md px-3 py-2 text-zinc-500 hover:text-zinc-300"
          >
            Đổi tài khoản
          </Link>
        </nav>
        <div className="px-4 py-4 text-xs text-zinc-500">
          <div>API: {apiBase()}</div>
          <div className="mt-2">
            <LogoutButton />
          </div>
        </div>
      </aside>
      <main className="flex-1">
        <div className="border-b border-white/10 px-6 py-4">
          <div className="text-sm text-zinc-300">Merchant</div>
        </div>
        <div className="px-6 py-6">{children}</div>
      </main>
    </div>
  );
}
