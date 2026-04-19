# Lovable brief — Biển Vô Cực (Mobile app) + System Architecture

Tài liệu này để giao cho Lovable (designer) **thiết kế lại UI/UX app mobile** dựa trên **chức năng hiện có** và **kiến trúc hệ thống** (API/backend, môi trường, ràng buộc kỹ thuật).

---

## 1) Mục tiêu sản phẩm (Product goals)

- **Giúp người dùng lên kế hoạch đi Biển Vô Cực**: xem **triều**, **khung triều vàng**, **dự báo thời tiết**, và một chỉ số tổng hợp “Go score”.
- **Đặt dịch vụ nhanh**: ăn/ở, xe xích, chụp ảnh/flycam, combo.
- **Trải nghiệm ổn định** kể cả khi một nguồn dữ liệu bị lỗi (ví dụ thời tiết upstream 429).

---

## 2) Persona & tình huống sử dụng

- **Khách du lịch/đi phượt**: cần biết ngày/giờ triều thấp, thời tiết ổn để chụp “gương trời”.
- **Nhóm gia đình**: ưu tiên an toàn, gió/mưa ít; muốn đặt combo dịch vụ.
- **Nhà cung cấp/merchant (tuỳ scope)**: xem/nhận booking (nếu có luồng quản trị trong app; hiện chủ yếu ở web/admin).

---

## 3) Kiến trúc hệ thống (High-level architecture)

### 3.1 Mobile app (Flutter)

- App Flutter (monorepo module) nằm ở: `apps/mobile/`
- Networking dùng **Dio** thông qua façade `NetworkService` (một Dio duy nhất, có interceptor gắn Bearer token).
- Cấu hình môi trường:
  - `API_BASE_URL`, `ENVIRONMENT`, `USE_MOCK`
  - Ưu tiên `--dart-define` > `.env` (flutter_dotenv)
  - Base URL được **normalize** để tránh nhập nhầm kèm path/query/fragment.

### 3.2 Backend API (NestJS)

- API nằm ở `apps/api/` (NestJS + Prisma)
- Endpoint public (dành cho mobile/web):
  - `GET /tides` (theo ngày)
  - `GET /tides/range` (khoảng ngày)
  - `GET /tides/golden-hours`
  - `GET /weather/forecast` (proxy Open‑Meteo; có cache để giảm rate limit)
  - `GET /services`, `GET /combos`, các endpoint booking (tuỳ module)
- Auth (JWT):
  - `POST /auth/login`
  - `POST /auth/register`
  - `POST /auth/refresh`

### 3.3 Nguồn dữ liệu ngoài

- **Open‑Meteo**: dùng cho forecast (có thể gặp **429 Too Many Requests**).
- **Stormglass**: dùng cho sync triều (cần `STORMGLASS_API_KEY` ở env API).

---

## 4) Map màn hình (IA / Screens) & chức năng

### 4.1 Tab bar / Navigation

Bottom tabs (hiện có):
- **Home**
- **Ăn & Ở** (Services)
- **Đặt dịch vụ** (Booking flow / quick booking)

> Goal của redesign: giữ tab đơn giản, CTA rõ, ưu tiên “đi biển hôm nay/ngày mai”.

### 4.2 Home (màn hình chính)

Chức năng chính:
- **Tải dữ liệu tổng hợp 7 ngày**:
  - Triều hôm nay
  - Triều 7 ngày (range)
  - Khung triều vàng 7 ngày
  - Thời tiết 7 ngày
- **Hiển thị 2 card nổi bật**:
  - “Hôm nay (ưu tiên)”
  - “Ngày mai (chuẩn bị sớm)”
  - Mỗi card: Go score + nhiệt độ (min/max) + gió + mưa + giờ triều thấp (nếu có)
- **Section 7 ngày**:
  - Chip ngang 7 ngày: score + verdict + badge “Triều vàng” + highlight “điểm cao nhất tuần”
  - “Chi tiết từng ngày”: breakdown nhiệt độ/mưa/gió + triều thấp + note triều vàng
- **Quick actions**:
  - Ăn & Ở
  - Xe xích
  - Chụp ảnh + Flycam
- **Refresh**: kéo xuống hoặc nút refresh trên AppBar

Trạng thái lỗi cần UX:
- Nếu **thời tiết fail** (429/500): vẫn render triều/golden-hours; weather có thể trống và nên có hint “thời tiết tạm không có”.
- Nếu **triều fail**: hiển thị message rõ và CTA “Thử lại”.
- Nếu **mất mạng**: thông báo offline + retry.

### 4.3 Services (Ăn & Ở)

Chức năng:
- List dịch vụ/điểm đến/khách sạn/món ăn/combo
- Search/filter (tuỳ scope)
- Detail: ảnh, mô tả, giá, CTA đặt

### 4.4 Booking flow (Đặt dịch vụ)

Chức năng:
- Chọn dịch vụ/combo
- Chọn ngày/giờ/số lượng/người liên hệ
- Xác nhận booking
- Xem booking của tôi (nếu đăng nhập)

Trạng thái:
- Chưa đăng nhập: prompt login
- Đã đăng nhập: lưu session, refresh token

### 4.5 Auth (Login/Register/Account)

