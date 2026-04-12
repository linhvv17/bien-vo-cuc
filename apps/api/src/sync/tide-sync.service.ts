import {
  BadRequestException,
  HttpException,
  HttpStatus,
  Injectable,
  Logger,
  OnModuleInit,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Cron } from '@nestjs/schedule';

import { PrismaService } from '../prisma/prisma.service';

type StormglassExtreme = {
  time: string; // ISO (UTC)
  type: 'high' | 'low';
  height: number;
};

// We treat "local day" as Asia/Ho_Chi_Minh (UTC+7) without DST.
const VN_UTC_OFFSET_HOURS = 7;

function pad2(n: number) {
  return String(n).padStart(2, '0');
}

function ymdFromUtcPlus7(dateUtc: Date): string {
  const d = new Date(dateUtc.getTime() + VN_UTC_OFFSET_HOURS * 3600_000);
  return `${d.getUTCFullYear()}-${pad2(d.getUTCMonth() + 1)}-${pad2(d.getUTCDate())}`;
}

function localDayStartUtcFromYmd(ymd: string): Date {
  const [y, m, d] = ymd.split('-').map(Number);
  // Local midnight (UTC+7) expressed as UTC is previous day 17:00Z.
  return new Date(Date.UTC(y, m - 1, d, -VN_UTC_OFFSET_HOURS, 0, 0, 0));
}

function toStormglassHourParam(dateUtc: Date): string {
  // Stormglass docs accept start/end in "YYYY-MM-DDTHH" (UTC).
  return `${dateUtc.getUTCFullYear()}-${pad2(dateUtc.getUTCMonth() + 1)}-${pad2(dateUtc.getUTCDate())}T${pad2(
    dateUtc.getUTCHours(),
  )}`;
}

@Injectable()
export class TideSyncService implements OnModuleInit {
  private readonly logger = new Logger(TideSyncService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
  ) {}

  onModuleInit(): void {
    const flag = this.config.get<string>('RUN_TIDE_SYNC_ON_START') ?? '';
    const enabled = ['1', 'true', 'yes', 'on'].includes(
      flag.trim().toLowerCase(),
    );
    if (!enabled) return;

    // Fire-and-forget so startup isn't blocked too long.
    setTimeout(() => {
      void this.syncNextDaysToDb(7)
        .then((r) => this.logger.log(`syncOnStart ok: ${JSON.stringify(r)}`))
        .catch((e: unknown) =>
          this.logger.error(
            `syncOnStart failed: ${String(e)}`,
            e instanceof Error ? e.stack : undefined,
          ),
        );
    }, 500);
  }

  /**
   * Daily sync at 00:10 Vietnam time.
   */
  @Cron('10 0 * * *', { timeZone: 'Asia/Ho_Chi_Minh' })
  async dailySync() {
    try {
      const result = await this.syncNextDaysToDb(7);
      this.logger.log(`dailySync ok: ${JSON.stringify(result)}`);
    } catch (e: unknown) {
      this.logger.error(
        `dailySync failed: ${String(e)}`,
        e instanceof Error ? e.stack : undefined,
      );
    }
  }

  async syncNextDaysToDb(days: number) {
    const apiKey = this.config.get<string>('STORMGLASS_API_KEY')?.trim();
    if (!apiKey) {
      throw new BadRequestException(
        'Chưa cấu hình STORMGLASS_API_KEY trong apps/api/.env (lấy key miễn phí tại https://stormglass.io). Sau đó khởi động lại API.',
      );
    }

    const lat = Number(this.config.get<string>('BEACH_LAT') ?? '20.5774021');
    const lng = Number(this.config.get<string>('BEACH_LNG') ?? '106.6192557');

    const nowUtc = new Date();
    const todayYmd = ymdFromUtcPlus7(nowUtc);
    const toYmd = ymdFromUtcPlus7(
      new Date(nowUtc.getTime() + (days - 1) * 86400_000),
    );

    const startUtc = localDayStartUtcFromYmd(todayYmd);
    const endUtc = new Date(
      localDayStartUtcFromYmd(toYmd).getTime() + 86400_000,
    ); // +1 day

    const url = new URL('https://api.stormglass.io/v2/tide/extremes/point');
    url.searchParams.set('lat', String(lat));
    url.searchParams.set('lng', String(lng));
    url.searchParams.set('start', toStormglassHourParam(startUtc));
    url.searchParams.set('end', toStormglassHourParam(endUtc));

    let res: Response;
    try {
      res = await fetch(url, {
        headers: {
          Authorization: apiKey,
        },
      });
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      throw new HttpException(
        `Không kết nối được Stormglass (${msg}). Kiểm tra mạng hoặc firewall.`,
        HttpStatus.BAD_GATEWAY,
      );
    }
    if (!res.ok) {
      const text = await res.text().catch(() => '');
      throw new HttpException(
        `Stormglass trả lỗi HTTP ${res.status}. Kiểm tra API key và quota. ${text.slice(0, 280)}`,
        HttpStatus.BAD_GATEWAY,
      );
    }

    let json: unknown;
    try {
      json = await res.json();
    } catch {
      throw new HttpException(
        'Stormglass trả dữ liệu không phải JSON.',
        HttpStatus.BAD_GATEWAY,
      );
    }
    const data = ((json as { data?: unknown })?.data ??
      []) as StormglassExtreme[];

    const lowsByDay = new Map<string, StormglassExtreme[]>();
    for (const item of data) {
      if (item.type !== 'low') continue;
      const t = new Date(item.time);
      const ymd = ymdFromUtcPlus7(t);
      const arr = lowsByDay.get(ymd) ?? [];
      arr.push(item);
      lowsByDay.set(ymd, arr);
    }

    let upserted = 0;
    let skipped = 0;

    const daysToProcess: string[] = [];
    for (let i = 0; i < days; i++) {
      const d = new Date(startUtc.getTime() + i * 86400_000);
      daysToProcess.push(ymdFromUtcPlus7(d));
    }

    for (const ymd of daysToProcess) {
      const lows = (lowsByDay.get(ymd) ?? [])
        .slice()
        .sort((a, b) => a.time.localeCompare(b.time));
      if (lows.length === 0) {
        skipped++;
        continue;
      }

      const low1 = lows[0];
      const low2 = lows[1];

      const date = localDayStartUtcFromYmd(ymd);

      await this.prisma.tideSchedule.upsert({
        where: { date },
        update: {
          lowTime1: new Date(low1.time),
          lowHeight1: low1.height,
          lowTime2: low2 ? new Date(low2.time) : null,
          lowHeight2: low2 ? low2.height : null,
          note: 'Synced from Stormglass',
        },
        create: {
          date,
          lowTime1: new Date(low1.time),
          lowHeight1: low1.height,
          lowTime2: low2 ? new Date(low2.time) : null,
          lowHeight2: low2 ? low2.height : null,
          note: 'Synced from Stormglass',
        },
      });

      upserted++;
    }

    return { from: todayYmd, to: toYmd, upserted, skipped };
  }
}
