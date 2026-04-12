/**
 * Base URL cho axios/fetch.
 * - Không set `VITE_API_BASE_URL`: dùng `/api` — dev: Vite proxy tới backend; prod: cần reverse proxy cùng origin hoặc set env.
 * - Có `VITE_API_BASE_URL`: gọi trực tiếp URL đó (bỏ qua proxy dev).
 */
export function getApiBaseUrl(): string {
  const u = import.meta.env.VITE_API_BASE_URL?.trim();
  if (u) return u.replace(/\/+$/, "");
  return "/api";
}

export function apiUrl(path: string): string {
  const base = getApiBaseUrl().replace(/\/$/, "");
  const clean = path.startsWith("/") ? path.slice(1) : path;
  return `${base}/${clean}`;
}
