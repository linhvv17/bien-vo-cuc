import { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { toast } from "sonner";
import { useAuth } from "@/contexts/AuthContext";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

export default function Register() {
  const { register, session } = useAuth();
  const nav = useNavigate();
  const [name, setName] = useState("");
  const [phone, setPhone] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (session) nav("/", { replace: true });
  }, [session, nav]);

  if (session) return null;

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    try {
      await register(name.trim(), phone.trim(), password);
      toast.success("Tạo tài khoản thành công");
      nav("/", { replace: true });
    } catch (err: unknown) {
      toast.error(err instanceof Error ? err.message : "Đăng ký thất bại");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-ocean px-4 py-24">
      <div className="w-full max-w-md rounded-2xl border border-white/10 bg-card/90 p-8 shadow-xl backdrop-blur">
        <h1 className="font-display text-2xl font-bold text-center mb-2">Đăng ký</h1>
        <p className="text-sm text-muted-foreground text-center mb-6">
          Mật khẩu 8–64 ký tự, có ít nhất một chữ cái và một chữ số (theo quy định hệ thống).
        </p>
        <form onSubmit={onSubmit} className="space-y-4">
          <div>
            <Label htmlFor="name">Họ tên</Label>
            <Input id="name" value={name} onChange={(e) => setName(e.target.value)} required className="mt-1" />
          </div>
          <div>
            <Label htmlFor="phone">Số điện thoại</Label>
            <Input
              id="phone"
              type="tel"
              placeholder="0912345678"
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
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              minLength={8}
              className="mt-1"
            />
          </div>
          <Button type="submit" className="w-full" disabled={loading}>
            {loading ? "Đang tạo tài khoản…" : "Đăng ký"}
          </Button>
        </form>
        <p className="text-sm text-center mt-4 text-muted-foreground">
          Đã có tài khoản?{" "}
          <Link to="/login" className="text-primary font-medium underline-offset-4 hover:underline">
            Đăng nhập
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
