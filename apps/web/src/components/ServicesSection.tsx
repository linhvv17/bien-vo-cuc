import { useState } from "react";
import { Link } from "react-router-dom";
import { motion, AnimatePresence } from "framer-motion";
import { Users, Clock, X, Plus, Minus, Loader2, AlertCircle } from "lucide-react";
import { toast } from "sonner";
import { useCreatePublicBooking } from "@/hooks/api/useBookings";
import {
  useCatalogServices,
  groupCatalogByCategory,
  type CatalogService,
} from "@/hooks/useCatalogServices";
import { useAuth } from "@/contexts/AuthContext";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";

const useMockOnly = import.meta.env.VITE_USE_MOCK === "true";

const VN_PHONE_REGEX = /^0[35789]\d{8}$/;

function BookingModal({ service, onClose }: { service: CatalogService; onClose: () => void }) {
  const { session } = useAuth();
  const [people, setPeople] = useState(1);
  const [formData, setFormData] = useState({ name: "", phone: "", email: "", date: "", notes: "" });
  const [errors, setErrors] = useState<Record<string, string>>({});
  const { mutateAsync: createBooking, isPending } = useCreatePublicBooking();

  /** API lưu trú có phòng: không gửi roomLines thì chỉ được quantity = 1 (một phòng / lần). */
  const isAccommodation = service.category === "ACCOMMODATION";

  const today = new Date().toISOString().split("T")[0];

  const validate = () => {
    const errs: Record<string, string> = {};
    if (!formData.name.trim()) errs.name = "Vui lòng nhập họ tên";
    if (!formData.phone.trim()) errs.phone = "Vui lòng nhập số điện thoại";
    else if (!VN_PHONE_REGEX.test(formData.phone.replace(/\s/g, "")))
      errs.phone = "Số điện thoại không hợp lệ (VD: 0912345678)";
    if (!formData.date) errs.date = "Vui lòng chọn ngày";
    if (formData.email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email))
      errs.email = "Email không hợp lệ";
    setErrors(errs);
    return Object.keys(errs).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validate()) return;

    try {
      const qty = isAccommodation ? 1 : people;
      const noteParts: string[] = [];
      if (isAccommodation) {
        noteParts.push(`Số khách dự kiến: ${people}`);
      }
      if (formData.notes?.trim()) noteParts.push(formData.notes.trim());
      const customerNote = noteParts.length > 0 ? noteParts.join(" · ") : undefined;

      await createBooking({
        asGuest: !session,
        serviceId: service.id,
        date: formData.date,
        quantity: qty,
        customerName: formData.name.trim(),
        customerPhone: formData.phone.replace(/\s/g, ""),
        customerNote,
      });

      onClose();
      toast.success(
        session
          ? "Đặt chỗ thành công! Bạn có thể xem trong mục Đơn của tôi."
          : "Đặt chỗ thành công! Đơn được gửi cho admin và nhà cung cấp. Đăng nhập sau để theo dõi đơn cùng số điện thoại.",
      );
    } catch (err: unknown) {
      toast.error(err instanceof Error ? err.message : "Có lỗi xảy ra, vui lòng thử lại.");
    }
  };

  const setField = (key: string, value: string) => {
    setFormData((prev) => ({ ...prev, [key]: value }));
    if (errors[key]) setErrors((prev) => { const n = { ...prev }; delete n[key]; return n; });
  };

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 z-50 bg-ocean/50 backdrop-blur-sm flex items-end md:items-center justify-center p-4"
      onClick={onClose}
    >
      <motion.div
        initial={{ y: 100, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        exit={{ y: 100, opacity: 0 }}
        onClick={(e) => e.stopPropagation()}
        className="bg-card text-card-foreground rounded-t-2xl md:rounded-2xl w-full max-w-lg p-6 shadow-2xl max-h-[90vh] overflow-y-auto"
      >
        <div className="flex items-center justify-between mb-4">
          <h3 className="font-display text-xl font-bold">{service.title}</h3>
          <button type="button" onClick={onClose} disabled={isPending}><X size={20} /></button>
        </div>

        {!useMockOnly && !session ? (
          <p className="rounded-xl border border-sky-500/25 bg-sky-500/10 px-4 py-3 text-sm text-sky-100/95">
            Bạn có thể đặt ngay <strong>không cần tài khoản</strong>.{" "}
            <Link to="/login?next=/" className="font-medium text-primary underline-offset-2 hover:underline">
              Đăng nhập
            </Link>{" "}
            để xem lại đơn trong <strong>Đơn của tôi</strong>.
          </p>
        ) : null}

        <form onSubmit={handleSubmit} className="space-y-4 mt-4">
          <div>
            <label className="text-sm font-medium block mb-1">Ngày đặt <span className="text-destructive">*</span></label>
            <input
              type="date"
              required
              min={today}
              value={formData.date}
              onChange={(e) => setField("date", e.target.value)}
              className={`w-full px-4 py-3 rounded-lg border bg-background text-foreground text-sm ${errors.date ? "border-destructive" : "border-input"}`}
            />
            {errors.date && <p className="text-xs text-destructive mt-1">{errors.date}</p>}
          </div>

          <div>
            <label className="text-sm font-medium block mb-1">
              {isAccommodation ? "Số khách (dự kiến)" : "Số người"} <span className="text-destructive">*</span>
            </label>
            {isAccommodation ? (
              <p className="text-xs text-muted-foreground mb-2 rounded-md bg-muted/40 px-2 py-1.5">
                Mỗi lần đặt <strong>1 phòng</strong> trên web. Số khách ghi kèm đơn; cần nhiều phòng vui lòng đặt thêm lần hoặc ghi trong ghi chú.
              </p>
            ) : null}
            <div className="flex items-center gap-4">
              <button type="button" onClick={() => setPeople(Math.max(1, people - 1))} className="w-10 h-10 rounded-lg border border-input flex items-center justify-center hover:bg-muted transition"><Minus size={16} /></button>
              <span className="text-lg font-bold w-8 text-center">{people}</span>
              <button type="button" onClick={() => setPeople(Math.min(service.maxPeople, people + 1))} className="w-10 h-10 rounded-lg border border-input flex items-center justify-center hover:bg-muted transition"><Plus size={16} /></button>
              <span className="text-xs text-muted-foreground">({service.capacity})</span>
            </div>
          </div>

          <div>
            <label className="text-sm font-medium block mb-1">Họ và tên <span className="text-destructive">*</span></label>
            <input required placeholder="Nguyễn Văn A" maxLength={100} value={formData.name} onChange={(e) => setField("name", e.target.value)} className={`w-full px-4 py-3 rounded-lg border bg-background text-foreground text-sm ${errors.name ? "border-destructive" : "border-input"}`} />
            {errors.name && <p className="text-xs text-destructive mt-1">{errors.name}</p>}
          </div>

          <div>
            <label className="text-sm font-medium block mb-1">Số điện thoại <span className="text-destructive">*</span></label>
            <input required type="tel" placeholder="0912 345 678" maxLength={15} value={formData.phone} onChange={(e) => setField("phone", e.target.value)} className={`w-full px-4 py-3 rounded-lg border bg-background text-foreground text-sm ${errors.phone ? "border-destructive" : "border-input"}`} />
            {errors.phone && <p className="text-xs text-destructive mt-1">{errors.phone}</p>}
          </div>

          <div>
            <label className="text-sm font-medium block mb-1">Email <span className="text-xs text-muted-foreground">(tùy chọn)</span></label>
            <input type="email" placeholder="email@example.com" maxLength={255} value={formData.email} onChange={(e) => setField("email", e.target.value)} className={`w-full px-4 py-3 rounded-lg border bg-background text-foreground text-sm ${errors.email ? "border-destructive" : "border-input"}`} />
            {errors.email && <p className="text-xs text-destructive mt-1">{errors.email}</p>}
          </div>

          <div>
            <label className="text-sm font-medium block mb-1">Ghi chú <span className="text-xs text-muted-foreground">(tùy chọn)</span></label>
            <textarea rows={3} maxLength={1000} placeholder="Yêu cầu đặc biệt…" value={formData.notes} onChange={(e) => setField("notes", e.target.value)} className="w-full px-4 py-3 rounded-lg border border-input bg-background text-foreground text-sm resize-none" />
          </div>

          <div className="bg-muted/50 rounded-lg p-4 text-center">
            <div className="flex justify-between text-sm text-muted-foreground mb-1">
              <span>Đơn giá</span>
              <span>
                {isAccommodation
                  ? `${service.price.toLocaleString("vi-VN")} VNĐ / phòng (×1)`
                  : `${service.price.toLocaleString("vi-VN")} VNĐ × ${people} người`}
              </span>
            </div>
            <span className="text-sm text-muted-foreground">Tổng cộng</span>
            <p className="text-2xl font-bold text-primary">
              {(isAccommodation ? service.price : service.price * people).toLocaleString("vi-VN")} VNĐ
            </p>
          </div>

          <button
            type="submit"
            disabled={isPending}
            className="w-full bg-primary text-primary-foreground py-3.5 rounded-lg font-semibold text-lg hover:brightness-110 transition disabled:opacity-60 disabled:cursor-not-allowed flex items-center justify-center gap-2"
          >
            {isPending ? (<><Loader2 size={20} className="animate-spin" />Đang xử lý...</>) : "Xác Nhận Đặt Chỗ"}
          </button>
          {useMockOnly ? (
            <p className="text-xs text-center text-amber-200/90">Chế độ demo — không gửi lên server.</p>
          ) : (
            <p className="text-xs text-center text-muted-foreground">
              Đơn gửi về hệ thống để admin / nhà cung cấp xử lý. Khách chưa đăng nhập vẫn đặt được; đăng nhập cùng SĐT để xem trong Đơn của tôi.
            </p>
          )}
        </form>
      </motion.div>
    </motion.div>
  );
}

