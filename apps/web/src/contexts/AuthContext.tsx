import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from "react";
import { apiFetchJson } from "@/lib/api-json";
import { clearSession, loadSession, saveSession, type WebAuthUser, type WebSession } from "@/lib/auth-storage";

type AuthContextValue = {
  session: WebSession | null;
  ready: boolean;
  login: (identifier: string, password: string) => Promise<void>;
  register: (name: string, phone: string, password: string) => Promise<void>;
  logout: () => void;
};

const AuthContext = createContext<AuthContextValue | null>(null);

type LoginPayload = {
  accessToken: string;
  refreshToken: string;
  user: WebAuthUser;
};

export function AuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<WebSession | null>(null);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    setSession(loadSession());
    setReady(true);
  }, []);

  const login = useCallback(async (identifier: string, password: string) => {
    const data = await apiFetchJson<LoginPayload>("/auth/login", {
      method: "POST",
      body: JSON.stringify({ identifier: identifier.trim(), password }),
    });
    const s: WebSession = {
      accessToken: data.accessToken,
      refreshToken: data.refreshToken,
      user: data.user,
    };
    saveSession(s);
    setSession(s);
  }, []);

  const register = useCallback(async (name: string, phone: string, password: string) => {
    const data = await apiFetchJson<LoginPayload>("/auth/register", {
      method: "POST",
      body: JSON.stringify({ name: name.trim(), phone: phone.trim(), password }),
    });
    const s: WebSession = {
      accessToken: data.accessToken,
      refreshToken: data.refreshToken,
      user: data.user,
    };
    saveSession(s);
    setSession(s);
  }, []);

  const logout = useCallback(() => {
    clearSession();
    setSession(null);
  }, []);

  const value = useMemo(
    () => ({ session, ready, login, register, logout }),
    [session, ready, login, register, logout],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const v = useContext(AuthContext);
  if (!v) throw new Error("useAuth must be used within AuthProvider");
  return v;
}
