import { ChevronDown } from "lucide-react";
import { motion } from "framer-motion";
import heroImg from "@/assets/hero-beach.jpg";

export default function HeroSection() {
  return (
    <section className="relative z-0 min-h-screen flex items-center justify-center overflow-hidden">
      {/* Background image */}
      <img
        src={heroImg}
        alt="Biển Vô Cực lúc bình minh"
        className="absolute inset-0 w-full h-full object-cover"
        width={1920}
        height={1080}
      />
      {/* Overlay */}
      <div className="absolute inset-0 bg-ocean/60" />

      <div className="relative z-10 text-center px-4 max-w-4xl mx-auto">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, delay: 0.2 }}
        >
          <h1 className="font-display text-5xl sm:text-6xl md:text-8xl font-bold text-ocean-foreground mb-4 tracking-tight">
            Biển Vô Cực
          </h1>
          <p className="text-lg sm:text-xl md:text-2xl text-ocean-foreground/80 font-body font-light max-w-2xl mx-auto mb-8 leading-relaxed">
            Nơi bầu trời hòa tan vào mặt biển phù sa Thái Bình
          </p>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.6 }}
          className="flex flex-col sm:flex-row gap-4 justify-center mb-10"
        >
          <a
            href="#dich-vu"
            className="bg-primary text-primary-foreground px-8 py-3.5 rounded-lg font-semibold text-lg hover:brightness-110 transition"
          >
            Đặt Dịch Vụ
          </a>
          <a
            href="#thu-vien"
            className="border-2 border-ocean-foreground/50 text-ocean-foreground px-8 py-3.5 rounded-lg font-semibold text-lg hover:bg-ocean-foreground/10 transition"
          >
            Xem Thư Viện Ảnh
          </a>
        </motion.div>

        {/* Một dòng phụ — chi tiết nằm ở #thoi-tiet, tránh khối vàng to trên hero */}
        <motion.p
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 0.5, delay: 1 }}
          className="mx-auto max-w-lg text-[13px] leading-relaxed text-ocean-foreground/75 sm:text-sm"
        >
          Nhiều khách chọn{" "}
          <span className="text-ocean-foreground/90">sáng sớm / bình minh</span> để ngắm cảnh; mùa{" "}
          <span className="text-ocean-foreground/90">tháng 4–8</span> thường thuận tiện hơn (tham khảo).{" "}
          <a
            href="#thoi-tiet"
            className="font-medium text-sky-200 underline decoration-sky-200/50 underline-offset-2 transition hover:text-sky-100"
          >
            Dự báo & gợi ý theo ngày
          </a>
        </motion.p>
      </div>

      {/* Scroll indicator */}
      <motion.div
        className="absolute bottom-8 left-1/2 -translate-x-1/2 text-ocean-foreground/60 animate-bounce-slow"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 1.5 }}
      >
        <ChevronDown size={32} />
      </motion.div>
    </section>
  );
}
