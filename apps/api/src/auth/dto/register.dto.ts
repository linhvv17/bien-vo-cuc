import { IsString, Matches, MaxLength, MinLength } from 'class-validator';

export class RegisterDto {
  @IsString()
  @MinLength(8)
  @MaxLength(20)
  phone!: string;

  @IsString()
  @MinLength(2)
  @MaxLength(80)
  name!: string;

  @IsString()
  @MinLength(8)
  @MaxLength(64)
  @Matches(/^(?=.*[A-Za-z])(?=.*\d).{8,64}$/, {
    message:
      'Mật khẩu 8–64 ký tự, gồm ít nhất một chữ cái (a-z, A-Z) và một chữ số.',
  })
  password!: string;
}
