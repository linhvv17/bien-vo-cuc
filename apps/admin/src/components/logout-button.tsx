"use client";

import { useRouter } from "next/navigation";

import { clearAuth } from "@/lib/api";

export function LogoutButton() {
  const router = useRouter();

  return (
    <button
      type="button"
      onClick={() => {
        clearAuth();
        router.push("/login");
      }}
      className="text-xs text-zinc-400 underline-offset-2 hover:text-white hover:underline"
    >
      Đăng xuất
    </button>
  );
}
