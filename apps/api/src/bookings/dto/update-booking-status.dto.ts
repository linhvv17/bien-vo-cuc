import { BookingStatus } from '@prisma/client';
import { IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';

export class UpdateBookingStatusDto {
  @IsEnum(BookingStatus)
  status!: BookingStatus;

  /** Khi NCC hủy đơn — mã preset (bắt buộc qua validate service). Admin có thể bỏ qua. */
  @IsOptional()
  @IsString()
  @MaxLength(32)
  merchantCancelPreset?: string;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  merchantCancelDetail?: string;
}
