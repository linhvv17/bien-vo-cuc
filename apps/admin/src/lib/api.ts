export type ApiResponse<T> = {
  success: boolean;
  data: T;
  message: string;
  meta?: Record<string, unknown>;
};

export function apiBase() {
  const fromBase = process.env.NEXT_PUBLIC_API_BASE_URL?.trim();
  if (fromBase) return fromBase.replace(/\/+$/, "");
  const legacy = process.env.NEXT_PUBLIC_API_URL?.trim();
  if (legacy) return legacy.replace(/\/+$/, "");
  return "http://127.0.0.1:3001";
}

export function apiUrl(path: string) {
  const base = apiBase();
  return `${base}${path.startsWith("/") ? "" : "/"}${path}`;
}

/** Gợi ý thân thiện khi fetch lỗi (ECONNREFUSED / backend tắt). Dùng trong catch của Server Component. */
export function describeFetchFailure(e: unknown): string {
  if (isConnectionRefused(e)) {
    return `Không kết nối được backend tại ${apiBase()}. Mở terminal khác và chạy: cd apps/api && npm run start:dev`;
  }
  if (e instanceof Error) return e.message;
  return String(e);
}

function isConnectionRefused(e: unknown, depth = 0): boolean {
  if (depth > 6 || e == null || typeof e !== "object") return false;
  const any = e as { code?: string; cause?: unknown; errors?: unknown[] };
  if (any.code === "ECONNREFUSED") return true;
  if (any.cause != null && isConnectionRefused(any.cause, depth + 1)) return true;
  if (Array.isArray(any.errors) && any.errors.some((x) => isConnectionRefused(x, depth + 1))) return true;
  return false;
}

async function fetchApi(path: string, init?: RequestInit): Promise<Response> {
  return fetch(apiUrl(path), init);
}

export async function apiGet<T>(path: string, init?: RequestInit): Promise<ApiResponse<T>> {
  const res = await fetchApi(path, {
    ...init,
    headers: {
      Accept: "application/json",
      ...(init?.headers ?? {}),
    },
    cache: "no-store",
  });
  const json = (await res.json()) as ApiResponse<T>;
  if (!res.ok || !json.success) {
    throw new Error(json?.message || `Request failed: ${res.status}`);
  }
  return json;
}

export async function apiPost<T>(path: string, init?: RequestInit): Promise<ApiResponse<T>> {
  const res = await fetchApi(path, {
    method: "POST",
    ...init,
    headers: {
      Accept: "application/json",
      ...(init?.headers ?? {}),
    },
    cache: "no-store",
  });
  const json = (await res.json()) as ApiResponse<T>;
  if (!res.ok || !json.success) {
    throw new Error(json?.message || `Request failed: ${res.status}`);
  }
  return json;
}

export type AuthUser = {
  id: string;
  email: string;
  name: string;
  role: string;
  userKind: string;
  providerId: string | null;
};

export type LoginPayload = {
  accessToken: string;
  user: AuthUser;
};

const AUTH_KEY = "bvc_auth";

export function loadAuth(): { token: string; user: AuthUser } | null {
  if (typeof window === "undefined") return null;
  try {
    const raw = localStorage.getItem(AUTH_KEY);
    if (!raw) return null;
    return JSON.parse(raw) as { token: string; user: AuthUser };
  } catch {
    return null;
  }
}

export function saveAuth(token: string, user: AuthUser) {
  localStorage.setItem(AUTH_KEY, JSON.stringify({ token, user }));
}

export function clearAuth() {
  localStorage.removeItem(AUTH_KEY);
}

export async function loginRequest(email: string, password: string): Promise<LoginPayload> {
  const res = await fetchApi("/auth/login", {
    method: "POST",
    headers: { Accept: "application/json", "Content-Type": "application/json" },
    body: JSON.stringify({ identifier: email.trim(), password }),
    cache: "no-store",
  });
  const json = (await res.json()) as ApiResponse<LoginPayload>;
  if (!res.ok || !json.success || !json.data) {
    throw new Error(json.message || `Login failed: ${res.status}`);
  }
  return json.data;
}

export type ProviderRow = { id: string; name: string; phone: string | null };

export async function listProvidersForAdmin(token: string): Promise<ProviderRow[]> {
  const res = await apiAuth<ProviderRow[]>("/admin/providers", token, { method: "GET" });
  return res.data;
}

export type ProviderAccountRow = {
  id: string;
  username: string;
  email: string;
  name: string;
  providerId: string | null;
  providerName: string | null;
  createdAt: string;
};

export async function listProviderAccounts(token: string): Promise<ProviderAccountRow[]> {
  const res = await apiAuth<ProviderAccountRow[]>("/admin/provider-accounts", token, { method: "GET" });
  return res.data;
}

export type CreatedProviderAccount = {
  id: string;
  username: string;
  email: string;
  name: string;
  role: string;
  userKind: string;
  providerId: string | null;
};

export async function createProviderAccount(
  token: string,
  body: { username: string; password: string; providerId: string; name?: string },
): Promise<CreatedProviderAccount> {
  const res = await apiAuth<CreatedProviderAccount>("/admin/provider-accounts", token, {
    method: "POST",
    body: JSON.stringify(body),
  });
  return res.data;
}

export async function updateProviderAccount(
  token: string,
  id: string,
  body: { username?: string; name?: string; providerId?: string; password?: string },
): Promise<CreatedProviderAccount> {
  const res = await apiAuth<CreatedProviderAccount>(`/admin/provider-accounts/${id}`, token, {
    method: "PATCH",
    body: JSON.stringify(body),
  });
  return res.data;
}

export async function deleteProviderAccount(token: string, id: string): Promise<{ id: string }> {
  const res = await apiAuth<{ id: string }>(`/admin/provider-accounts/${id}`, token, {
    method: "DELETE",
  });
  return res.data;
}

export async function apiAuth<T>(
  path: string,
  token: string,
  init?: RequestInit,
): Promise<ApiResponse<T>> {
  const res = await fetchApi(path, {
    ...init,
    headers: {
      Accept: "application/json",
      Authorization: `Bearer ${token}`,
      ...(init?.body ? { "Content-Type": "application/json" } : {}),
      ...(init?.headers ?? {}),
    },
    cache: "no-store",
  });
  const json = (await res.json()) as ApiResponse<T>;
  if (!res.ok || !json.success) {
    throw new Error(json?.message || `Request failed: ${res.status}`);
  }
  return json;
}

