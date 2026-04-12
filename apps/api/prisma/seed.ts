import 'dotenv/config';

import * as bcrypt from 'bcryptjs';
import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';

const databaseUrl = process.env.DATABASE_URL;
if (!databaseUrl) {
  throw new Error('Missing DATABASE_URL in environment');
}

// Prisma v7 requires an adapter (or accelerateUrl) at runtime.
const prisma = new PrismaClient({
  adapter: new PrismaPg(databaseUrl),
});

async function main() {
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const days = 7;
  const schedules = Array.from({ length: days }).map((_, i) => {
    const date = new Date(today);
    date.setDate(today.getDate() + i);

    const lowTime1 = new Date(date);
    lowTime1.setHours(5, 20 + i, 0, 0);

    const lowTime2 = new Date(date);
    lowTime2.setHours(17, 45 + i, 0, 0);

    return {
      date,
      lowTime1,
      lowHeight1: 0.6 + i * 0.03,
      lowTime2,
      lowHeight2: 0.7 + i * 0.02,
      isGolden: i % 2 === 0,
      note: i % 2 === 0 ? 'Khung giờ vàng (seed)' : null,
    };
  });

  for (const s of schedules) {
    await prisma.tideSchedule.upsert({
      where: { date: s.date },
      update: {
        lowTime1: s.lowTime1,
        lowHeight1: s.lowHeight1,
        lowTime2: s.lowTime2,
        lowHeight2: s.lowHeight2,
        isGolden: s.isGolden,
        note: s.note ?? undefined,
      },
      create: s,
    });
  }

  const demoHash = bcrypt.hashSync('demo1234', 10);

  const providers = [
    { id: 'seed-provider-hotel', name: 'NCC Homestay / nhà nghỉ', phone: '0900000001' },
    { id: 'seed-provider-food', name: 'NCC Ăn uống', phone: '0900000002' },
    { id: 'seed-provider-transport', name: 'NCC Xe / vận chuyển', phone: '0900000003' },
    { id: 'seed-provider-photo', name: 'NCC Chụp ảnh / flycam', phone: '0900000004' },
  ] as const;

  for (const p of providers) {
    await prisma.provider.upsert({
      where: { id: p.id },
      update: { name: p.name, phone: p.phone },
      create: { id: p.id, name: p.name, phone: p.phone },
    });
  }

  await prisma.user.upsert({
    where: { email: 'admin@bienvocuc.local' },
    update: { passwordHash: demoHash, role: 'ADMIN', providerId: null, userKind: 'SYSTEM_STAFF' },
    create: {
      email: 'admin@bienvocuc.local',
      name: 'Admin Demo',
      passwordHash: demoHash,
      role: 'ADMIN',
      userKind: 'SYSTEM_STAFF',
    },
  });

  const merchants = [
    { email: 'merchant.hotel@bienvocuc.local', name: 'Merchant Homestay', providerId: 'seed-provider-hotel' },
    { email: 'merchant.food@bienvocuc.local', name: 'Merchant Ăn uống', providerId: 'seed-provider-food' },
    { email: 'merchant.transport@bienvocuc.local', name: 'Merchant Xe', providerId: 'seed-provider-transport' },
    { email: 'merchant.photo@bienvocuc.local', name: 'Merchant Chụp ảnh', providerId: 'seed-provider-photo' },
  ] as const;

  for (const m of merchants) {
    await prisma.user.upsert({
      where: { email: m.email },
      update: {
        passwordHash: demoHash,
        role: 'MERCHANT',
        providerId: m.providerId,
        name: m.name,
        userKind: 'PROVIDER_ACCOUNT',
      },
      create: {
        email: m.email,
        name: m.name,
        passwordHash: demoHash,
        role: 'MERCHANT',
        providerId: m.providerId,
        userKind: 'PROVIDER_ACCOUNT',
      },
    });
  }

  // Seed services (ăn uống, ngủ nghỉ, xe, chụp ảnh) — gắn NCC.
  await prisma.service.upsert({
    where: { id: 'seed-accom-1' },
    update: {
      providerId: 'seed-provider-hotel',
      addressLine: 'Thôn Quang Lang, xã Đông Thụy Anh, huyện Ân Thi, tỉnh Hưng Yên',
      locationSummary: 'Cách bãi ~800m • có chỗ để xe • wifi',
      images: [
        'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',
        'https://images.unsplash.com/photo-1611892440504-42a792e54d4d?w=800&q=80',
      ],
    },
    create: {
      id: 'seed-accom-1',
      type: 'ACCOMMODATION',
      providerId: 'seed-provider-hotel',
      name: 'Homestay Quang Lang',
      description: 'Gần biển, sạch sẽ, phù hợp đi săn bình minh.',
      price: 350000,
      maxCapacity: 4,
      addressLine: 'Thôn Quang Lang, xã Đông Thụy Anh, huyện Ân Thi, tỉnh Hưng Yên',
      locationSummary: 'Cách bãi ~800m • có chỗ để xe • wifi',
      images: [
        'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',
        'https://images.unsplash.com/photo-1611892440504-42a792e54d4d?w=800&q=80',
      ],
      isActive: true,
    },
  });

  await prisma.service.upsert({
    where: { id: 'seed-accom-2' },
    update: {
      providerId: 'seed-provider-hotel',
      addressLine: 'QL39, gần thị trấn Diêm Điền, huyện Ân Thi, tỉnh Hưng Yên',
      locationSummary: 'Gần quốc lộ • phòng mới sơn',
      images: [
        'https://images.unsplash.com/photo-1631049307264-da0ec9ad7038?w=800&q=80',
        'https://images.unsplash.com/photo-1598928506311-c55ded91a20c?w=800&q=80',
      ],
    },
    create: {
      id: 'seed-accom-2',
      type: 'ACCOMMODATION',
      providerId: 'seed-provider-hotel',
      name: 'Nhà nghỉ Thái Thụy',
      description: 'Giá hợp lý, tiện xuất phát sớm.',
      price: 250000,
      maxCapacity: 2,
      addressLine: 'QL39, gần thị trấn Diêm Điền, huyện Ân Thi, tỉnh Hưng Yên',
      locationSummary: 'Gần quốc lộ • phòng mới sơn',
      images: [
        'https://images.unsplash.com/photo-1631049307264-da0ec9ad7038?w=800&q=80',
        'https://images.unsplash.com/photo-1598928506311-c55ded91a20c?w=800&q=80',
      ],
      isActive: true,
    },
  });

  const imgRoom =
    'https://images.unsplash.com/photo-1631049307264-da0ec9ad7038?w=600&q=80';
  /** Nhiều phòng cùng loại để app demo: còn trống / đặt đoàn (2 đơn + 1 đôi + …). */
  const roomsAc1 = [
    { code: '101', name: 'Phòng đơn view vườn', roomType: 'SINGLE' as const, maxGuests: 1, floor: 1, sortOrder: 1 },
    { code: '103', name: 'Phòng đơn góc yên tĩnh', roomType: 'SINGLE' as const, maxGuests: 1, floor: 1, sortOrder: 2 },
    { code: '104', name: 'Phòng đơn tầng 1', roomType: 'SINGLE' as const, maxGuests: 1, floor: 1, sortOrder: 3 },
    { code: '102', name: 'Phòng đôi giường Queen', roomType: 'DOUBLE' as const, maxGuests: 2, floor: 1, sortOrder: 4 },
    { code: '105', name: 'Phòng đôi ban công', roomType: 'DOUBLE' as const, maxGuests: 2, floor: 1, sortOrder: 5 },
    { code: '106', name: 'Phòng đôi cửa sổ lớn', roomType: 'DOUBLE' as const, maxGuests: 2, floor: 2, sortOrder: 6 },
    { code: '107', name: 'Phòng đôi tiêu chuẩn', roomType: 'DOUBLE' as const, maxGuests: 2, floor: 2, sortOrder: 7 },
    { code: '201', name: 'Phòng gia đình 2 giường', roomType: 'FAMILY' as const, maxGuests: 4, floor: 2, sortOrder: 8 },
    { code: '202', name: 'Phòng gia đình gầm mái', roomType: 'FAMILY' as const, maxGuests: 4, floor: 3, sortOrder: 9 },
  ];
  for (const r of roomsAc1) {
    await prisma.room.upsert({
      where: { serviceId_code: { serviceId: 'seed-accom-1', code: r.code } },
      update: {
        name: r.name,
        roomType: r.roomType,
        maxGuests: r.maxGuests,
        floor: r.floor,
        sortOrder: r.sortOrder,
        images: [imgRoom],
      },
      create: {
        serviceId: 'seed-accom-1',
        code: r.code,
        name: r.name,
        roomType: r.roomType,
        maxGuests: r.maxGuests,
        floor: r.floor,
        sortOrder: r.sortOrder,
        images: [imgRoom],
      },
    });
  }

  const roomsAc2 = [
    { code: 'A1', name: 'Phòng đôi tiêu chuẩn', roomType: 'DOUBLE' as const, maxGuests: 2, floor: 1, sortOrder: 1 },
    { code: 'B1', name: 'Phòng đôi gần cầu thang', roomType: 'DOUBLE' as const, maxGuests: 2, floor: 1, sortOrder: 2 },
    { code: 'B2', name: 'Phòng đôi cuối hành lang', roomType: 'DOUBLE' as const, maxGuests: 2, floor: 2, sortOrder: 3 },
    { code: 'A2', name: 'Phòng 2 giường đơn', roomType: 'TWIN' as const, maxGuests: 2, floor: 1, sortOrder: 4 },
    { code: 'C1', name: 'Phòng 2 giường đơn sáng', roomType: 'TWIN' as const, maxGuests: 2, floor: 2, sortOrder: 5 },
  ];
  for (const r of roomsAc2) {
    await prisma.room.upsert({
      where: { serviceId_code: { serviceId: 'seed-accom-2', code: r.code } },
      update: {
        name: r.name,
        roomType: r.roomType,
        maxGuests: r.maxGuests,
        floor: r.floor,
        sortOrder: r.sortOrder,
        images: [imgRoom],
      },
      create: {
        serviceId: 'seed-accom-2',
        code: r.code,
        name: r.name,
        roomType: r.roomType,
        maxGuests: r.maxGuests,
        floor: r.floor,
        sortOrder: r.sortOrder,
        images: [imgRoom],
      },
    });
  }

  await prisma.service.upsert({
    where: { id: 'seed-food-1' },
    update: {
      providerId: 'seed-provider-food',
      images: [
        'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&q=80',
        'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=800&q=80',
      ],
    },
    create: {
      id: 'seed-food-1',
      type: 'FOOD',
      providerId: 'seed-provider-food',
      name: 'Bún cá Thái Bình',
      description: 'Ăn nóng trước khi ra biển sáng sớm.',
      price: 35000,
      maxCapacity: 1,
      images: [
        'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&q=80',
        'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=800&q=80',
      ],
      isActive: true,
    },
  });

  await prisma.service.upsert({
    where: { id: 'seed-food-2' },
    update: {
      providerId: 'seed-provider-food',
      images: [
        'https://images.unsplash.com/photo-1559339352-11d035aa65de?w=800&q=80',
        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800&q=80',
      ],
    },
    create: {
      id: 'seed-food-2',
      type: 'FOOD',
      providerId: 'seed-provider-food',
      name: 'Hải sản địa phương',
      description: 'Tôm, cá, ngao tươi theo mùa.',
      price: 150000,
      maxCapacity: 2,
      images: [
        'https://images.unsplash.com/photo-1559339352-11d035aa65de?w=800&q=80',
        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800&q=80',
      ],
      isActive: true,
    },
  });

  await prisma.service.upsert({
    where: { id: 'seed-vehicle-1' },
    update: { providerId: 'seed-provider-transport' },
    create: {
      id: 'seed-vehicle-1',
      type: 'VEHICLE',
      providerId: 'seed-provider-transport',
      name: 'Xe xích ra bãi (1 chiều)',
      description: 'Dành cho ai không muốn lội bùn 1–3km.',
      price: 50000,
      maxCapacity: 2,
      images: [],
      isActive: true,
    },
  });

  await prisma.service.upsert({
    where: { id: 'seed-tour-1' },
    update: { providerId: 'seed-provider-photo' },
    create: {
      id: 'seed-tour-1',
      type: 'TOUR',
      providerId: 'seed-provider-photo',
      name: 'Chụp ảnh + Flycam (30 phút)',
      description: 'Ekip hỗ trợ pose + quay flycam, ưu tiên khung giờ bình minh.',
      price: 300000,
      maxCapacity: 2,
      images: [],
      isActive: true,
    },
  });

  await prisma.combo.upsert({
    where: {
      hotelServiceId_foodServiceId: {
        hotelServiceId: 'seed-accom-1',
        foodServiceId: 'seed-food-1',
      },
    },
    update: {
      title: 'Combo Homestay + Bún cá',
      discountPercent: 15,
      isActive: true,
    },
    create: {
      id: 'seed-combo-1',
      hotelServiceId: 'seed-accom-1',
      foodServiceId: 'seed-food-1',
      title: 'Combo Homestay + Bún cá',
      discountPercent: 15,
      isActive: true,
    },
  });
}

main()
  .then(async () => {
    await prisma.$disconnect();
  })
  .catch(async (e) => {
    console.error(e);
    await prisma.$disconnect();
    process.exit(1);
  });

