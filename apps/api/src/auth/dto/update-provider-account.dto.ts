import { Transform } from 'class-transformer';
import {
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  MinLength,
} from 'class-validator';

/** Cập nhật tài khoản NCC — gửi ít nhất một trường. */
export class UpdateProviderAccountDto {
  @IsOptional()
  @Transform(({ value }: { value: unknown }) => {
    if (value == null || value === '') return undefined;
    return typeof value === 'string' ? value.trim().toLowerCase() : value;
  })
  @IsString()
  @Matches(/^[a-z0-9_]{3,32}$/, {
    message: 'Tên đăng nhập 3–32 ký tự (chữ không dấu, số, gạch dưới).',
  })
  username?: string;

  @IsOptional()
  @Transform(({ value }: { value: unknown }) => {
    if (value == null || value === '') return undefined;
    return typeof value === 'string' ? value.trim() : value;
  })
  @IsString()
  @MinLength(2)
  @MaxLength(80)
  name?: string;

  @IsOptional()
  @IsString()
  @MinLength(1)
  providerId?: string;

  @IsOptional()
  @Transform(({ value }: { value: unknown }) => {
    if (value == null || value === '') return undefined;
    return typeof value === 'string' ? value : undefined;
  })
  @IsString()
  @MinLength(8)
  @MaxLength(64)
  @Matches(/^(?=.*[A-Za-z])(?=.*\d).{8,64}$/, {
    message:
      'Mật khẩu 8–64 ký tự, gồm ít nhất một chữ cái (a-z, A-Z) và một chữ số.',
  })
  password?: string;
}
