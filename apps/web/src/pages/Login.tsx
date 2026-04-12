import { useEffect, useState } from "react";
import { Link, useNavigate, useSearchParams } from "react-router-dom";
import { toast } from "sonner";
import { useAuth } from "@/contexts/AuthContext";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

export default function Login() {
  const { login, session } = useAuth();
  const nav = useNavigate();
  const [params] = useSearchParams();
  const next = params.get("next") || "/";
  const [phone, setPhone] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (session) nav(next, { replace: true });
  }, [session, nav, next]);

  if (session) return null;

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    try {
      await login(phone.trim(), password);
      toast.success("Đăng nhập thành công");
      nav(next, { replace: true });
    } catch (err: unknown) {
      toast.error(err instanceof Error ? err.message : "Đăng nhập thất bại");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-ocean px-4 py-24">
      <div className="w-full max-w-md rounded-2xl border border-white/10 bg-card/90 p-8 shadow-xl backdrop-blur">
        <h1 className="font-display text-2xl font-bold text-center mb-2">Đăng nhập</h1>
        <p className="text-sm text-muted-foreground text-center mb-6">
          Khách: <strong>số điện thoại</strong> (VN). Nhà cung cấp web: <strong>tên đăng nhập</strong> hoặc email.
        </p>
        <form onSubmit={onSubmit} className="space-y-4">
          <div>
            <Label htmlFor="phone">Số điện thoại hoặc tên đăng nhập (NCC)</Label>
            <Input
              id="phone"
              type="text"
              inputMode="text"
              autoComplete="username"
              placeholder="0912345678 hoặc ten_dang_nhap"
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              required
              className="mt-1"
            />
          </div>
          <div>
            <Label htmlFor="pw">Mật khẩu</Label>
            <Input
              id="pw"
              type="password"
              autoComplete="current-password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              className="mt-1"
            />
          </div>
          <Button type="submit" className="w-full" disabled={loading}>
            {loading ? "Đang đăng nhập…" : "Đăng nhập"}
          </Button>
        </form>
        <p className="text-sm text-center mt-4 text-muted-foreground">
          Chưa có tài khoản?{" "}
          <Link to="/register" className="text-primary font-medium underline-offset-4 hover:underline">
            Đăng ký
          </Link>
        </p>
        <p className="text-center mt-4">
          <Link to="/" className="text-sm text-muted-foreground hover:text-foreground">
            ← Về trang chủ
          </Link>
        </p>
      </div>
    </div>
  );
}
