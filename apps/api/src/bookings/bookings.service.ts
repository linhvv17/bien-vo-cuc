import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { BookingStatus, Prisma, RoomType, ServiceType } from '@prisma/client';
import { randomUUID } from 'node:crypto';

import { PrismaService } from '../prisma/prisma.service';
import { CreatePublicBookingDto } from './dto/create-public-booking.dto';
import { CreatePublicComboBookingDto } from './dto/create-public-combo-booking.dto';
import { ListBookingsQueryDto } from './dto/list-bookings-query.dto';
import { UpdateBookingStatusDto } from './dto/update-booking-status.dto';
import { isMerchantCancelPreset } from './merchant-cancel-presets';

function parseYmdToLocalDate(ymd: string): Date {
  const [y, m, d] = ymd.split('-').map(Number);
  return new Date(y, m - 1, d, 0, 0, 0, 0);
}

/** Chuẩn hóa số điện thoại VN để lưu / tra cứu (0xxxxxxxxx). */
export function normalizePhoneForStorage(input: string): string {
  let d = input.replace(/\D/g, '');
  if (d.startsWith('84')) d = '0' + d.slice(2);
  return d;
}

const bookingInclude = {
  service: { include: { provider: true } },
  combo: { include: { hotel: true, food: true } },
} satisfies Prisma.BookingInclude;

@Injectable()
export class BookingsService {
  constructor(private readonly prisma: PrismaService) {}

