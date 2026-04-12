import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Query,
  UseGuards,
} from '@nestjs/common';
import { Role } from '@prisma/client';

import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { apiSuccess } from '../common/response/api-response';
import { ListBookingsQueryDto } from './dto/list-bookings-query.dto';
import { UpdateBookingStatusDto } from './dto/update-booking-status.dto';
import { BookingsService } from './bookings.service';

@Controller('admin/bookings')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(Role.ADMIN)
export class AdminBookingsController {
  constructor(private readonly bookings: BookingsService) {}

  @Get('stats')
  async stats() {
    const data = await this.bookings.statsAdmin();
    return apiSuccess(data, 'OK');
  }

  @Get()
  async list(@Query() query: ListBookingsQueryDto) {
    const data = await this.bookings.listAdmin(query);
    return apiSuccess(data, 'OK');
  }

  @Patch(':id/status')
  async updateStatus(
    @Param('id') id: string,
    @Body() dto: UpdateBookingStatusDto,
  ) {
    const booking = await this.bookings.updateStatusAdmin(id, dto.status);
    return apiSuccess(booking, 'OK');
  }
}
