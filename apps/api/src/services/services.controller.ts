import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Put,
  Query,
} from '@nestjs/common';
import { ServiceType } from '@prisma/client';

import { apiSuccess } from '../common/response/api-response';
import { GetServicesQueryDto } from './dto/get-services.dto';
import { CreateRoomDto, UpdateRoomDto } from './dto/mutate-room.dto';
import { CreateServiceDto, UpdateServiceDto } from './dto/mutate-service.dto';
import { ServicesService } from './services.service';

@Controller('services')
export class ServicesController {
  constructor(private readonly services: ServicesService) {}

  @Get()
  async list(@Query() query: GetServicesQueryDto) {
    const page = query.page ? Number(query.page) : undefined;
    const limit = query.limit ? Number(query.limit) : undefined;
    const type = query.type as ServiceType | undefined;

    const result = await this.services.list({ type, page, limit });
    return apiSuccess(result.items, 'OK', {
      total: result.total,
      page: result.page,
      limit: result.limit,
    });
  }

  @Get('combo')
  async combo() {
    const data = await this.services.combo();
    return apiSuccess(data, 'OK');
  }

  @Get('combos')
  async combos(@Query('limit') limit?: string) {
    const data = await this.services.combos({
      limit: limit ? Number(limit) : undefined,
    });
    return apiSuccess(data, 'OK', { count: data.length });
  }

  @Get(':id/rooms')
  async listRooms(@Param('id') id: string) {
    const data = await this.services.listRoomsForService(id);
    return apiSuccess(data, 'OK');
  }

  @Post(':id/rooms')
  async createRoom(@Param('id') id: string, @Body() dto: CreateRoomDto) {
    const created = await this.services.createRoom(id, dto);
    return apiSuccess(created, 'OK');
  }

  @Put(':serviceId/rooms/:roomId')
  async updateRoom(
    @Param('serviceId') serviceId: string,
    @Param('roomId') roomId: string,
    @Body() dto: UpdateRoomDto,
  ) {
    const updated = await this.services.updateRoom(serviceId, roomId, dto);
    return apiSuccess(updated, 'OK');
  }

  @Delete(':serviceId/rooms/:roomId')
  async deleteRoom(
    @Param('serviceId') serviceId: string,
    @Param('roomId') roomId: string,
  ) {
    const deleted = await this.services.softDeleteRoom(serviceId, roomId);
    return apiSuccess(deleted, 'OK');
  }

  @Get(':id/accommodation-detail')
  async accommodationDetail(
    @Param('id') id: string,
    @Query('date') date?: string,
  ) {
    const ymd =
      date && /^\d{4}-\d{2}-\d{2}$/.test(date)
        ? date
        : new Date(
            new Date().getFullYear(),
            new Date().getMonth(),
            new Date().getDate() + 1,
          )
            .toISOString()
            .slice(0, 10);
    const data = await this.services.getAccommodationDetail(id, ymd);
    return apiSuccess(data, 'OK');
  }

  @Post()
  async create(@Body() dto: CreateServiceDto) {
    const created = await this.services.create(dto);
    return apiSuccess(created, 'OK');
  }

  @Put(':id')
  async update(@Param('id') id: string, @Body() dto: UpdateServiceDto) {
    const updated = await this.services.update(id, dto);
    return apiSuccess(updated, 'OK');
  }

  @Delete(':id')
  async remove(@Param('id') id: string) {
    const deleted = await this.services.softDelete(id);
    return apiSuccess(deleted, 'OK');
  }
}
