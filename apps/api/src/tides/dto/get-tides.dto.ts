import { IsString, Matches } from 'class-validator';

export class GetTidesQueryDto {
  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: 'date must be in format YYYY-MM-DD',
  })
  date!: string;
}

export class GetGoldenHoursQueryDto {
  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: 'from must be in format YYYY-MM-DD',
  })
  from!: string;

  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: 'to must be in format YYYY-MM-DD',
  })
  to!: string;
}

export class GetTidesRangeQueryDto {
  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: 'from must be in format YYYY-MM-DD',
  })
  from!: string;

  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: 'to must be in format YYYY-MM-DD',
  })
  to!: string;
}

// Helper for mapping Y-M-D to Date (local time) deterministically.
export function parseYmdToLocalDate(ymd: string): Date {
  const [y, m, d] = ymd.split('-').map((v) => Number(v));
  return new Date(y, m - 1, d, 0, 0, 0, 0);
}

export function addDaysLocal(date: Date, days: number): Date {
  const next = new Date(date);
  next.setDate(next.getDate() + days);
  return next;
}
