import { IsString, MinLength } from 'class-validator';

export class RefreshDto {
  @IsString()
  @MinLength(10, { message: 'refreshToken không hợp lệ' })
  refreshToken!: string;
}
