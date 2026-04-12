import { IsIn, IsOptional, IsString, Matches } from 'class-validator';

const SERVICE_TYPES = ['VEHICLE', 'TOUR', 'ACCOMMODATION', 'FOOD'] as const;
export type ServiceTypeQuery = (typeof SERVICE_TYPES)[number];

export class GetServicesQueryDto {
  @IsOptional()
  @IsString()
  @IsIn(SERVICE_TYPES)
  type?: ServiceTypeQuery;

  @IsOptional()
  @Matches(/^\d+$/, { message: 'page must be a positive integer' })
  page?: string;

  @IsOptional()
  @Matches(/^\d+$/, { message: 'limit must be a positive integer' })
  limit?: string;
}
