import { Type } from 'class-transformer';
import {
  IsArray,
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  Matches,
  Max,
  Min,
  ValidateIf,
  ValidateNested,
} from 'class-validator';

import { RoomLineDto } from './room-line.dto';

export class CreatePublicBookingDto {
  @IsString()
  serviceId!: string;

  // YYYY-MM-DD
  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: 'date must be in format YYYY-MM-DD',
  })
  date!: string;

  /** Khi không gửi [roomLines], bắt buộc (1 đơn vị dịch vụ / 1 phòng cũ). */
  @ValidateIf((o: CreatePublicBookingDto) => !o.roomLines?.length)
  @IsInt()
  @Min(1)
  @Max(99)
  quantity?: number;

  /** Đặt nhiều phòng theo loại (đoàn). Khi có, [quantity] được bỏ qua (server cộng từ các dòng). */
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => RoomLineDto)
  roomLines?: RoomLineDto[];

  @IsString()
  customerName!: string;

  @IsString()
  customerPhone!: string;

  @IsOptional()
  @IsString()
  customerNote?: string;

  /** ACCOMMODATION: chọn phòng cụ thể (kèm roomAssignment=SPECIFIC). */
  @IsOptional()
  @IsString()
  roomId?: string;

  /** SPECIFIC | RANDOM — mặc định RANDOM khi có danh sách phòng. */
  @IsOptional()
  @IsString()
  @IsIn(['SPECIFIC', 'RANDOM'])
  roomAssignment?: 'SPECIFIC' | 'RANDOM';

  /** Các key tiêu chí (vd: quiet, high_floor). */
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  guestPreferences?: string[];
}
