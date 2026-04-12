/**
 * Seed tối giản cho production: chỉ tạo / cập nhật **một** tài khoản ADMIN.
 *
 *   cd apps/api
 *   ADMIN_EMAIL=... ADMIN_PASSWORD='...' npm run seed:production
 *
 * Cần DATABASE_URL (file .env hoặc biến môi trường trên CI/Render).
 */
import 'dotenv/config';

import * as bcrypt from 'bcryptjs';
import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';

const databaseUrl = process.env.DATABASE_URL;
if (!databaseUrl) {
  throw new Error('Thiếu DATABASE_URL');
}

const rawEmail = process.env.ADMIN_EMAIL?.trim().toLowerCase();
const rawPassword = process.env.ADMIN_PASSWORD?.trim();

if (!rawEmail || !rawEmail.includes('@')) {
  throw new Error('Đặt ADMIN_EMAIL (email hợp lệ)');
}
if (!rawPassword || rawPassword.length < 8) {
  throw new Error('Đặt ADMIN_PASSWORD (tối thiểu 8 ký tự)');
}

const email = rawEmail;
const password = rawPassword;

const prisma = new PrismaClient({
  adapter: new PrismaPg(databaseUrl),
});

async function main() {
  const passwordHash = bcrypt.hashSync(password, 10);
  const name = process.env.ADMIN_NAME?.trim() || 'Administrator';

  await prisma.user.upsert({
    where: { email },
    update: {
      passwordHash,
      role: 'ADMIN',
      userKind: 'SYSTEM_STAFF',
      providerId: null,
      name,
    },
    create: {
      email,
      name,
      passwordHash,
      role: 'ADMIN',
      userKind: 'SYSTEM_STAFF',
    },
  });

  console.log('[seed-production] Đã tạo/cập nhật admin:', email);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
