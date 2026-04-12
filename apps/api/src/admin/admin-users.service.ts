import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { Role, UserKind } from '@prisma/client';

import {
  displayLoginFromStoredEmail,
  isNccSyntheticEmail,
  isValidNccUsernameSlug,
  nccEmailFromUsername,
  nccLocalPartFromUsername,
} from '../auth/ncc-username.util';
import { CreateProviderUserDto } from '../auth/dto/create-provider-user.dto';
import { UpdateProviderAccountDto } from '../auth/dto/update-provider-account.dto';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class AdminUsersService {
  constructor(private readonly prisma: PrismaService) {}

  listProviders() {
    return this.prisma.provider.findMany({
      orderBy: { name: 'asc' },
      select: { id: true, name: true, phone: true },
    });
  }

  listProviderAccounts() {
    return this.prisma.user
      .findMany({
        where: { userKind: UserKind.PROVIDER_ACCOUNT },
        include: { provider: { select: { id: true, name: true } } },
        orderBy: { createdAt: 'desc' },
      })
      .then((rows) =>
        rows.map((u) => ({
          id: u.id,
          username: displayLoginFromStoredEmail(u.email),
          email: u.email,
          name: u.name,
          providerId: u.providerId,
          providerName: u.provider?.name ?? null,
          createdAt: u.createdAt.toISOString(),
        })),
      );
  }

  async createProviderAccount(dto: CreateProviderUserDto) {
    const provider = await this.prisma.provider.findUnique({
      where: { id: dto.providerId },
    });
    if (!provider) throw new NotFoundException('Không tìm thấy nhà cung cấp');

    const slug = nccLocalPartFromUsername(dto.username);
    if (!isValidNccUsernameSlug(slug)) {
      throw new BadRequestException(
        'Tên đăng nhập 3–32 ký tự (chữ không dấu, số, gạch dưới).',
      );
    }
    const email = nccEmailFromUsername(dto.username);
    const exists = await this.prisma.user.findUnique({ where: { email } });
    if (exists) throw new BadRequestException('Tên đăng nhập đã được sử dụng');

    const displayName = dto.name?.trim() || slug;
    const passwordHash = await bcrypt.hash(dto.password, 10);
    const user = await this.prisma.user.create({
      data: {
        email,
        name: displayName,
        passwordHash,
        role: Role.MERCHANT,
        userKind: UserKind.PROVIDER_ACCOUNT,
        providerId: dto.providerId,
      },
    });

    return {
      id: user.id,
      username: displayLoginFromStoredEmail(user.email),
      email: user.email,
      name: user.name,
      role: user.role,
      userKind: user.userKind,
      providerId: user.providerId,
    };
  }

  async updateProviderAccount(id: string, dto: UpdateProviderAccountDto) {
    const user = await this.prisma.user.findUnique({ where: { id } });
    if (!user || user.userKind !== UserKind.PROVIDER_ACCOUNT) {
      throw new NotFoundException('Không tìm thấy tài khoản NCC');
    }

    const hasPatch =
      dto.username !== undefined ||
      dto.name !== undefined ||
      dto.providerId !== undefined ||
      dto.password !== undefined;
    if (!hasPatch) {
      throw new BadRequestException('Gửi ít nhất một trường cần cập nhật.');
    }

    if (dto.providerId !== undefined) {
      const provider = await this.prisma.provider.findUnique({
        where: { id: dto.providerId },
      });
      if (!provider) throw new NotFoundException('Không tìm thấy nhà cung cấp');
    }

    const data: {
      email?: string;
      name?: string;
      providerId?: string;
      passwordHash?: string;
    } = {};

    if (dto.username !== undefined) {
      if (!isNccSyntheticEmail(user.email)) {
        throw new BadRequestException(
          'Tài khoản đăng nhập bằng email không đổi được tên đăng nhập kiểu NCC tại đây.',
        );
      }
      const slug = nccLocalPartFromUsername(dto.username);
      if (!isValidNccUsernameSlug(slug)) {
        throw new BadRequestException(
          'Tên đăng nhập 3–32 ký tự (chữ không dấu, số, gạch dưới).',
        );
      }
      const nextEmail = nccEmailFromUsername(dto.username);
      if (nextEmail !== user.email) {
        const taken = await this.prisma.user.findFirst({
          where: { email: nextEmail, NOT: { id: user.id } },
        });
        if (taken)
          throw new BadRequestException('Tên đăng nhập đã được sử dụng');
        data.email = nextEmail;
      }
    }

    if (dto.name !== undefined) {
      data.name = dto.name;
    }

    if (dto.providerId !== undefined) {
      data.providerId = dto.providerId;
    }

    if (dto.password !== undefined) {
      data.passwordHash = await bcrypt.hash(dto.password, 10);
    }

    if (Object.keys(data).length === 0) {
      throw new BadRequestException('Không có thay đổi để cập nhật.');
    }

    const updated = await this.prisma.user.update({
      where: { id },
      data,
    });

    return {
      id: updated.id,
      username: displayLoginFromStoredEmail(updated.email),
      email: updated.email,
      name: updated.name,
      role: updated.role,
      userKind: updated.userKind,
      providerId: updated.providerId,
    };
  }

  async deleteProviderAccount(id: string) {
    const user = await this.prisma.user.findUnique({ where: { id } });
    if (!user || user.userKind !== UserKind.PROVIDER_ACCOUNT) {
      throw new NotFoundException('Không tìm thấy tài khoản NCC');
    }

    const [bookings, photos] = await Promise.all([
      this.prisma.booking.count({ where: { userId: id } }),
      this.prisma.photo.count({ where: { userId: id } }),
    ]);
    if (bookings > 0 || photos > 0) {
      throw new BadRequestException(
        'Không xóa được: tài khoản còn liên kết đặt chỗ hoặc ảnh. Hãy xử lý dữ liệu liên quan trước.',
      );
    }

    await this.prisma.user.delete({ where: { id } });
    return { id };
  }
}
