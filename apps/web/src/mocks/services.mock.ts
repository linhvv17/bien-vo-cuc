export interface ServiceData {
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
  type: "VEHICLE" | "TOUR";
  isActive: boolean;
  popular?: boolean;
}

// Images imported from assets will be used in the component directly
// This mock provides the data structure for API compatibility
export const mockServices: Omit<ServiceData, "image">[] = [
  {
    id: "svc-1",
    icon: "🚲",
    title: "Xe Xích Lội Biển",
    price: 150000,
    priceLabel: "150,000 VNĐ/người",
    duration: "Buổi sáng (4h–8h)",
    description: "Xe địa phương đặc biệt, di chuyển thoải mái trên bãi phù sa",
    capacity: "Tối đa 2 người/xe",
    maxPeople: 2,
    type: "VEHICLE",
    isActive: true,
  },
  {
    id: "svc-2",
    icon: "🦐",
    title: "Trải Nghiệm Te Tôm",
    price: 200000,
    priceLabel: "200,000 VNĐ/người",
    duration: "2–3 tiếng",
    description: "Cùng ngư dân đánh bắt tôm truyền thống, mang về nấu ăn",
    capacity: "Tối đa 6 người/nhóm",
    maxPeople: 6,
    type: "TOUR",
    isActive: true,
  },
  {
    id: "svc-3",
    icon: "📷",
    title: "Chụp Ảnh Có Hướng Dẫn",
    price: 350000,
    priceLabel: "350,000 VNĐ/người",
    duration: "Buổi bình minh",
    description: "Nhiếp ảnh gia địa phương hướng dẫn góc chụp, kỹ thuật phản chiếu",
    capacity: "Tối đa 4 người/nhóm",
    maxPeople: 4,
    type: "TOUR",
    isActive: true,
  },
  {
    id: "svc-4",
    icon: "⭐",
    title: "Gói Trọn Ngày",
    price: 600000,
    priceLabel: "600,000 VNĐ/người",
    duration: "Cả ngày",
    description: "Xe xích + Te tôm + Bữa ăn hải sản + Chụp ảnh bình minh",
    capacity: "Tối đa 4 người/nhóm",
    maxPeople: 4,
    type: "TOUR",
    isActive: true,
    popular: true,
  },
];
