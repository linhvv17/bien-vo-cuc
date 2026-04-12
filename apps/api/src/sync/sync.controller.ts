import { Controller, Post } from '@nestjs/common';

import { apiSuccess } from '../common/response/api-response';
import { TideSyncService } from './tide-sync.service';

@Controller('sync')
export class SyncController {
  constructor(private readonly tideSync: TideSyncService) {}

  @Post('tides')
  async syncTidesNow() {
    const result = await this.tideSync.syncNextDaysToDb(7);
    return apiSuccess(result, 'OK');
  }
}
