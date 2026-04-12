import { useQuery } from "@tanstack/react-query";
import apiClient from "@/lib/api-client";
import { mockServices } from "@/mocks/services.mock";
import serviceXich from "@/assets/service-xich.jpg";
import serviceShrimp from "@/assets/service-shrimp.jpg";
import servicePhoto from "@/assets/service-photo.jpg";
import serviceFullday from "@/assets/service-fullday.jpg";

/** Bật `true` trong `.env` khi không có API — toàn bộ dịch vụ & đặt chỗ là demo. */
const useMockOnly = import.meta.env.VITE_USE_MOCK === "true";

type ApiService = {
  id: string;
  name: string;
  description: string;
  price: number;
  maxCapacity: number;
  images: string[];
  type: string;
};

function typeIcon(t: string) {
  switch (t) {
    case "VEHICLE":
      return "🚲";
    case "TOUR":
      return "📷";
    case "ACCOMMODATION":
      return "🏨";
    case "FOOD":
      return "🍜";
    default:
      return "⭐";
  }
}

function fallbackImg(t: string): string {
  switch (t) {
    case "VEHICLE":
      return serviceXich;
    case "TOUR":
      return servicePhoto;
    case "FOOD":
      return serviceShrimp;
    case "ACCOMMODATION":
      return serviceFullday;
    default:
      return serviceFullday;
  }
}

/** Khớp `ServiceType` API — dùng để chia mục trên web. */
export type ServiceCategory = "ACCOMMODATION" | "FOOD" | "VEHICLE" | "TOUR" | "OTHER";

function normalizeCategory(t: string): ServiceCategory {
  if (t === "ACCOMMODATION" || t === "FOOD" || t === "VEHICLE" || t === "TOUR") return t;
  return "OTHER";
}

export type CatalogService = {
  id: string;
  icon: string;
  title: string;
  price: number;
  priceLabel: string;
  duration: string;
  description: string;
  capacity: string;
  maxPeople: number;
  image: string;
  /** Phân nhóm hiển thị (Đặt dịch vụ theo mục). */
  category: ServiceCategory;
  popular?: boolean;
};

function mapApi(s: ApiService): CatalogService {
  const img = s.images?.length ? s.images[0] : fallbackImg(s.type);
  return {
    id: s.id,
    icon: typeIcon(s.type),
    title: s.name,
    price: s.price,
    priceLabel: `${s.price.toLocaleString("vi-VN")} VNĐ`,
    duration: "Chi tiết khi xác nhận đơn",
    description: s.description || "",
    capacity: `Tối đa ${s.maxCapacity} người`,
    maxPeople: Math.max(1, s.maxCapacity),
    image: img,
    category: normalizeCategory(s.type),
  };
}

function mapMock(): CatalogService[] {
  const imgs = [serviceXich, serviceShrimp, servicePhoto, serviceFullday];
  return mockServices.map((m, i) => ({
    ...m,
    image: imgs[i % imgs.length],
    category: normalizeCategory(m.type),
  })) as CatalogService[];
}

/** Thứ tự hiển thị mục trên trang Đặt dịch vụ. */
export const SERVICE_CATEGORY_ORDER: ServiceCategory[] = [
  "ACCOMMODATION",
  "FOOD",
  "VEHICLE",
  "TOUR",
  "OTHER",
];

export const SERVICE_CATEGORY_LABELS: Record<ServiceCategory, string> = {
  ACCOMMODATION: "Lưu trú",
  FOOD: "Ăn uống",
  VEHICLE: "Phương tiện & di chuyển",
  TOUR: "Trải nghiệm & chụp ảnh",
  OTHER: "Dịch vụ khác",
};

export const SERVICE_CATEGORY_HINTS: Partial<Record<ServiceCategory, string>> = {
  ACCOMMODATION: "Homestay, phòng nghỉ gần bãi",
  FOOD: "Hải sản, bữa ăn theo nhóm",
  VEHICLE: "Xe xích, di chuyển trên bãi",
  TOUR: "Te tôm, chụp ảnh, gói cả ngày",
  OTHER: "Các dịch vụ còn lại",
};

export function groupCatalogByCategory(items: CatalogService[]): {
  category: ServiceCategory;
  title: string;
  hint?: string;
  items: CatalogService[];
}[] {
  const buckets = new Map<ServiceCategory, CatalogService[]>();
  for (const c of SERVICE_CATEGORY_ORDER) buckets.set(c, []);
  for (const s of items) {
    const list = buckets.get(s.category) ?? buckets.get("OTHER")!;
    list.push(s);
  }
  return SERVICE_CATEGORY_ORDER.filter((c) => (buckets.get(c)?.length ?? 0) > 0).map((c) => ({
    category: c,
    title: SERVICE_CATEGORY_LABELS[c],
    hint: SERVICE_CATEGORY_HINTS[c],
    items: buckets.get(c)!,
  }));
}

export function useCatalogServices() {
  return useQuery({
    queryKey: ["catalog-services", useMockOnly],
    queryFn: async (): Promise<{ items: CatalogService[]; source: "api" | "mock" }> => {
      if (useMockOnly) {
        return { items: mapMock(), source: "mock" };
      }
      const res = await apiClient.get<ApiService[]>("services?limit=50");
      const rows = res.data;
      const list = Array.isArray(rows) ? rows : [];
      return { items: list.map(mapApi), source: "api" };
    },
    staleTime: 60_000,
  });
}
