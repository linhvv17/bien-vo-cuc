/**
 * Tạo / cập nhật user ADMIN. Cần DATABASE_URL trong apps/api/.env
 *
 *   cd apps/api && ADMIN_EMAIL=a@b.com ADMIN_PASSWORD='matkhau8kitu' npm run create-admin
 */
import 'dotenv/config';

import * as bcrypt from 'bcryptjs';
import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';

const databaseUrl = process.env.DATABASE_URL;
if (!databaseUrl) {
  console.error('Thiếu DATABASE_URL (apps/api/.env).');
  process.exit(1);
}

const prisma = new PrismaClient({
  adapter: new PrismaPg(databaseUrl),
});

async function main() {
  const email = (process.env.ADMIN_EMAIL ?? 'admin@bienvocuc.local').trim().toLowerCase();
  const password = process.env.ADMIN_PASSWORD?.trim();
  if (!password || password.length < 8) {
    console.error('Thiếu ADMIN_PASSWORD (tối thiểu 8 ký tự).');
    process.exit(1);
  }

  const passwordHash = bcrypt.hashSync(password, 10);
  const user = await prisma.user.upsert({
    where: { email },
    update: {
      passwordHash,
      role: 'ADMIN',
      userKind: 'SYSTEM_STAFF',
      providerId: null,
      name: process.env.ADMIN_NAME?.trim() || 'Quản trị viên',
    },
    create: {
      email,
      name: process.env.ADMIN_NAME?.trim() || 'Quản trị viên',
      passwordHash,
      role: 'ADMIN',
      userKind: 'SYSTEM_STAFF',
    },
  });
  console.log('Xong. Đăng nhập admin bằng email + mật khẩu vừa đặt.');
  console.log('  Email:', user.email);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
