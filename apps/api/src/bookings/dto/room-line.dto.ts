import { RoomType } from '@prisma/client';
import { IsEnum, IsInt, Max, Min } from 'class-validator';

/** Một dòng đặt: bao nhiêu phòng cùng loại (đơn / đôi / gia đình …). */
export class RoomLineDto {
  @IsEnum(RoomType)
  roomType!: RoomType;

  @IsInt()
  @Min(1)
  @Max(20)
  quantity!: number;
}
