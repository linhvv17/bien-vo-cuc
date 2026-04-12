import { Phone, Mail } from "lucide-react";

const quickLinks = [
  { label: "Thời tiết", href: "#thoi-tiet" },
  { label: "Thư viện ảnh", href: "#thu-vien" },
  { label: "Đặt dịch vụ", href: "#dich-vu" },
  { label: "Liên hệ", href: "#lien-he" },
];

export default function FooterSection() {
  return (
    <footer id="lien-he" className="section-dark py-12 md:py-16 border-t border-ocean-foreground/10">
      <div className="container">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-10 mb-10">
          {/* Brand */}
          <div>
            <h3 className="font-display text-2xl font-bold text-ocean-foreground mb-2">Biển Vô Cực</h3>
            <p className="text-sm text-ocean-foreground/60 italic">Nơi trời và biển hòa làm một</p>
          </div>

          {/* Quick links */}
          <div>
            <h4 className="font-semibold text-ocean-foreground mb-3">Liên kết</h4>
            <div className="flex flex-col gap-2">
              {quickLinks.map((link) => (
                <a key={link.href} href={link.href} className="text-sm text-ocean-foreground/60 hover:text-primary transition">
                  {link.label}
                </a>
              ))}
            </div>
          </div>

          {/* Contact */}
          <div>
            <h4 className="font-semibold text-ocean-foreground mb-3">Liên hệ</h4>
            <div className="space-y-2">
              <div className="flex items-center gap-2 text-sm text-ocean-foreground/60">
                <Phone size={14} /> 0912 345 678
              </div>
              <div className="flex items-center gap-2 text-sm text-ocean-foreground/60">
                <Mail size={14} /> info@bienvocuc.vn
              </div>
            </div>
            <div className="flex gap-4 mt-4">
              {["Facebook", "Instagram", "TikTok"].map((s) => (
                <a key={s} href="#" className="text-sm text-ocean-foreground/40 hover:text-primary transition">
                  {s}
                </a>
              ))}
            </div>
          </div>
        </div>

        <div className="border-t border-ocean-foreground/10 pt-6 text-center">
          <p className="text-xs text-ocean-foreground/40">© 2026 Biển Vô Cực – Thái Bình</p>
        </div>
      </div>
    </footer>
  );
}
