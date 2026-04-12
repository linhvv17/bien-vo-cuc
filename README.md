# Biển Vô Cực — monorepo

Các app: `apps/api` (NestJS), `apps/web` (Vite + React), `apps/admin` (Next.js), `apps/mobile` (Flutter).

**Chạy local chi tiết:** [docs/LOCAL_DEV.md](docs/LOCAL_DEV.md).

Hạ tầng: `docker compose up -d` (Postgres cổng host **5433**, Redis **6379**).

## Branch & Deploy

Sau khi `git init` / clone, tạo và bảo vệ các nhánh: `main` (production), `uat` (UAT), `dev` (development).

| Branch | Môi trường | URL |
|--------|-----------|-----|
| main   | Production | https://bienvocuc.vn |
| uat    | UAT | https://uat.bienvocuc.vn |
| local  | Dev | Web Vite: **http://localhost:8080** (`apps/web`) |

Push lên `main` / `uat` → GitHub Actions (xem `.github/workflows/`) có thể deploy API (Render hooks), web & admin (Vercel — cần secrets).

## Chạy local

```bash
# Backend (đọc `apps/api/.env.dev` — trước đó: `cp apps/api/.env.example apps/api/.env.dev` và chỉnh)
cd apps/api && npm run start:dev

# Landing web (Vite — cổng 8080)
cd apps/web && npm run dev

# Admin (Next — cổng 3000)
cd apps/admin && npm run dev

# Mobile (cần `cp apps/mobile/.env.example apps/mobile/.env` nếu chưa có asset `.env`)
cd apps/mobile && flutter run
```

## Ghi chú

- **Admin (Next 16):** không còn lệnh `next lint`; dùng `npm run lint` → `eslint .`.
- **API:** Prisma CLI mặc định đọc file tên `.env` — có thể `cp apps/api/.env.dev apps/api/.env` khi chạy `prisma migrate` (cả hai đều nên nằm trong `.gitignore` ở root).
- **Web — Mapbox:** ảnh bản đồ tĩnh dùng `VITE_MAPBOX_PUBLIC_TOKEN` (public `pk.*`, khai báo trong `.env.development` local hoặc biến môi trường trên Vercel). Không hardcode token trong source (GitHub push protection).
- **Git — `apps/admin` là submodule (có `.git` con):** xóa repo lồng nhau rồi add lại toàn bộ file: `rm -rf apps/admin/.git && git rm --cached apps/admin 2>/dev/null; git add apps/admin` rồi commit lại.
- **Push GitHub bị chặn vì secret trong *lịch sử cũ*:** cần rewrite (ví dụ một commit gốc sạch: `git checkout --orphan tmp && git add -A && git commit -m "…" && git branch -D main && git branch -m main`), rồi `git push --force-with-lease origin main` (chỉ khi remote chưa có commit quan trọng khác).
