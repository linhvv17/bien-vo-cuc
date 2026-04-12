import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateComboDto, UpdateComboDto } from './dto/mutate-combo.dto';

@Injectable()
export class CombosService {
  constructor(private readonly prisma: PrismaService) {}

  async list() {
    return this.prisma.combo.findMany({
      where: { isActive: true },
      include: { hotel: true, food: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  async create(dto: CreateComboDto) {
    if (dto.hotelServiceId === dto.foodServiceId) {
      throw new BadRequestException(
        'hotelServiceId and foodServiceId must be different',
      );
    }

    const [hotel, food] = await Promise.all([
      this.prisma.service.findUnique({ where: { id: dto.hotelServiceId } }),
      this.prisma.service.findUnique({ where: { id: dto.foodServiceId } }),
    ]);
    if (!hotel || hotel.type !== 'ACCOMMODATION')
      throw new NotFoundException('Hotel service not found');
    if (!food || food.type !== 'FOOD')
      throw new NotFoundException('Food service not found');

    try {
      return await this.prisma.combo.create({
        data: {
          hotelServiceId: dto.hotelServiceId,
          foodServiceId: dto.foodServiceId,
          title: dto.title,
          discountPercent: dto.discountPercent ?? 10,
        },
        include: { hotel: true, food: true },
      });
    } catch (e: unknown) {
      if (
        e &&
        typeof e === 'object' &&
        'code' in e &&
        (e as { code: string }).code === 'P2002'
      ) {
        throw new BadRequestException(
          'Combo already exists for this hotel + food',
        );
      }
      throw e;
    }
  }

  async update(id: string, dto: UpdateComboDto) {
    return this.prisma.combo.update({
      where: { id },
      data: {
        ...(dto.title !== undefined ? { title: dto.title } : {}),
        ...(dto.discountPercent !== undefined
          ? { discountPercent: dto.discountPercent }
          : {}),
        ...(dto.isActive !== undefined ? { isActive: dto.isActive } : {}),
      },
      include: { hotel: true, food: true },
    });
  }

  async softDelete(id: string) {
    return this.prisma.combo.update({
      where: { id },
      data: { isActive: false },
    });
  }

  toDeal(combo: {
    id: string;
    title: string | null;
    discountPercent: number;
    hotel: { price: number };
    food: { price: number };
  }) {
    const originalTotal = combo.hotel.price + combo.food.price;
    const discountedTotal = Math.round(
      (originalTotal * (100 - combo.discountPercent)) / 100,
    );
    return {
      id: combo.id,
      title: combo.title,
      discountPercent: combo.discountPercent,
      originalTotal,
      discountedTotal,
      saved: originalTotal - discountedTotal,
      hotel: combo.hotel,
      food: combo.food,
    };
  }

  async deals(params?: { limit?: number }) {
    const limit =
      params?.limit && params.limit > 0 ? Math.min(params.limit, 50) : 12;
    const combos = await this.prisma.combo.findMany({
      where: { isActive: true },
      include: { hotel: true, food: true },
      orderBy: { createdAt: 'desc' },
      take: limit,
    });
    return combos.map((c) => this.toDeal(c));
  }
}
