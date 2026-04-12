import { Controller, Get, Query } from '@nestjs/common';

import { apiSuccess } from '../common/response/api-response';
import {
  GetGoldenHoursQueryDto,
  GetTidesQueryDto,
  GetTidesRangeQueryDto,
} from './dto/get-tides.dto';
import { TidesService } from './tides.service';

@Controller('tides')
export class TidesController {
  constructor(private readonly tidesService: TidesService) {}

  @Get()
  async getTides(@Query() query: GetTidesQueryDto) {
    const schedule = await this.tidesService.getByDate(query.date);
    return apiSuccess(schedule, 'OK');
  }

  @Get('golden-hours')
  async getGoldenHours(@Query() query: GetGoldenHoursQueryDto) {
    const items = await this.tidesService.getGoldenHours(query.from, query.to);
    return apiSuccess(items, 'OK', { count: items.length });
  }

  @Get('range')
  async getRange(@Query() query: GetTidesRangeQueryDto) {
    const items = await this.tidesService.getRange(query.from, query.to);
    return apiSuccess(items, 'OK', { count: items.length });
  }
}