Chức năng:
- Login / Register
- Refresh token tự động khi 401 (trừ endpoints public auth)
- Account screen (hồ sơ, đăng xuất)

---

## 5) Mapping API endpoints (để design hiểu data)

Home (tổng hợp):
- `GET /tides?date=YYYY-MM-DD`
- `GET /tides/range?from=YYYY-MM-DD&to=YYYY-MM-DD`
- `GET /tides/golden-hours?from=YYYY-MM-DD&to=YYYY-MM-DD`
- `GET /weather/forecast?lat=...&lon=...`

Auth:
- `POST /auth/login`
- `POST /auth/register`
- `POST /auth/refresh`

Services/Combos/Bookings (tuỳ module backend):
- `GET /services`
- `GET /combos`
- booking endpoints (nếu app đang dùng)

Response envelope (Nest API):
- Thành công: `{ success: true, data: ..., message: "OK", meta?: ... }`
- Lỗi: `{ success: false, data: null, message: "...", meta?: ... }`

Weather payload fields (backend hiện trả **cả 2 kiểu tên** để tương thích):
- Recommended: `tempMinC`, `tempMaxC`, `windMaxKmh`, `precipitationMm`, `humidityPct`
- Legacy alias (mobile đang dùng): `tempMin`, `tempMax`, `windSpeedMax`, `precipitationSum`

---

## 6) Non-functional requirements (NFR)

- **Độ ưu tiên**: Home phải “lên” nhanh, không bị fail toàn màn vì 1 nguồn (weather).
- **Offline/mạng yếu**: có retry, timeout hợp lý, message ngắn gọn.
- **Internationalization**: hiện chủ yếu tiếng Việt; design nên hỗ trợ text dài/ngắn.
- **Accessibility**: contrast tốt (dark background), font size linh hoạt.
- **Performance**: list 7 ngày không lag; skeleton loading nhẹ.

---

## 7) Design direction (gợi ý cho Lovable)

- Mood: **biển đêm / bình minh** (dark + accent warm gold/blue).
- Home: 1 “hero card” rõ ràng cho “Hôm nay”, CTA “Mở Maps”.
- 7 ngày: chip + detail card có hierarchy tốt; số score nổi bật nhưng giải thích ngắn.
- Error states: không “đổ lỗi kỹ thuật”; dùng copy thân thiện + CTA retry.

---

## 8) Deliverables mong muốn từ Lovable

- **UI kit**: colors, typography, spacing, components (cards/chips/badges/buttons).
- **Redesign screens**:
  - Home (loading/empty/error/partial-data states)
  - Services list + detail (tối thiểu)
  - Booking flow (tối thiểu 3 bước)
  - Auth screens
- **Prototype** (Figma) + annotations mapping data/API.

---

## 9) Handoff để “đồng bộ vào project luôn” (PR-ready integration)

Mục tiêu: Lovable làm xong **mở PR và merge thẳng** vào repo, không cần làm lại từ Figma.

### 9.1 Output bắt buộc

- **Tạo Pull Request** vào repo `bien-vo-cuc`, base branch `main`.
- **Scope thay đổi**: chỉ trong `apps/mobile/` (Flutter).
- **Không đổi API contract** (response envelope `{success,data,message,meta}`) và các endpoint chính ở mục (5).
- **Không hardcode môi trường**: đọc `API_BASE_URL`/`ENVIRONMENT`/`USE_MOCK` qua `--dart-define` hoặc `.env` theo cơ chế sẵn có.
- Nếu thêm dependency mới: cập nhật `apps/mobile/pubspec.yaml` + ghi rõ “why” trong PR description.

### 9.2 Quy ước design → code (để maintain được)

- **Design tokens / components đặt trong `bvc_ui`**:
  - `apps/mobile/packages/bvc_ui/lib/src/app_theme.dart`: colors, typography, spacing, radius, elevations.
  - Tạo component dùng chung (nếu cần): `AppCard`, `AppChip`, `AppButton`, `EmptyState`, `ErrorState`, `Skeleton`.
- **Screen không hardcode style**: ưu tiên dùng theme + component.

### 9.3 Vị trí file cần sửa (để match kiến trúc hiện tại)

- Home redesign:
  - `apps/mobile/packages/bvc_home/lib/src/presentation/screens/home_screen.dart`
  - `apps/mobile/packages/bvc_home/lib/src/presentation/widgets/*`
- Networking/repositories: không tạo Dio mới; dùng `NetworkService` hiện có.
- Routing: giữ nguyên `go_router` paths hiện tại; nếu thêm màn hình phải add route rõ ràng.

### 9.4 Acceptance checklist (bạn test nhanh sau khi merge)

- Chạy được local:
  - `cd apps/mobile && flutter pub get`
  - `flutter analyze` (không lỗi)
  - `flutter test` (pass)
  - `flutter run`
- Home:
  - Có loading state, error state, **partial-data state** (weather 429 vẫn thấy triều).
  - Không crash khi API trả 429/500.
  - Copy UX rõ ràng, không lộ thông tin kỹ thuật thừa.

### 9.5 Lệnh Lovable phải chạy trước khi gửi PR

```bash
cd apps/mobile
flutter pub get
flutter analyze
flutter test
flutter run
```

