import { RoomType } from '@prisma/client';
import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  Max,
  Min,
} from 'class-validator';

export class CreateRoomDto {
  @IsString()
  code!: string;

  @IsString()
  name!: string;

  @IsEnum(RoomType)
  roomType!: RoomType;

  @IsInt()
  @Min(1)
  @Max(20)
  maxGuests!: number;

  @IsOptional()
  @IsInt()
  floor?: number;

  @IsOptional()
  @IsInt()
  sortOrder?: number;

  /** Để trống = dùng giá cơ sở (Service.price). */
  @IsOptional()
  @IsInt()
  @Min(0)
  pricePerNight?: number;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(20)
  @IsString({ each: true })
  images?: string[];
}

export class UpdateRoomDto {
  @IsOptional()
  @IsString()
  code?: string;

  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsEnum(RoomType)
  roomType?: RoomType;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(20)
  maxGuests?: number;

  @IsOptional()
  @IsInt()
  floor?: number;

  @IsOptional()
  @IsInt()
  sortOrder?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  pricePerNight?: number;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(20)
  @IsString({ each: true })
  images?: string[];

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
