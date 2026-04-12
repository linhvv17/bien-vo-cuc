import { Transform } from 'class-transformer';
import {
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  MinLength,
} from 'class-validator';

/** Admin tạo tài khoản đăng nhập cho nhà cung cấp (không qua đăng ký công khai). */
export class CreateProviderUserDto {
  /** Tên đăng nhập web NCC (lưu nội bộ dạng `{username}@ncc.local`). */
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim().toLowerCase() : value,
  )
  @IsString()
  @Matches(/^[a-z0-9_]{3,32}$/, {
    message: 'Tên đăng nhập 3–32 ký tự (chữ không dấu, số, gạch dưới).',
  })
  username!: string;

  @IsOptional()
  @Transform(({ value }: { value: unknown }) => {
    if (value == null || value === '') return undefined;
    return typeof value === 'string' ? value.trim() : value;
  })
  @IsString()
  @MinLength(2)
  @MaxLength(80)
  name?: string;

  @IsString()
  @MinLength(8)
  @MaxLength(64)
  @Matches(/^(?=.*[A-Za-z])(?=.*\d).{8,64}$/, {
    message:
      'Mật khẩu 8–64 ký tự, gồm ít nhất một chữ cái (a-z, A-Z) và một chữ số.',
  })
  password!: string;

  @IsString()
  @MinLength(1)
  providerId!: string;
}
