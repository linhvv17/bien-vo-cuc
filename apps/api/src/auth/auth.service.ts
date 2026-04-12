import {
  BadRequestException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcryptjs';
import { Role, User, UserKind } from '@prisma/client';

import { PrismaService } from '../prisma/prisma.service';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';
import {
  isValidNccUsernameSlug,
  nccEmailFromUsername,
  nccLocalPartFromUsername,
} from './ncc-username.util';
import {
  normalizeVietnameseMobilePhone,
  syntheticEmailFromPhone,
} from './phone-vn.util';

export type JwtPayload = {
  sub: string;
  email: string;
  role: Role;
  userKind: UserKind;
  providerId: string | null;
};

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
  ) {}

  private userToDto(user: User) {
    return {
      id: user.id,
      email: user.email,
      phone: user.phone,
      name: user.name,
      role: user.role,
      userKind: user.userKind,
      providerId: user.providerId,
    };
  }

  private issueSession(user: User) {
    const payload: JwtPayload = {
      sub: user.id,
      email: user.email,
      role: user.role,
      userKind: user.userKind,
      providerId: user.providerId,
    };
    const accessToken = this.jwt.sign(payload);
    const refreshSecret =
      this.config.get<string>('JWT_REFRESH_SECRET') ||
      this.config.get<string>('JWT_SECRET') ||
      'change-me';
    const refreshExpires =
      this.config.get<string>('JWT_REFRESH_EXPIRES_IN') ||
      this.config.get<string>('JWT_REFRESH_EXPIRES') ||
      '7d';
    const refreshToken = this.jwt.sign(
      { sub: user.id, typ: 'refresh' as const },
      {
        secret: refreshSecret,
        expiresIn: refreshExpires as `${number}d` | `${number}h` | `${number}m`,
      },
    );
    return {
      accessToken,
      refreshToken,
      user: this.userToDto(user),
    };
  }

  /** Làm mới access token bằng refresh token (rotation: mỗi lần cấp cặp token mới). */
  async refresh(refreshTokenRaw: string) {
    const refreshSecret =
      this.config.get<string>('JWT_REFRESH_SECRET') ||
      this.config.get<string>('JWT_SECRET') ||
      'change-me';
    let decoded: { sub?: string; typ?: string };
    try {
      decoded = this.jwt.verify(refreshTokenRaw.trim(), {
        secret: refreshSecret,
      });
    } catch {
      throw new UnauthorizedException(
        'Refresh token không hợp lệ hoặc đã hết hạn',
      );
    }
    if (decoded.typ !== 'refresh' || !decoded.sub) {
      throw new UnauthorizedException('Refresh token không hợp lệ');
    }
    const user = await this.prisma.user.findUnique({
      where: { id: decoded.sub },
    });
    if (!user) throw new UnauthorizedException('Tài khoản không còn tồn tại');
    return this.issueSession(user);
  }

  async login(dto: LoginDto) {
    const raw = dto.identifier.trim();
    if (!raw) {
      throw new BadRequestException(
        'Nhập email, số điện thoại hoặc tên đăng nhập NCC.',
      );
    }
    if (raw.includes('@')) {
      return this.loginWithEmail(raw, dto.password);
    }
    const phone = normalizeVietnameseMobilePhone(raw);
    if (phone) {
      return this.loginWithPhone(raw, dto.password);
    }
    return this.loginWithNccUsername(raw, dto.password);
  }

  private async loginWithEmail(emailRaw: string, password: string) {
    const email = emailRaw.trim().toLowerCase();
    const user = await this.prisma.user.findUnique({ where: { email } });
    if (!user) throw new UnauthorizedException('Sai email hoặc mật khẩu');
    const ok = await bcrypt.compare(password, user.passwordHash);
    if (!ok) throw new UnauthorizedException('Sai email hoặc mật khẩu');
    return this.issueSession(user);
  }

  /** Đăng nhập SĐT: chỉ tài khoản khách app (APP_CUSTOMER). */
  private async loginWithPhone(rawPhone: string, password: string) {
    const phone = normalizeVietnameseMobilePhone(rawPhone);
    if (!phone) {
      throw new BadRequestException(
        'Số điện thoại không hợp lệ (di động Việt Nam).',
      );
    }
    const synthetic = syntheticEmailFromPhone(phone);
    const user = await this.prisma.user.findFirst({
      where: {
        OR: [{ phone }, { email: synthetic }],
      },
    });
    if (!user)
      throw new UnauthorizedException('Sai số điện thoại hoặc mật khẩu');
    if (user.userKind !== UserKind.APP_CUSTOMER) {
      throw new UnauthorizedException(
        'Tài khoản nhà cung cấp vui lòng đăng nhập bằng email hoặc tên đăng nhập NCC.',
      );
    }
    const ok = await bcrypt.compare(password, user.passwordHash);
    if (!ok) throw new UnauthorizedException('Sai số điện thoại hoặc mật khẩu');
    return this.issueSession(user);
  }

  /** Đăng nhập tài khoản NCC bằng username (không có @). */
  private async loginWithNccUsername(identifierRaw: string, password: string) {
    const slug = nccLocalPartFromUsername(identifierRaw);
    if (!isValidNccUsernameSlug(slug)) {
      throw new BadRequestException(
        'Nhập số điện thoại hợp lệ, email, hoặc tên đăng nhập NCC (3–32 ký tự: chữ, số, gạch dưới).',
      );
    }
    const email = nccEmailFromUsername(identifierRaw);
    const user = await this.prisma.user.findUnique({ where: { email } });
    if (!user)
      throw new UnauthorizedException('Sai tên đăng nhập hoặc mật khẩu');
    if (
      user.userKind !== UserKind.PROVIDER_ACCOUNT ||
      user.role !== Role.MERCHANT
    ) {
      throw new UnauthorizedException('Sai tên đăng nhập hoặc mật khẩu');
    }
    const ok = await bcrypt.compare(password, user.passwordHash);
    if (!ok) throw new UnauthorizedException('Sai tên đăng nhập hoặc mật khẩu');
    return this.issueSession(user);
  }

  /** Đăng ký công khai — chỉ tạo khách hàng app. */
  async register(dto: RegisterDto) {
    const phone = normalizeVietnameseMobilePhone(dto.phone);
    if (!phone) {
      throw new BadRequestException(
        'Số điện thoại không hợp lệ (di động Việt Nam).',
      );
    }

    const existsPhone = await this.prisma.user.findUnique({ where: { phone } });
    if (existsPhone)
      throw new BadRequestException('Số điện thoại đã được đăng ký');

    const email = syntheticEmailFromPhone(phone);
    const existsEmail = await this.prisma.user.findUnique({ where: { email } });
    if (existsEmail)
      throw new BadRequestException('Không thể tạo tài khoản với số này');

    const passwordHash = await bcrypt.hash(dto.password, 10);
    const user = await this.prisma.user.create({
      data: {
        email,
        phone,
        name: dto.name.trim(),
        passwordHash,
        role: Role.USER,
        userKind: UserKind.APP_CUSTOMER,
      },
    });

    return this.issueSession(user);
  }
}
