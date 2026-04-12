import { useState, useEffect } from "react";
import { createPortal } from "react-dom";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { Menu, X } from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";
import { useAuth } from "@/contexts/AuthContext";

const navLinks = [
  { label: "Thời Tiết", href: "#thoi-tiet" },
  { label: "Thư Viện", href: "#thu-vien" },
  { label: "Dịch Vụ", href: "#dich-vu" },
  { label: "Liên Hệ", href: "#lien-he" },
];

export default function StickyNav() {
  const { session, logout, ready } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [scrolled, setScrolled] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 60);
    window.addEventListener("scroll", onScroll);
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  useEffect(() => {
    if (!menuOpen) return;
    const prev = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      document.body.style.overflow = prev;
    };
  }, [menuOpen]);

  /** Các `#section` chỉ tồn tại trên trang chủ — từ route khác phải navigate về `/` kèm hash. */
  const goToSection = (hash: string) => {
    setMenuOpen(false);
    if (location.pathname !== "/") {
      navigate({ pathname: "/", hash });
      return;
    }
    document.querySelector(hash)?.scrollIntoView({ behavior: "smooth" });
  };

  return (
    <>
    <nav
      className={`fixed top-0 left-0 right-0 z-[300] transition-all duration-300 ${
        scrolled ? "bg-ocean/95 backdrop-blur-md shadow-lg" : "bg-transparent"
      }`}
    >
      <div className="container flex items-center justify-between h-16 md:h-20">
        <Link
          to="/"
          className="font-display text-xl md:text-2xl font-bold text-primary-foreground tracking-wide"
          onClick={() => setMenuOpen(false)}
        >
          Biển Vô Cực
        </Link>

        {/* Desktop links */}
        <div className="hidden md:flex items-center gap-8">
          {navLinks.map((link) => (
            <button
              key={link.href}
              type="button"
              onClick={() => goToSection(link.href)}
              className="text-sm font-medium text-ocean-foreground/80 hover:text-ocean-foreground transition-colors"
            >
              {link.label}
            </button>
          ))}
          <button
            type="button"
            onClick={() => goToSection("#dich-vu")}
            className="bg-primary text-primary-foreground px-5 py-2 rounded-lg text-sm font-semibold hover:brightness-110 transition"
          >
            Đặt Ngay
          </button>
          {ready && (
            session ? (
              <div className="flex items-center gap-3 text-sm">
                <span className="text-ocean-foreground/70 max-w-[120px] truncate" title={session.user.name}>
                  {session.user.name}
                </span>
                <Link
                  to="/don-cua-toi"
                  className="text-ocean-foreground/90 hover:text-primary font-medium transition-colors"
                >
                  Đơn của tôi
                </Link>
                <button
                  type="button"
                  onClick={() => logout()}
                  className="text-ocean-foreground/80 hover:text-ocean-foreground underline-offset-4 hover:underline"
                >
                  Đăng xuất
                </button>
              </div>
            ) : (
              <Link
                to="/login"
                className="text-sm font-medium text-ocean-foreground/90 hover:text-primary transition"
              >
                Đăng nhập
              </Link>
            )
          )}
        </div>

        {/* Mobile hamburger */}
        <button
          onClick={() => setMenuOpen(!menuOpen)}
          className="md:hidden text-ocean-foreground p-2"
          aria-label="Menu"
        >
          {menuOpen ? <X size={24} /> : <Menu size={24} />}
        </button>
      </div>

    </nav>
      {typeof document !== "undefined" &&
        createPortal(
          <AnimatePresence>
            {menuOpen && (
              <motion.div
                key="mobile-menu"
                role="dialog"
                aria-modal="true"
                aria-label="Menu điều hướng"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                transition={{ duration: 0.2 }}
                className="fixed inset-0 z-[250] md:hidden"
              >
                <button
                  type="button"
                  aria-label="Đóng menu"
                  className="absolute inset-0 z-0 bg-black/60 backdrop-blur-[2px]"
                  onClick={() => setMenuOpen(false)}
                />
                <div className="absolute inset-x-0 top-16 bottom-0 z-10 flex flex-col items-center justify-start gap-6 overflow-y-auto overscroll-contain bg-ocean px-6 py-10 pb-[max(2.5rem,env(safe-area-inset-bottom))] shadow-[0_-12px_48px_rgba(0,0,0,0.45)]">
                  {navLinks.map((link) => (
                    <button
                      key={link.href}
                      type="button"
                      onClick={() => goToSection(link.href)}
                      className="text-2xl font-display text-ocean-foreground hover:text-primary transition-colors"
                    >
                      {link.label}
                    </button>
                  ))}
                  <button
                    type="button"
                    onClick={() => goToSection("#dich-vu")}
                    className="bg-primary text-primary-foreground px-8 py-3 rounded-lg text-lg font-semibold"
                  >
                    Đặt Ngay
                  </button>
                  {ready && !session && (
                    <Link to="/login" className="text-xl text-primary" onClick={() => setMenuOpen(false)}>
                      Đăng nhập
                    </Link>
                  )}
                  {ready && session && (
                    <>
                      <Link
                        to="/don-cua-toi"
                        className="text-xl text-primary font-medium"
                        onClick={() => setMenuOpen(false)}
                      >
                        Đơn của tôi
                      </Link>
                      <button
                        type="button"
                        onClick={() => {
                          logout();
                          setMenuOpen(false);
                        }}
                        className="text-xl text-ocean-foreground"
                      >
                        Đăng xuất
                      </button>
                    </>
                  )}
                </div>
              </motion.div>
            )}
          </AnimatePresence>,
          document.body,
        )}
    </>
  );
}