export default function ServicesSection() {
  const [booking, setBooking] = useState<CatalogService | null>(null);
  const { data, isLoading, isError, error } = useCatalogServices();

  const items = data?.items ?? [];
  const source = data?.source;
  const grouped = groupCatalogByCategory(items);

  return (
    <section id="dich-vu" className="section-dark py-16 md:py-24">
      <div className="container">
        <motion.h2 initial={{ opacity: 0, y: 20 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} className="font-display text-3xl md:text-4xl font-bold text-ocean-foreground text-center mb-4">
          Đặt Dịch Vụ
        </motion.h2>
        <p className="text-center text-ocean-foreground/60 mb-4 text-sm">Trải nghiệm trọn vẹn vẻ đẹp Biển Vô Cực</p>

        {source === "api" ? (
          <p className="text-center text-xs text-emerald-400/90 mb-8">Đã kết nối hệ thống — đặt chỗ gửi về server.</p>
        ) : useMockOnly ? (
          <p className="text-center text-xs text-amber-200/80 mb-8">Chế độ demo (VITE_USE_MOCK=true)</p>
        ) : null}

        {isLoading ? (
          <div className="flex justify-center py-20">
            <Loader2 className="h-10 w-10 animate-spin text-primary" />
          </div>
        ) : isError ? (
          <div className="flex flex-col items-center gap-2 py-16 text-center text-rose-300">
            <AlertCircle className="h-10 w-10" />
            <p>
              Không tải được danh sách dịch vụ. Kiểm tra API đang chạy; dev dùng proxy{" "}
              <code className="text-xs">VITE_API_PROXY_TARGET</code> (hoặc{" "}
              <code className="text-xs">VITE_API_BASE_URL</code> nếu gọi trực tiếp).
            </p>
            <p className="text-sm text-muted-foreground">{error instanceof Error ? error.message : String(error)}</p>
          </div>
        ) : items.length === 0 ? (
          <p className="text-center text-muted-foreground py-16">Chưa có dịch vụ trên hệ thống. Vui lòng quay lại sau.</p>
        ) : (
          <Tabs defaultValue={grouped[0]!.category} className="w-full scroll-mt-28">
            <div className="relative -mx-1 mb-2 overflow-x-auto pb-1">
              <TabsList
                className="inline-flex h-auto min-h-11 w-max max-w-none flex-nowrap gap-1 rounded-xl border border-white/10 bg-white/5 p-1.5 text-ocean-foreground/80 md:mx-auto md:flex md:w-auto md:flex-wrap md:justify-center"
                aria-label="Chọn nhóm dịch vụ"
              >
                {grouped.map((group) => (
                  <TabsTrigger
                    key={group.category}
                    value={group.category}
                    id={`dich-vu-tab-${group.category.toLowerCase().replace(/_/g, "-")}`}
                    className="shrink-0 rounded-lg px-4 py-2.5 text-sm font-medium data-[state=active]:bg-primary/25 data-[state=active]:text-primary-foreground data-[state=active]:shadow-md sm:px-5"
                  >
                    {group.title}
                  </TabsTrigger>
                ))}
              </TabsList>
            </div>

            {grouped.map((group) => (
              <TabsContent
                key={group.category}
                value={group.category}
                className="mt-6 outline-none focus-visible:ring-0"
                id={`dich-vu-${group.category.toLowerCase().replace(/_/g, "-")}`}
              >
                {group.hint ? (
                  <p className="mb-6 text-center text-sm text-ocean-foreground/60 md:text-left">{group.hint}</p>
                ) : null}
                <div className="grid grid-cols-1 gap-6 md:grid-cols-2 xl:grid-cols-4">
                  {group.items.map((s, i) => (
                    <motion.div
                      key={s.id}
                      initial={{ opacity: 0, y: 24 }}
                      whileInView={{ opacity: 1, y: 0 }}
                      viewport={{ once: true }}
                      transition={{ delay: Math.min(i * 0.06, 0.36) }}
                      whileHover={{ y: -8, boxShadow: "0 20px 40px -10px rgba(0,0,0,0.4)" }}
                      className="card-surface flex flex-col overflow-hidden"
                    >
                      <div className="relative">
                        <img src={s.image} alt={s.title} className="aspect-video w-full object-cover" loading="lazy" />
                        {s.popular && <span className="badge-gold absolute right-3 top-3">Phổ biến nhất</span>}
                      </div>
                      <div className="flex flex-1 flex-col p-5">
                        <div className="mb-2 flex items-center gap-2">
                          <span className="text-2xl">{s.icon}</span>
                          <h4 className="font-display text-lg font-bold text-ocean-foreground">{s.title}</h4>
                        </div>
                        <p className="mb-2 text-2xl font-bold text-primary">{s.priceLabel}</p>
                        <div className="mb-1 flex items-center gap-2 text-xs text-surface-foreground/60">
                          <Clock size={14} /> {s.duration}
                        </div>
                        <p className="mb-3 flex-1 text-sm text-surface-foreground/70">{s.description}</p>
                        <div className="mb-4 flex items-center gap-2 text-xs text-surface-foreground/50">
                          <Users size={14} /> {s.capacity}
                        </div>
                        <button
                          type="button"
                          onClick={() => setBooking(s)}
                          className="w-full rounded-lg bg-primary py-3 font-semibold text-primary-foreground transition hover:brightness-110"
                        >
                          Đặt Ngay
                        </button>
                      </div>
                    </motion.div>
                  ))}
                </div>
              </TabsContent>
            ))}
          </Tabs>
        )}
      </div>

      <AnimatePresence>
        {booking && <BookingModal service={booking} onClose={() => setBooking(null)} />}
      </AnimatePresence>
    </section>
  );
}
