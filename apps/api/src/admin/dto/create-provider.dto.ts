import { Transform } from 'class-transformer';
import { IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

/** Admin tạo bản ghi nhà cung cấp (NCC) — cần có trước khi tạo tài khoản đăng nhập NCC. */
export class CreateProviderDto {
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @MinLength(2)
  @MaxLength(120)
  name!: string;

  @IsOptional()
  @Transform(({ value }: { value: unknown }) => {
    if (value == null || value === '') return undefined;
    return typeof value === 'string' ? value.trim() : value;
  })
  @IsString()
  @MaxLength(32)
  phone?: string;

  @IsOptional()
  @Transform(({ value }: { value: unknown }) => {
    if (value == null || value === '') return undefined;
    return typeof value === 'string' ? value.trim() : value;
  })
  @IsString()
  @MaxLength(500)
  address?: string;
}
