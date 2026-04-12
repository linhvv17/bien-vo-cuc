import {
  Body,
  Controller,
  ForbiddenException,
  Get,
  Param,
  Patch,
  Query,
  UseGuards,
} from '@nestjs/common';
import { Role } from '@prisma/client';

import { CurrentUser, type RequestUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { apiSuccess } from '../common/response/api-response';
import { ListBookingsQueryDto } from './dto/list-bookings-query.dto';
import { UpdateBookingStatusDto } from './dto/update-booking-status.dto';
import { BookingsService } from './bookings.service';

@Controller('merchant/bookings')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(Role.MERCHANT)
export class MerchantBookingsController {
  constructor(private readonly bookings: BookingsService) {}

  @Get('stats')
  async stats(@CurrentUser() user: RequestUser) {
    const providerId = user.providerId;
    if (!providerId) throw new ForbiddenException('Merchant has no provider');
    const data = await this.bookings.statsMerchant(providerId);
    return apiSuccess(data, 'OK');
  }

  @Get()
  async list(
    @CurrentUser() user: RequestUser,
    @Query() query: ListBookingsQueryDto,
  ) {
    const providerId = user.providerId;
    if (!providerId) throw new ForbiddenException('Merchant has no provider');
    const data = await this.bookings.listMerchant(providerId, query);
    return apiSuccess(data, 'OK');
  }

  @Patch(':id/status')
  async updateStatus(
    @CurrentUser() user: RequestUser,
    @Param('id') id: string,
    @Body() dto: UpdateBookingStatusDto,
  ) {
    const providerId = user.providerId;
    if (!providerId) throw new ForbiddenException('Merchant has no provider');
    const booking = await this.bookings.updateStatusMerchant(
      id,
      providerId,
      dto,
    );
    return apiSuccess(booking, 'OK');
  }
}
