import { apiUrl } from "./api-config";

export type ApiEnvelope<T> = {
  success: boolean;
  data: T;
  message: string;
  meta?: Record<string, unknown>;
};

export async function apiFetchJson<T>(
  path: string,
  init?: RequestInit & { accessToken?: string },
): Promise<T> {
  const { accessToken, headers: h, ...rest } = init ?? {};
  const headers = new Headers(h);
  headers.set("Accept", "application/json");
  if (rest.body && !headers.has("Content-Type")) {
    headers.set("Content-Type", "application/json");
  }
  if (accessToken) headers.set("Authorization", `Bearer ${accessToken}`);

  const res = await fetch(apiUrl(path), { ...rest, headers });
  const json = (await res.json()) as ApiEnvelope<T>;
  if (!res.ok || !json.success) {
    throw new Error(json.message || `HTTP ${res.status}`);
  }
  return json.data;
}
