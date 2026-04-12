import { IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

export class CreateComboDto {
  @IsString()
  hotelServiceId!: string;

  @IsString()
  foodServiceId!: string;

  @IsOptional()
  @IsString()
  title?: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(100)
  discountPercent?: number; // default 10
}

export class UpdateComboDto {
  @IsOptional()
  @IsString()
  title?: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(100)
  discountPercent?: number;

  @IsOptional()
  isActive?: boolean;
}
