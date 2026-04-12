# API (NestJS)

## Prisma & file `.env`

Prisma CLI mặc định đọc **`apps/api/.env`** (không đọc `.env.dev`).

Trước khi chạy `prisma migrate dev` (hoặc lệnh Prisma cần biến môi trường), từ thư mục gốc monorepo:

```bash
cp apps/api/.env.dev apps/api/.env
```

File `.env` bị gitignore — không commit nhầm.

Chạy API dev: `npm run start:dev` (dùng `apps/api/.env.dev` qua `--env-file` trong `package.json`).
