import { Injectable } from '@nestjs/common';

import { PrismaService } from '../prisma/prisma.service';
import { addDaysLocal, parseYmdToLocalDate } from './dto/get-tides.dto';

@Injectable()
export class TidesService {
  constructor(private readonly prisma: PrismaService) {}

  async getByDate(dateYmd: string) {
    const start = parseYmdToLocalDate(dateYmd);
    const end = addDaysLocal(start, 1);

    return this.prisma.tideSchedule.findFirst({
      where: {
        date: {
          gte: start,
          lt: end,
        },
      },
    });
  }

  async getGoldenHours(fromYmd: string, toYmd: string) {
    const start = parseYmdToLocalDate(fromYmd);
    const end = addDaysLocal(parseYmdToLocalDate(toYmd), 1);

    return this.prisma.tideSchedule.findMany({
      where: {
        isGolden: true,
        date: {
          gte: start,
          lt: end,
        },
      },
      orderBy: { date: 'asc' },
    });
  }

  async getRange(fromYmd: string, toYmd: string) {
    const start = parseYmdToLocalDate(fromYmd);
    const end = addDaysLocal(parseYmdToLocalDate(toYmd), 1);

    return this.prisma.tideSchedule.findMany({
      where: {
        date: {
          gte: start,
          lt: end,
        },
      },
      orderBy: { date: 'asc' },
    });
  }
}
