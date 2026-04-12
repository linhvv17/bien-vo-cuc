import Link from "next/link";

import { LogoutButton } from "@/components/logout-button";
import { apiBase } from "@/lib/api";

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex min-h-screen bg-zinc-950 text-zinc-100">
      <aside className="w-64 border-r border-white/10 bg-zinc-950/60 backdrop-blur">
        <div className="px-4 py-4">
          <div className="text-lg font-semibold">Biển Vô Cực</div>
          <div className="text-xs text-zinc-400">Admin</div>
        </div>
        <nav className="px-2 py-2 text-sm">
          <NavItem href="/bookings">Đặt chỗ &amp; dashboard</NavItem>
          <NavItem href="/services">Dịch vụ (KS / Ăn uống)</NavItem>
          <NavItem href="/combos">Combo</NavItem>
          <NavItem href="/provider-accounts">Tài khoản NCC</NavItem>
          <NavItem href="/tides">Thủy triều</NavItem>
          <Link
            href="/login"
            className="mt-2 block rounded-md px-3 py-2 text-xs text-zinc-500 hover:text-zinc-300"
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
          <div className="text-sm text-zinc-300">Dashboard</div>
        </div>
        <div className="px-6 py-6">{children}</div>
      </main>
    </div>
  );
}

function NavItem({ href, children }: { href: string; children: React.ReactNode }) {
  return (
    <Link
      href={href}
      className="block rounded-md px-3 py-2 text-zinc-200 hover:bg-white/5 hover:text-white"
    >
      {children}
    </Link>
  );
}

