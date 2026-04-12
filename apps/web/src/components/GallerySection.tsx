import { useCallback, useEffect, useState } from "react";
import { ChevronLeft, ChevronRight, Heart, Play } from "lucide-react";
import { motion } from "framer-motion";

import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import gallery1 from "@/assets/gallery-1.jpg";
import gallery2 from "@/assets/gallery-2.jpg";
import gallery3 from "@/assets/gallery-3.jpg";
import gallery4 from "@/assets/gallery-4.jpg";
import gallery5 from "@/assets/gallery-5.jpg";
import gallery6 from "@/assets/gallery-6.jpg";

type GalleryItem = {
  id: number;
  src: string;
  user: string;
  likes: number;
  date: string;
  category: "sunrise" | "sunset" | "experience" | "video";
  isVideo?: boolean;
  isGolden?: boolean;
  aspect: "portrait" | "landscape";
  /** Mô tả ngắn — hiện trong xem chi tiết */
  caption?: string;
};

const galleryData: GalleryItem[] = [
  {
    id: 1,
    src: gallery1,
    user: "Nguyễn Minh Anh",
    likes: 234,
    date: "2 ngày trước",
    category: "sunrise",
    isGolden: true,
    aspect: "portrait",
    caption: "Bình minh trên bãi — khung giờ vàng triều rút.",
  },
  { id: 2, src: gallery2, user: "Trần Thu Hà", likes: 189, date: "5 ngày trước", category: "sunset", aspect: "landscape", caption: "Hoàng hôn nhìn về phía biển." },
  { id: 3, src: gallery3, user: "Lê Văn Đức", likes: 312, date: "1 tuần trước", category: "experience", isGolden: true, aspect: "portrait" },
  { id: 4, src: gallery4, user: "Phạm Hoàng Long", likes: 145, date: "3 ngày trước", category: "sunrise", aspect: "landscape" },
  { id: 5, src: gallery5, user: "Đỗ Thị Mai", likes: 267, date: "1 ngày trước", category: "sunrise", isGolden: true, aspect: "portrait" },
  { id: 6, src: gallery6, user: "Vũ Quang Huy", likes: 198, date: "4 ngày trước", category: "sunset", aspect: "landscape" },
  {
    id: 7,
    src: gallery1,
    user: "Hoàng Thị Lan",
    likes: 87,
    date: "6 ngày trước",
    category: "video",
    isVideo: true,
    aspect: "portrait",
    caption: "Clip ngắn ghi lại sóng và bình minh (ảnh bìa — video đầy đủ sẽ gắn khi có nguồn).",
  },
  { id: 8, src: gallery2, user: "Bùi Thanh Tùng", likes: 156, date: "2 tuần trước", category: "experience", aspect: "landscape" },
  { id: 9, src: gallery5, user: "Ngô Phương Thảo", likes: 210, date: "1 tuần trước", category: "sunrise", aspect: "portrait" },
  {
    id: 10,
    src: gallery4,
    user: "Trịnh Đức Anh",
    likes: 134,
    date: "3 ngày trước",
    category: "video",
    isVideo: true,
    aspect: "landscape",
    caption: "Toàn cảnh bãi lúc ráng chiều.",
  },
  { id: 11, src: gallery3, user: "Lý Thị Hồng", likes: 278, date: "5 ngày trước", category: "sunset", aspect: "portrait" },
  { id: 12, src: gallery6, user: "Đinh Văn Nam", likes: 95, date: "1 ngày trước", category: "experience", aspect: "landscape" },
];

const tabs = [
  { key: "all", label: "Tất cả" },
  { key: "sunrise", label: "Bình minh" },
  { key: "sunset", label: "Hoàng hôn" },
  { key: "experience", label: "Trải nghiệm" },
  { key: "video", label: "Video" },
];

const CATEGORY_VI: Record<GalleryItem["category"], string> = {
  sunrise: "Bình minh",
  sunset: "Hoàng hôn",
  experience: "Trải nghiệm",
  video: "Video",
};

type DetailState = { list: GalleryItem[]; index: number };

