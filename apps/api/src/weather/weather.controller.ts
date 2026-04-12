import { Controller, Get, Query } from '@nestjs/common';

import { apiSuccess } from '../common/response/api-response';
import { WeatherService } from './weather.service';

@Controller('weather')
export class WeatherController {
  constructor(private readonly weatherService: WeatherService) {}

  /**
   * Dự báo 7 ngày — nguồn Open-Meteo (server proxy, không cần API key).
   * Web end-user & app mobile dùng chung: `GET /weather/forecast` (tuỳ chọn `?lat=&lon=`, mặc định BEACH_LAT/LNG).
   */
  @Get('forecast')
  async forecast(@Query('lat') lat?: string, @Query('lon') lon?: string) {
    const data = await this.weatherService.getForecast7Days({
      lat: lat ? Number(lat) : undefined,
      lon: lon ? Number(lon) : undefined,
    });
    return apiSuccess(data, 'OK', { days: data.length });
  }
}
