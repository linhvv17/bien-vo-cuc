import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma, RoomType, ServiceType } from '@prisma/client';

import { PrismaService } from '../prisma/prisma.service';
import { CreateRoomDto, UpdateRoomDto } from './dto/mutate-room.dto';
import { CreateServiceDto, UpdateServiceDto } from './dto/mutate-service.dto';
import { GUEST_PREFERENCE_OPTIONS } from './guest-preferences';

function parseYmdLocal(ymd: string): Date {
  const [y, m, d] = ymd.split('-').map(Number);
  return new Date(y, m - 1, d, 0, 0, 0, 0);
}

const ROOM_TYPE_LABEL_VI: Record<RoomType, string> = {
  SINGLE: 'Phòng đơn',
  DOUBLE: 'Phòng đôi',
  TWIN: 'Phòng đôi (2 giường đơn)',
  FAMILY: 'Phòng gia đình',
  DORM: 'Tập thể / dorm',
  SUITE: 'Suite',
  QUAD: 'Phòng 4 người',
};

@Injectable()
export class ServicesService {
  constructor(private readonly prisma: PrismaService) {}

  async list(params: { type?: ServiceType; page?: number; limit?: number }) {
    const page = params.page && params.page > 0 ? params.page : 1;
    const limit =
      params.limit && params.limit > 0 ? Math.min(params.limit, 50) : 20;
    const skip = (page - 1) * limit;

    const where: Prisma.ServiceWhereInput = {
      isActive: true,
      ...(params.type ? { type: params.type } : {}),
    };

    const [items, total] = await Promise.all([
      this.prisma.service.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
        include: { provider: true },
      }),
      this.prisma.service.count({ where }),
    ]);

    return { items, total, page, limit };
  }

  async combo() {
    const [accommodations, foods] = await Promise.all([
      this.prisma.service.findMany({
        where: { isActive: true, type: 'ACCOMMODATION' },
        orderBy: { createdAt: 'desc' },
        take: 10,
      }),
      this.prisma.service.findMany({
        where: { isActive: true, type: 'FOOD' },
        orderBy: { createdAt: 'desc' },
        take: 10,
      }),
    ]);

    return { accommodations, foods };
  }

  async combos(params?: { limit?: number }) {
    const limit =
      params?.limit && params.limit > 0 ? Math.min(params.limit, 30) : 12;

    const [hotels, foods] = await Promise.all([
      this.prisma.service.findMany({
        where: { isActive: true, type: 'ACCOMMODATION' },
        orderBy: { createdAt: 'desc' },
        take: 10,
      }),
      this.prisma.service.findMany({
        where: { isActive: true, type: 'FOOD' },
        orderBy: { createdAt: 'desc' },
        take: 10,
      }),
    ]);

    const combos = [];
    for (const h of hotels) {
      for (const f of foods) {
        const originalTotal = h.price + f.price;
        // MVP discount rule (simple + readable):
        // - default 10%
        // - 15% if total >= 400k
        // - 20% if total >= 600k
        let discountPercent = 10;
        if (originalTotal >= 600000) discountPercent = 20;
        else if (originalTotal >= 400000) discountPercent = 15;

        const discountedTotal = Math.round(
          (originalTotal * (100 - discountPercent)) / 100,
        );
        combos.push({
          id: `combo_${h.id}_${f.id}`,
          hotel: h,
          food: f,
          originalTotal,
          discountedTotal,
          discountPercent,
          saved: originalTotal - discountedTotal,
        });
      }
    }

    combos.sort((a, b) => a.discountedTotal - b.discountedTotal);
    return combos.slice(0, limit);
  }

  async create(dto: CreateServiceDto) {
    return this.prisma.service.create({
      data: {
        type: dto.type as ServiceType,
        name: dto.name,
        description: dto.description,
        price: dto.price,
        maxCapacity: dto.maxCapacity,
        images: dto.images ?? [],
        isActive: dto.isActive ?? true,
      },
    });
  }

  async update(id: string, dto: UpdateServiceDto) {
    return this.prisma.service.update({
      where: { id },
      data: {
        ...(dto.type ? { type: dto.type as ServiceType } : {}),
        ...(dto.name !== undefined ? { name: dto.name } : {}),
        ...(dto.description !== undefined
          ? { description: dto.description }
          : {}),
        ...(dto.price !== undefined ? { price: dto.price } : {}),
        ...(dto.maxCapacity !== undefined
          ? { maxCapacity: dto.maxCapacity }
          : {}),
        ...(dto.images !== undefined ? { images: dto.images } : {}),
        ...(dto.isActive !== undefined ? { isActive: dto.isActive } : {}),
      },
    });
  }

  async softDelete(id: string) {
    return this.prisma.service.update({
      where: { id },
      data: { isActive: false },
    });
  }

  /** Chi tiết khách sạn/nhà nghỉ: phòng + còn trống theo ngày. */
  async getAccommodationDetail(serviceId: string, dateYmd: string) {
    const service = await this.prisma.service.findFirst({
      where: { id: serviceId, isActive: true, type: ServiceType.ACCOMMODATION },
      include: {
        provider: true,
        rooms: {
          where: { isActive: true },
          orderBy: [{ sortOrder: 'asc' }, { code: 'asc' }],
        },
      },
    });
    if (!service) throw new NotFoundException('Không tìm thấy cơ sở lưu trú');

    const day = parseYmdLocal(dateYmd);

    const baseNight = service.price;

    const rooms = await Promise.all(
      service.rooms.map(async (r) => {
        const booked = await this.prisma.booking.count({
          where: {
            roomId: r.id,
            date: day,
            status: { not: 'CANCELLED' },
          },
        });
        const available = booked === 0;
        const pricePerNight = r.pricePerNight ?? baseNight;
        return {
          id: r.id,
          code: r.code,
          name: r.name,
          roomType: r.roomType,
          maxGuests: r.maxGuests,
          floor: r.floor,
          images: r.images,
          pricePerNight,
          available,
          availableCount: available ? 1 : 0,
        };
      }),
    );

    const byType = new Map<
      RoomType,
      {
        availableCount: number;
        inventory: number;
        maxGuests: number;
        minPrice: number | null;
      }
    >();
    for (const r of rooms) {
      const rt = r.roomType;
      if (!byType.has(rt)) {
        byType.set(rt, {
          availableCount: 0,
          inventory: 0,
          maxGuests: r.maxGuests,
          minPrice: null,
        });
      }
      const g = byType.get(rt)!;
      g.inventory += 1;
      g.availableCount += r.available ? 1 : 0;
      g.maxGuests = Math.max(g.maxGuests, r.maxGuests);
      const p = r.pricePerNight;
      if (g.minPrice == null || p < g.minPrice) g.minPrice = p;
    }

    const roomTypeGroups = Array.from(byType.entries()).map(
      ([roomType, s]) => ({
        roomType,
        labelVi: ROOM_TYPE_LABEL_VI[roomType] ?? roomType,
        availableCount: s.availableCount,
        inventory: s.inventory,
        maxGuests: s.maxGuests,
        pricePerNight: s.minPrice ?? baseNight,
      }),
    );

    return {
      service: {
        id: service.id,
        name: service.name,
        description: service.description,
        price: service.price,
        maxCapacity: service.maxCapacity,
        images: service.images,
        addressLine: service.addressLine,
        locationSummary: service.locationSummary,
        provider: service.provider
          ? {
              id: service.provider.id,
              name: service.provider.name,
              phone: service.provider.phone,
              address: service.provider.address,
            }
          : null,
      },
      rooms,
      roomTypeGroups,
      preferenceOptions: [...GUEST_PREFERENCE_OPTIONS],
    };
  }

  private async requireAccommodationService(serviceId: string) {
    const s = await this.prisma.service.findFirst({
      where: { id: serviceId, isActive: true, type: ServiceType.ACCOMMODATION },
    });
    if (!s) {
      throw new NotFoundException('Không tìm thấy cơ sở lưu trú hoặc đã tắt.');
    }
    return s;
  }

  async listRoomsForService(serviceId: string) {
    await this.requireAccommodationService(serviceId);
    return this.prisma.room.findMany({
      where: { serviceId },
      orderBy: [{ sortOrder: 'asc' }, { code: 'asc' }],
    });
  }

  async createRoom(serviceId: string, dto: CreateRoomDto) {
    await this.requireAccommodationService(serviceId);
    try {
      return await this.prisma.room.create({
        data: {
          serviceId,
          code: dto.code.trim(),
          name: dto.name.trim(),
          roomType: dto.roomType,
          maxGuests: dto.maxGuests,
          floor: dto.floor,
          sortOrder: dto.sortOrder ?? 0,
          pricePerNight:
            dto.pricePerNight !== undefined ? dto.pricePerNight : null,
          images: dto.images ?? [],
        },
      });
    } catch (e) {
      if (
        e instanceof Prisma.PrismaClientKnownRequestError &&
        e.code === 'P2002'
      ) {
        throw new BadRequestException(
          'Mã phòng (code) đã tồn tại trong cơ sở này.',
        );
      }
      throw e;
    }
  }

  async updateRoom(serviceId: string, roomId: string, dto: UpdateRoomDto) {
    await this.requireAccommodationService(serviceId);
    const existing = await this.prisma.room.findFirst({
      where: { id: roomId, serviceId },
    });
    if (!existing) {
      throw new NotFoundException('Không tìm thấy phòng.');
    }
    try {
      return await this.prisma.room.update({
        where: { id: roomId },
        data: {
          ...(dto.code !== undefined ? { code: dto.code.trim() } : {}),
          ...(dto.name !== undefined ? { name: dto.name.trim() } : {}),
          ...(dto.roomType !== undefined ? { roomType: dto.roomType } : {}),
          ...(dto.maxGuests !== undefined ? { maxGuests: dto.maxGuests } : {}),
          ...(dto.floor !== undefined ? { floor: dto.floor } : {}),
          ...(dto.sortOrder !== undefined ? { sortOrder: dto.sortOrder } : {}),
          ...(dto.pricePerNight !== undefined
            ? { pricePerNight: dto.pricePerNight }
            : {}),
          ...(dto.images !== undefined ? { images: dto.images } : {}),
          ...(dto.isActive !== undefined ? { isActive: dto.isActive } : {}),
        },
      });
    } catch (e) {
      if (
        e instanceof Prisma.PrismaClientKnownRequestError &&
        e.code === 'P2002'
      ) {
        throw new BadRequestException(
          'Mã phòng (code) đã tồn tại trong cơ sở này.',
        );
      }
      throw e;
    }
  }

  async softDeleteRoom(serviceId: string, roomId: string) {
    await this.requireAccommodationService(serviceId);
    const existing = await this.prisma.room.findFirst({
      where: { id: roomId, serviceId },
    });
    if (!existing) {
      throw new NotFoundException('Không tìm thấy phòng.');
    }
    return this.prisma.room.update({
      where: { id: roomId },
      data: { isActive: false },
    });
  }
}
