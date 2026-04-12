# API (NestJS)

## Tạo tài khoản admin

1. Trong **`apps/api/.env`** có `DATABASE_URL=` đúng Supabase (chuỗi copy trong Supabase).

2. Chạy:

```bash
cd apps/api
ADMIN_EMAIL=email-cua-ban@gmail.com ADMIN_PASSWORD='matKhauDu8KyTu' npm run create-admin
```

3. Mở trang **login** của admin → đăng nhập bằng **email + mật khẩu** vừa gõ.

---

**Hoặc** chỉ admin cho **production** (không seed triều/dịch vụ demo):

```bash
ADMIN_EMAIL=ban@gmail.com ADMIN_PASSWORD='matKhauDu8KyTu' npm run seed:production
```

**Hoặc** full demo: `npm run seed` → admin **`admin@bienvocuc.local`** / **`demo1234`**.

---

## File `.env` (Prisma)

Prisma đọc **`apps/api/.env`**. Chưa có: `cp apps/api/.env.example apps/api/.env` rồi sửa.

Chạy API local: `npm run start:dev`.

## Deploy (Render)

Env: `DATABASE_URL`, `JWT_SECRET`, `JWT_REFRESH_SECRET`, … (xem `.env.example`).  
Web/Admin: `NEXT_PUBLIC_API_BASE_URL` = URL API (không `localhost`).  
Sau deploy có migration mới: `prisma migrate deploy`.