export default function GallerySection() {
  const [activeTab, setActiveTab] = useState("all");
  const [showCount, setShowCount] = useState(8);
  const [detail, setDetail] = useState<DetailState | null>(null);

  const filtered = activeTab === "all" ? galleryData : galleryData.filter((g) => g.category === activeTab);
  const visible = filtered.slice(0, showCount);

  const openDetail = useCallback(
    (item: GalleryItem) => {
      const idx = filtered.findIndex((g) => g.id === item.id);
      setDetail({ list: filtered, index: idx >= 0 ? idx : 0 });
    },
    [filtered],
  );

  const detailItem = detail ? detail.list[detail.index] : null;
  const detailPos = detail ? `${detail.index + 1} / ${detail.list.length}` : "";

  const goPrev = useCallback(() => {
    setDetail((d) => {
      if (!d || d.list.length === 0) return d;
      const next = d.index > 0 ? d.index - 1 : d.list.length - 1;
      return { list: d.list, index: next };
    });
  }, []);

  const goNext = useCallback(() => {
    setDetail((d) => {
      if (!d || d.list.length === 0) return d;
      const next = d.index < d.list.length - 1 ? d.index + 1 : 0;
      return { list: d.list, index: next };
    });
  }, []);

  useEffect(() => {
    if (!detail) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "ArrowLeft") {
        e.preventDefault();
        goPrev();
      } else if (e.key === "ArrowRight") {
        e.preventDefault();
        goNext();
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [detail, goPrev, goNext]);

  return (
    <section id="thu-vien" className="section-light py-16 md:py-24">
      <div className="container">
        <motion.h2
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="font-display text-3xl md:text-4xl font-bold text-foreground text-center mb-4"
        >
          Ảnh & Video Từ Cộng Đồng
        </motion.h2>
        <p className="text-center text-muted-foreground mb-8 text-sm">
          Khám phá vẻ đẹp qua ống kính của du khách — chạm vào ảnh hoặc video để xem chi tiết.
        </p>

        {/* Tabs */}
        <div className="flex gap-2 justify-center flex-wrap mb-8">
          {tabs.map((tab) => (
            <button
              key={tab.key}
              onClick={() => { setActiveTab(tab.key); setShowCount(8); }}
              className={`px-4 py-2 rounded-full text-sm font-medium transition-all ${
                activeTab === tab.key
                  ? "bg-primary text-primary-foreground"
                  : "bg-muted text-muted-foreground hover:bg-muted/80"
              }`}
            >
              {tab.label}
            </button>
          ))}
        </div>

        {/* Masonry grid */}
        <div className="columns-2 md:columns-3 lg:columns-4 gap-4 space-y-4">
          {visible.map((item, i) => (
            <motion.div
              key={item.id}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: i * 0.05 }}
              className="relative break-inside-avoid"
            >
              <button
                type="button"
                onClick={() => openDetail(item)}
                className="group relative w-full cursor-pointer overflow-hidden rounded-xl text-left ring-offset-background transition focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2"
                aria-label={`Xem chi tiết — ${CATEGORY_VI[item.category]}, ${item.user}`}
              >
                <img
                  src={item.src}
                  alt={`Ảnh bởi ${item.user}`}
                  className="w-full object-cover"
                  loading="lazy"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-ocean/85 via-ocean/20 to-transparent opacity-90 transition-opacity duration-300 group-hover:opacity-100 md:opacity-0 md:group-hover:opacity-100 flex flex-col justify-end p-3">
                  <span className="text-ocean-foreground text-sm font-medium drop-shadow">Chạm để xem chi tiết</span>
                  <span className="text-ocean-foreground text-sm font-medium drop-shadow md:hidden">{item.user}</span>
                  <div className="flex items-center gap-2 text-ocean-foreground/90 text-xs drop-shadow">
                    <Heart size={12} aria-hidden /> {item.likes}
                    <span className="ml-1">{item.date}</span>
                  </div>
                </div>
                {item.isVideo && (
                  <div className="pointer-events-none absolute inset-0 flex items-center justify-center">
                    <div className="flex h-14 w-14 items-center justify-center rounded-full bg-ocean/60">
                      <Play size={24} className="ml-1 text-ocean-foreground" aria-hidden />
                    </div>
                  </div>
                )}
                {item.isGolden && (
                  <span className="absolute left-3 top-3 badge-gold text-xs">Khung giờ vàng</span>
                )}
              </button>
            </motion.div>
          ))}
        </div>

        {showCount < filtered.length && (
          <div className="text-center mt-8">
            <button
              type="button"
              onClick={() => setShowCount((c) => c + 8)}
              className="px-6 py-3 border-2 border-primary text-primary rounded-lg font-semibold hover:bg-primary hover:text-primary-foreground transition"
            >
              Xem Thêm
            </button>
          </div>
        )}

        <Dialog open={detail != null} onOpenChange={(open) => !open && setDetail(null)}>
          <DialogContent className="flex max-h-[min(92dvh,880px)] w-[calc(100%-1.25rem)] max-w-3xl flex-col gap-0 overflow-y-auto overflow-x-hidden rounded-2xl border border-border/50 bg-card p-0 shadow-2xl">
            {detailItem ? (
              <>
                {/* Ảnh: giới hạn max-height — chừa chỗ cho panel dưới; không dùng min-h + flex-1 (dễ cắt chữ) */}
                <div className="relative flex max-h-[min(56vh,520px)] w-full shrink-0 items-center justify-center bg-gradient-to-b from-zinc-800/90 to-zinc-950 px-3 pb-4 pt-14 sm:max-h-[min(60vh,560px)] sm:px-5">
                  <button
                    type="button"
                    onClick={(e) => {
                      e.stopPropagation();
                      goPrev();
                    }}
                    className="absolute left-2 top-1/2 z-20 flex h-12 w-12 -translate-y-1/2 items-center justify-center rounded-full bg-white/12 text-white shadow-lg ring-1 ring-white/20 backdrop-blur-md transition hover:bg-white/22 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary sm:left-4"
                    aria-label="Ảnh trước"
                  >
                    <ChevronLeft className="h-7 w-7" aria-hidden />
                  </button>
                  <button
                    type="button"
                    onClick={(e) => {
                      e.stopPropagation();
                      goNext();
                    }}
                    className="absolute right-2 top-1/2 z-20 flex h-12 w-12 -translate-y-1/2 items-center justify-center rounded-full bg-white/12 text-white shadow-lg ring-1 ring-white/20 backdrop-blur-md transition hover:bg-white/22 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary sm:right-4"
                    aria-label="Ảnh sau"
                  >
                    <ChevronRight className="h-7 w-7" aria-hidden />
                  </button>
                  <img
                    src={detailItem.src}
                    alt=""
                    className="max-h-[min(50vh,480px)] w-auto max-w-full rounded-md object-contain shadow-[0_8px_40px_-8px_rgba(0,0,0,0.65)] ring-1 ring-white/10 sm:max-h-[min(54vh,520px)]"
                  />
                  {detailItem.isVideo ? (
                    <div className="pointer-events-none absolute inset-0 flex items-center justify-center bg-black/15 pt-10">
                      <div className="rounded-full bg-ocean/80 px-4 py-2 text-sm font-medium text-ocean-foreground shadow-lg backdrop-blur-sm">
                        Video — đang dùng ảnh bìa; gắn file khi có nguồn
                      </div>
                    </div>
                  ) : null}
                </div>
                {/* Thông tin: modal tổng đã overflow-y-auto — không cắt đáy; padding đáy an toàn trên iOS */}
                <div className="space-y-3 bg-gradient-to-b from-muted/25 to-background px-5 py-5 sm:px-7 sm:py-6 pb-[max(1.5rem,env(safe-area-inset-bottom,12px))]">
                  <DialogHeader className="space-y-2 text-left">
                    <div className="flex flex-wrap items-center justify-between gap-2">
                      <p className="text-[11px] font-semibold uppercase tracking-wide text-muted-foreground">{detailPos}</p>
                      <span className="text-[11px] text-muted-foreground/80">← → chuyển ảnh</span>
                    </div>
                    <div className="flex flex-wrap items-center gap-2">
                      <span className="rounded-full bg-primary/12 px-2.5 py-0.5 text-xs font-semibold text-primary">
                        {CATEGORY_VI[detailItem.category]}
                      </span>
                      {detailItem.isGolden ? (
                        <span className="rounded-full bg-accent/18 px-2.5 py-0.5 text-xs font-semibold text-accent-foreground">
                          Khung giờ vàng
                        </span>
                      ) : null}
                      {detailItem.isVideo ? (
                        <span className="rounded-full bg-secondary/20 px-2.5 py-0.5 text-xs font-semibold text-secondary-foreground">
                          Video
                        </span>
                      ) : null}
                    </div>
                    <DialogTitle className="pr-10 font-display text-xl leading-snug sm:text-2xl">
                      {detailItem.user}
                    </DialogTitle>
                    <DialogDescription asChild>
                      <div className="flex flex-wrap items-center gap-3 text-sm text-muted-foreground">
                        <span className="inline-flex items-center gap-1">
                          <Heart className="h-4 w-4 shrink-0" aria-hidden /> {detailItem.likes} lượt thích
                        </span>
                        <span className="text-border">·</span>
                        <span>{detailItem.date}</span>
                      </div>
                    </DialogDescription>
                  </DialogHeader>
                  <p className="text-sm leading-relaxed text-foreground/95">
                    {detailItem.caption ??
                      `Ảnh ${CATEGORY_VI[detailItem.category].toLowerCase()} từ cộng đồng. Bạn có thể đóng góp nội dung sau khi đăng nhập ứng dụng.`}
                  </p>
                </div>
              </>
            ) : null}
          </DialogContent>
        </Dialog>
      </div>
    </section>
  );
}