  /** Tên + SĐT lưu trên đơn: ưu tiên tài khoản đăng nhập. */
  private async resolveCustomerIdentity(
    userId: string,
    dto: { customerName: string; customerPhone: string },
  ): Promise<{ name: string; phone: string }> {
    const u = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!u) throw new UnauthorizedException('Phiên đăng nhập không hợp lệ.');
    const rawPhone = (u.phone?.trim() || dto.customerPhone).trim();
    const phone = normalizePhoneForStorage(rawPhone);
    if (phone.length < 9) {
      throw new BadRequestException(
        'Tài khoản cần số điện thoại hợp lệ để đặt chỗ.',
      );
    }
    const name = (dto.customerName.trim() || u.name || 'Khách').trim();
    return { name, phone };
  }

  /** Khách không đăng nhập: chỉ dùng họ tên + SĐT trên form. */
  private resolveGuestContact(dto: {
    customerName: string;
    customerPhone: string;
  }): {
    name: string;
    phone: string;
  } {
    const name = (dto.customerName.trim() || 'Khách').trim();
    const phone = normalizePhoneForStorage(dto.customerPhone.trim());
    if (phone.length < 9) {
      throw new BadRequestException('Vui lòng nhập số điện thoại hợp lệ.');
    }
    return { name, phone };
  }

  private async resolveBookingContact(
    userId: string | null,
    dto: { customerName: string; customerPhone: string },
  ): Promise<{ name: string; phone: string }> {
    if (userId) return this.resolveCustomerIdentity(userId, dto);
    return this.resolveGuestContact(dto);
  }

  async createForUser(userId: string | null, dto: CreatePublicBookingDto) {
    const service = await this.prisma.service.findUnique({
      where: { id: dto.serviceId },
      include: {
        rooms: {
          where: { isActive: true },
          orderBy: [{ sortOrder: 'asc' }, { code: 'asc' }],
        },
      },
    });
    if (!service || !service.isActive)
      throw new NotFoundException('Service not found');

    if (service.type !== ServiceType.ACCOMMODATION && dto.roomLines?.length) {
      throw new BadRequestException(
        'Đặt theo loại phòng chỉ áp dụng cho lưu trú.',
      );
    }

    const day = parseYmdToLocalDate(dto.date);
    const prefs = dto.guestPreferences ?? [];
    const hasRooms =
      service.type === ServiceType.ACCOMMODATION && service.rooms.length > 0;

    if (hasRooms && dto.roomLines?.length) {
      return this.createAccommodationMultiRoom(
        userId,
        service,
        dto,
        day,
        prefs,
      );
    }

    const { name: customerName, phone } = await this.resolveBookingContact(
      userId,
      dto,
    );
    const qty = dto.quantity ?? 1;

    if (hasRooms) {
      if (qty !== 1) {
        throw new BadRequestException(
          'Đặt 1 phòng: dùng chọn loại phòng & số lượng, hoặc chỉ đặt 1 đơn vị.',
        );
      }

      const mode = dto.roomAssignment === 'SPECIFIC' ? 'SPECIFIC' : 'RANDOM';

      const isRoomFree = async (roomId: string) => {
        const n = await this.prisma.booking.count({
          where: {
            roomId,
            date: day,
            status: { not: BookingStatus.CANCELLED },
          },
        });
        return n === 0;
      };

      let roomId: string | null = null;

      if (mode === 'SPECIFIC') {
        if (!dto.roomId) {
          throw new BadRequestException(
            'Chọn phòng hoặc đổi sang gán phòng ngẫu nhiên.',
          );
        }
        const room = service.rooms.find((r) => r.id === dto.roomId);
        if (!room)
          throw new BadRequestException('Phòng không thuộc cơ sở này.');
        if (!(await isRoomFree(room.id))) {
          throw new BadRequestException('Phòng đã được đặt cho ngày này.');
        }
        roomId = room.id;
      } else {
        const free: { id: string }[] = [];
        for (const r of service.rooms) {
          if (await isRoomFree(r.id)) free.push({ id: r.id });
        }
        if (free.length === 0) {
          throw new BadRequestException(
            'Không còn phòng trống cho ngày đã chọn.',
          );
        }
        roomId = free[Math.floor(Math.random() * free.length)].id;
      }

      const assignedRoom = service.rooms.find((r) => r.id === roomId);
      const totalPrice =
        (assignedRoom?.pricePerNight ?? service.price) * qty;

      const booking = await this.prisma.booking.create({
        data: {
          userId,
          serviceId: service.id,
          date: day,
          quantity: qty,
          totalPrice,
          customerName,
          customerPhone: phone,
          customerNote: dto.customerNote,
          roomId,
          roomAssignment: mode,
          guestPreferences: prefs,
        },
        include: bookingInclude,
      });
      return { bookingGroupId: null as string | null, bookings: [booking] };
    }

    const totalPrice = service.price * qty;

    const booking = await this.prisma.booking.create({
      data: {
        userId,
        serviceId: service.id,
        date: day,
        quantity: qty,
        totalPrice,
        customerName,
        customerPhone: phone,
        customerNote: dto.customerNote,
        guestPreferences:
          service.type === ServiceType.ACCOMMODATION ? prefs : [],
      },
      include: bookingInclude,
    });
    return { bookingGroupId: null as string | null, bookings: [booking] };
  }

  /** Nhiều phòng / đoàn: mỗi phòng một bản ghi booking, cùng bookingGroupId. */
  private async createAccommodationMultiRoom(
    userId: string | null,
    service: Prisma.ServiceGetPayload<{ include: { rooms: true } }>,
    dto: CreatePublicBookingDto,
    day: Date,
    prefs: string[],
  ) {
    const { name: customerName, phone } = await this.resolveBookingContact(
      userId,
      dto,
    );
    const lines = dto.roomLines!;
    if (lines.length === 0) {
      throw new BadRequestException('Thiếu roomLines.');
    }

    const isRoomFree = async (roomId: string) => {
      const n = await this.prisma.booking.count({
        where: { roomId, date: day, status: { not: BookingStatus.CANCELLED } },
      });
      return n === 0;
    };

    const poolByType = new Map<RoomType, string[]>();
    for (const r of service.rooms) {
      if (!(await isRoomFree(r.id))) continue;
      const rt = r.roomType;
      if (!poolByType.has(rt)) poolByType.set(rt, []);
      poolByType.get(rt)!.push(r.id);
    }

    for (const [, ids] of poolByType) {
      ids.sort((a, b) => {
        const ra = service.rooms.find((x) => x.id === a);
        const rb = service.rooms.find((x) => x.id === b);
        return (ra?.code ?? '').localeCompare(rb?.code ?? '');
      });
    }

    const needByType = new Map<RoomType, number>();
    for (const line of lines) {
      const rt = line.roomType;
      needByType.set(rt, (needByType.get(rt) ?? 0) + line.quantity);
    }
    for (const [rt, need] of needByType) {
      const have = (poolByType.get(rt) ?? []).length;
      if (have < need) {
        throw new BadRequestException(
          `Không đủ phòng loại ${rt}: cần ${need}, còn ${have} phòng trống.`,
        );
      }
    }

    const groupId = randomUUID();
    const nightPriceForRoom = (roomId: string) => {
      const room = service.rooms.find((x) => x.id === roomId);
      if (!room) {
        throw new BadRequestException('Phòng không thuộc cơ sở này.');
      }
      return room.pricePerNight ?? service.price;
    };

    return this.prisma.$transaction(async (tx) => {
      const created: Awaited<ReturnType<typeof tx.booking.create>>[] = [];
      for (const line of lines) {
        const rt = line.roomType;
        const pool = poolByType.get(rt)!;
        for (let i = 0; i < line.quantity; i++) {
          const roomId = pool.shift()!;
          const b = await tx.booking.create({
            data: {
              userId,
              serviceId: service.id,
              date: day,
              quantity: 1,
              totalPrice: nightPriceForRoom(roomId),
              customerName,
              customerPhone: phone,
              customerNote: dto.customerNote,
              roomId,
              roomAssignment: 'SPECIFIC',
              guestPreferences: prefs,
              bookingGroupId: groupId,
            },
            include: bookingInclude,
          });
          created.push(b);
        }
      }
      return { bookingGroupId: groupId, bookings: created };
    });
  }

  async createComboForUser(
    userId: string | null,
    dto: CreatePublicComboBookingDto,
  ) {
    const combo = await this.prisma.combo.findFirst({
      where: { id: dto.comboId, isActive: true },
      include: { hotel: true, food: true },
    });
    if (!combo) throw new NotFoundException('Combo not found');

    const hotel = combo.hotel;
    const food = combo.food;
    if (!hotel.isActive || !food.isActive)
      throw new NotFoundException('Combo services unavailable');

    const original = hotel.price + food.price;
    if (original <= 0) throw new NotFoundException('Invalid combo pricing');

    const qty = dto.quantity;
    const discountedTotal = Math.round(
      (original * qty * (100 - combo.discountPercent)) / 100,
    );
    const hotelShare = Math.round((hotel.price / original) * discountedTotal);
    const foodShare = discountedTotal - hotelShare;

    const { name: customerName, phone } = await this.resolveBookingContact(
      userId,
      dto,
    );
    const date = parseYmdToLocalDate(dto.date);
    const groupId = randomUUID();

    const [a, b] = await this.prisma.$transaction([
      this.prisma.booking.create({
        data: {
          userId,
          serviceId: hotel.id,
          comboId: combo.id,
          bookingGroupId: groupId,
          date,
          quantity: qty,
          totalPrice: hotelShare,
          customerName,
          customerPhone: phone,
          customerNote: dto.customerNote,
        },
        include: bookingInclude,
      }),
      this.prisma.booking.create({
        data: {
          userId,
          serviceId: food.id,
          comboId: combo.id,
          bookingGroupId: groupId,
          date,
          quantity: qty,
          totalPrice: foodShare,
          customerName,
          customerPhone: phone,
          customerNote: dto.customerNote,
        },
        include: bookingInclude,
      }),
    ]);

    return { bookingGroupId: groupId, bookings: [a, b] };
  }

  async findByUserId(userId: string, opts?: { status?: BookingStatus }) {
    const where: Prisma.BookingWhereInput = { userId };
    if (opts?.status) where.status = opts.status;
    return this.prisma.booking.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      include: bookingInclude,
    });
  }

  async listAdmin(query: ListBookingsQueryDto) {
    const where: Prisma.BookingWhereInput = {};
    if (query.status) where.status = query.status;
    if (query.serviceType) {
      where.service = { type: query.serviceType };
    }

    const skip = query.skip ?? 0;
    const take = query.take ?? 50;

    const [items, total] = await Promise.all([
      this.prisma.booking.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take,
        include: bookingInclude,
      }),
      this.prisma.booking.count({ where }),
    ]);

    return { items, total, skip, take };
  }

  async listMerchant(providerId: string, query: ListBookingsQueryDto) {
    const where: Prisma.BookingWhereInput = {
      service: {
        providerId,
        ...(query.serviceType ? { type: query.serviceType } : {}),
      },
    };
    if (query.status) where.status = query.status;

    const skip = query.skip ?? 0;
    const take = query.take ?? 50;

    const [items, total] = await Promise.all([
      this.prisma.booking.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take,
        include: bookingInclude,
      }),
      this.prisma.booking.count({ where }),
    ]);

    return { items, total, skip, take };
  }

  async updateStatusAdmin(id: string, status: BookingStatus) {
    const booking = await this.prisma.booking.findUnique({ where: { id } });
    if (!booking) throw new NotFoundException('Booking not found');

    return this.prisma.booking.update({
      where: { id },
      data: { status },
      include: bookingInclude,
    });
  }

  /** Khách hủy đơn của chính mình (PENDING / CONFIRMED). Nếu có bookingGroupId, hủy toàn bộ dòng cùng nhóm (combo / nhiều phòng). */
  async cancelForUser(userId: string, bookingId: string) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
    });
    if (!booking) throw new NotFoundException('Booking not found');
    if (booking.userId !== userId) {
      throw new ForbiddenException('Không thể hủy đơn của người khác.');
    }
    if (booking.status === BookingStatus.CANCELLED) {
      throw new BadRequestException('Đơn đã được hủy.');
    }
    if (
      booking.status !== BookingStatus.PENDING &&
      booking.status !== BookingStatus.CONFIRMED
    ) {
      throw new BadRequestException('Không thể hủy đơn ở trạng thái này.');
    }

    const groupId = booking.bookingGroupId;
    if (groupId) {
      const related = await this.prisma.booking.findMany({
        where: { bookingGroupId: groupId, userId },
      });
      const toCancel = related.filter(
        (b) =>
          b.status === BookingStatus.PENDING ||
          b.status === BookingStatus.CONFIRMED,
      );
      if (toCancel.length > 0) {
        await this.prisma.$transaction(
          toCancel.map((b) =>
            this.prisma.booking.update({
              where: { id: b.id },
              data: { status: BookingStatus.CANCELLED },
            }),
          ),
        );
      }
    } else {
      await this.prisma.booking.update({
        where: { id: bookingId },
        data: { status: BookingStatus.CANCELLED },
      });
    }

    const updated = await this.prisma.booking.findUnique({
      where: { id: bookingId },
      include: bookingInclude,
    });
    if (!updated) throw new NotFoundException('Booking not found');
    return updated;
  }

  async updateStatusMerchant(
    bookingId: string,
    providerId: string,
    dto: UpdateBookingStatusDto,
  ) {
    const {
      status,
      merchantCancelPreset: presetRaw,
      merchantCancelDetail: detailRaw,
    } = dto;
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
      include: { service: true },
    });
    if (!booking) throw new NotFoundException('Booking not found');
    if (booking.service.providerId !== providerId) {
      throw new ForbiddenException('Not your service');
    }

    if (booking.status === BookingStatus.CANCELLED) {
      throw new BadRequestException('Đơn đã hủy, không thể đổi trạng thái.');
    }

    if (status === BookingStatus.CANCELLED) {
      if (
        booking.status !== BookingStatus.PENDING &&
        booking.status !== BookingStatus.CONFIRMED
      ) {
        throw new BadRequestException('Không thể hủy đơn ở trạng thái này.');
      }
      const preset = (presetRaw ?? '').trim();
      if (!preset || !isMerchantCancelPreset(preset)) {
        throw new BadRequestException('Vui lòng chọn lý do hủy.');
      }
      const detail = (detailRaw ?? '').trim();
      if (preset === 'other') {
        if (detail.length < 3) {
          throw new BadRequestException(
            'Vui lòng ghi rõ lý do (tối thiểu 3 ký tự).',
          );
        }
      }
      const merchantCancelDetail = detail.length > 0 ? detail : null;

      return this.prisma.booking.update({
        where: { id: bookingId },
        data: {
          status: BookingStatus.CANCELLED,
          merchantCancelPreset: preset,
          merchantCancelDetail,
        },
        include: bookingInclude,
      });
    }

    if (status === BookingStatus.CONFIRMED) {
      if (booking.status === BookingStatus.CONFIRMED) {
        return this.prisma.booking.findUnique({
          where: { id: bookingId },
          include: bookingInclude,
        });
      }
      if (booking.status !== BookingStatus.PENDING) {
        throw new BadRequestException('Chỉ xác nhận được đơn đang chờ xử lý.');
      }
      return this.prisma.booking.update({
        where: { id: bookingId },
        data: { status: BookingStatus.CONFIRMED },
        include: bookingInclude,
      });
    }

    if (status === BookingStatus.PENDING) {
      throw new BadRequestException(
        'Không thể đặt lại đơn về trạng thái «Chờ xử lý».',
      );
    }

    throw new BadRequestException('Trạng thái không hợp lệ.');
  }

  async statsAdmin() {
    const [pending, confirmed, cancelled, total] = await Promise.all([
      this.prisma.booking.count({ where: { status: BookingStatus.PENDING } }),
      this.prisma.booking.count({ where: { status: BookingStatus.CONFIRMED } }),
      this.prisma.booking.count({ where: { status: BookingStatus.CANCELLED } }),
      this.prisma.booking.count(),
    ]);

    const serviceTypes: ServiceType[] = [
      'FOOD',
      'ACCOMMODATION',
      'VEHICLE',
      'TOUR',
    ];
    const byServiceType = await Promise.all(
      serviceTypes.map(async (type) => ({
        type,
        count: await this.prisma.booking.count({
          where: { service: { type } },
        }),
      })),
    );

    const byServiceTypeDetail = await Promise.all(
      serviceTypes.map(async (type) => {
        const base = { service: { type } } satisfies Prisma.BookingWhereInput;
        const [p, c, x] = await Promise.all([
          this.prisma.booking.count({
            where: { ...base, status: BookingStatus.PENDING },
          }),
          this.prisma.booking.count({
            where: { ...base, status: BookingStatus.CONFIRMED },
          }),
          this.prisma.booking.count({
            where: { ...base, status: BookingStatus.CANCELLED },
          }),
        ]);
        return {
          type,
          pending: p,
          confirmed: c,
          cancelled: x,
          total: p + c + x,
        };
      }),
    );

    return {
      total,
      byStatus: { pending, confirmed, cancelled },
      byServiceType,
      byServiceTypeDetail,
    };
  }

  async statsMerchant(providerId: string) {
    const base = { service: { providerId } } satisfies Prisma.BookingWhereInput;

    const [pending, confirmed, cancelled, total] = await Promise.all([
      this.prisma.booking.count({
        where: { ...base, status: BookingStatus.PENDING },
      }),
      this.prisma.booking.count({
        where: { ...base, status: BookingStatus.CONFIRMED },
      }),
      this.prisma.booking.count({
        where: { ...base, status: BookingStatus.CANCELLED },
      }),
      this.prisma.booking.count({ where: base }),
    ]);

    return { total, byStatus: { pending, confirmed, cancelled } };
  }
}
