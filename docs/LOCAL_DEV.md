# Chạy full stack local (Biển Vô Cực)

## Cổng chuẩn trong repo

| Thành phần | Cổng mặc định | Ghi chú |
|------------|---------------|---------|
| **API Nest** | **3001** | `apps/api/.env.dev` → `PORT`; Swagger: `http://127.0.0.1:3001/docs` |
| **Web (Vite)** | **8080** | Proxy `/api` → `VITE_API_PROXY_TARGET` (mặc định `http://127.0.0.1:3001`) |
| **Admin (Next.js)** | **3000** | `NEXT_PUBLIC_API_BASE_URL` (hoặc `NEXT_PUBLIC_API_URL`) → API |
| **Postgres (Docker)** | **5433** | Map ra máy host (container vẫn dùng 5432) |
| **Redis (Docker)** | **6379** | |

Flutter/mobile: `cp apps/mobile/.env.example apps/mobile/.env`, chỉnh `API_BASE_URL` nếu cần (xem `apps/mobile/packages/bvc_network`).

---

## 1. Yêu cầu

- Node.js (LTS), npm
- Docker Desktop (hoặc Docker Engine) cho Postgres + Redis

---

## 2. Hạ tầng (Postgres + Redis)

Từ thư mục gốc repo `bien-vo-cuc`:

```bash
docker compose up -d
```

Đợi container `healthy` (Postgres).

---

## 3. Backend API

**Prisma (`migrate dev`, v.v.)** chỉ đọc file tên `.env` trong `apps/api/`. Trước khi chạy `prisma migrate dev` (hoặc bất kỳ lệnh Prisma nào cần `DATABASE_URL`), từ **thư mục gốc repo**:

```bash
cp apps/api/.env.dev apps/api/.env
```

File `apps/api/.env` nằm trong `.gitignore` (không lo commit nhầm).

```bash
cd apps/api
cp .env.example .env.dev
# Sau khi chỉnh .env.dev, đồng bộ sang .env cho Prisma (lệnh trên hoặc: cp .env.dev .env)
cp .env.dev .env
# Chỉnh DATABASE_URL / JWT_* nếu cần; mặc định khớp docker-compose (port 5433).
npm install
npm run prisma:generate
npm run prisma:migrate
# hoặc lần đầu: npm run prisma:migrate  (tạo migration)
npm run seed
npm run start:dev
```

Giữ terminal này mở — phải thấy API đang listen (thường **3001**).

---

## 4. Website khách (Vite)

Terminal mới:

```bash
cd apps/web
cp .env.example .env.development
# Tùy chọn: chỉ khi API không chạy ở 3001:
# echo 'VITE_API_PROXY_TARGET=http://127.0.0.1:XXXX' >> .env.development
npm install
npm run dev
```

Mở `http://localhost:8080/`. Không cần mock nếu API đã chạy.

Chỉ giao diện demo (không API): trong `.env.development` thêm `VITE_USE_MOCK=true`.

---

## 5. Admin (Next.js)

Terminal mới:

```bash
cd apps/admin
cp .env.example .env.local
npm install
npm run dev
```

Mở URL Next in ra (thường `http://localhost:3000`). Đảm bảo `NEXT_PUBLIC_API_BASE_URL` (hoặc `NEXT_PUBLIC_API_URL`) trùng cổng API.

---

## 6. Mobile (Flutter)

API phải chạy; thiết bị/emulator trỏ tới đúng host (LAN IP hoặc `adb reverse` — xem `run_demo_android.sh`).

---

## Sự cố thường gặp

- **`ECONNREFUSED` / không tải dịch vụ trên web:** API chưa chạy hoặc sai cổng — bật `npm run start:dev` trong `apps/api`, kiểm tra `http://127.0.0.1:3001/docs`.
- **Prisma / DB:** Postgres chưa lên hoặc `DATABASE_URL` sai (port **5433** trên host khi dùng compose mẫu).
- **Cổng bận:** Đổi `PORT` trong `apps/api/.env.dev` và cập nhật `VITE_API_PROXY_TARGET`, `NEXT_PUBLIC_API_BASE_URL`, Flutter `.env` / `--dart-define` cho khớp.
