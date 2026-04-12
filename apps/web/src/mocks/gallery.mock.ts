export interface GalleryItem {
  id: string;
  src: string;
  user: string;
  likes: number;
  date: string;
  category: "sunrise" | "sunset" | "experience" | "video";
  isVideo?: boolean;
  isGolden?: boolean;
  aspect: "portrait" | "landscape";
}

export const mockGallery: GalleryItem[] = [
  { id: "g1", src: "https://picsum.photos/seed/bvc1/800/600", user: "Nguyễn Minh Anh", likes: 234, date: "2 ngày trước", category: "sunrise", isGolden: true, aspect: "portrait" },
  { id: "g2", src: "https://picsum.photos/seed/bvc2/800/600", user: "Trần Thu Hà", likes: 189, date: "5 ngày trước", category: "sunset", aspect: "landscape" },
  { id: "g3", src: "https://picsum.photos/seed/bvc3/800/600", user: "Lê Văn Đức", likes: 312, date: "1 tuần trước", category: "experience", isGolden: true, aspect: "portrait" },
  { id: "g4", src: "https://picsum.photos/seed/bvc4/800/600", user: "Phạm Hoàng Long", likes: 145, date: "3 ngày trước", category: "sunrise", aspect: "landscape" },
  { id: "g5", src: "https://picsum.photos/seed/bvc5/800/600", user: "Đỗ Thị Mai", likes: 267, date: "1 ngày trước", category: "sunrise", isGolden: true, aspect: "portrait" },
  { id: "g6", src: "https://picsum.photos/seed/bvc6/800/600", user: "Vũ Quang Huy", likes: 198, date: "4 ngày trước", category: "sunset", aspect: "landscape" },
  { id: "g7", src: "https://picsum.photos/seed/bvc7/800/600", user: "Hoàng Thị Lan", likes: 87, date: "6 ngày trước", category: "video", isVideo: true, aspect: "portrait" },
  { id: "g8", src: "https://picsum.photos/seed/bvc8/800/600", user: "Bùi Thanh Tùng", likes: 156, date: "2 tuần trước", category: "experience", aspect: "landscape" },
  { id: "g9", src: "https://picsum.photos/seed/bvc9/800/600", user: "Ngô Phương Thảo", likes: 210, date: "1 tuần trước", category: "sunrise", aspect: "portrait" },
  { id: "g10", src: "https://picsum.photos/seed/bvc10/800/600", user: "Trịnh Đức Anh", likes: 134, date: "3 ngày trước", category: "video", isVideo: true, aspect: "landscape" },
  { id: "g11", src: "https://picsum.photos/seed/bvc11/800/600", user: "Lý Thị Hồng", likes: 278, date: "5 ngày trước", category: "sunset", aspect: "portrait" },
  { id: "g12", src: "https://picsum.photos/seed/bvc12/800/600", user: "Đinh Văn Nam", likes: 95, date: "1 ngày trước", category: "experience", aspect: "landscape" },
];
