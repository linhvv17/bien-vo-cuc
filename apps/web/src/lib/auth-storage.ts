const KEY = "bvc_web_session_v1";

export type WebAuthUser = {
  id: string;
  email: string;
  phone: string | null;
  name: string;
  role: string;
  userKind: string;
  providerId: string | null;
};

export type WebSession = {
  accessToken: string;
  refreshToken: string;
  user: WebAuthUser;
};

export function loadSession(): WebSession | null {
  try {
    const raw = localStorage.getItem(KEY);
    if (!raw) return null;
    const p = JSON.parse(raw) as WebSession;
    if (!p?.accessToken || !p?.user?.id) return null;
    return p;
  } catch {
    return null;
  }
}

export function saveSession(s: WebSession) {
  localStorage.setItem(KEY, JSON.stringify(s));
}

export function clearSession() {
  localStorage.removeItem(KEY);
}
