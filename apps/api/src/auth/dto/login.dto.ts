import { IsString, MaxLength, MinLength } from 'class-validator';

/** Đăng nhập: `identifier` = email (admin / NCC) hoặc số điện thoại (app khách). */
export class LoginDto {
  @IsString()
  @MinLength(3)
  @MaxLength(120)
  identifier!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(128)
  password!: string;
}
