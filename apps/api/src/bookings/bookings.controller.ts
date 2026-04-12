import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';

import { CurrentUser, type RequestUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { apiSuccess } from '../common/response/api-response';
import { CreatePublicBookingDto } from './dto/create-public-booking.dto';
import { CreatePublicComboBookingDto } from './dto/create-public-combo-booking.dto';
import { MineBookingsQueryDto } from './dto/mine-bookings-query.dto';
import { BookingsService } from './bookings.service';

@Controller('bookings')
export class BookingsController {
  constructor(private readonly bookings: BookingsService) {}

  @Post('public')
  @UseGuards(JwtAuthGuard)
  async createPublic(
    @CurrentUser() user: RequestUser,
    @Body() dto: CreatePublicBookingDto,
  ) {
    const booking = await this.bookings.createForUser(user.userId, dto);
    return apiSuccess(booking, 'OK');
  }

  @Post('public/combo')
  @UseGuards(JwtAuthGuard)
  async createPublicCombo(
    @CurrentUser() user: RequestUser,
    @Body() dto: CreatePublicComboBookingDto,
  ) {
    const result = await this.bookings.createComboForUser(user.userId, dto);
    return apiSuccess(result, 'OK');
  }

  /** Đặt chỗ không cần tài khoản (web khách): chỉ dựa họ tên + SĐT trên form. */
  @Post('guest')
  async createGuest(@Body() dto: CreatePublicBookingDto) {
    const booking = await this.bookings.createForUser(null, dto);
    return apiSuccess(booking, 'OK');
  }

  @Post('guest/combo')
  async createGuestCombo(@Body() dto: CreatePublicComboBookingDto) {
    const result = await this.bookings.createComboForUser(null, dto);
    return apiSuccess(result, 'OK');
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  async mine(
    @CurrentUser() user: RequestUser,
    @Query() query: MineBookingsQueryDto,
  ) {
    const items = await this.bookings.findByUserId(user.userId, query);
    return apiSuccess(items, 'OK');
  }

  @Patch('me/:id/cancel')
  @UseGuards(JwtAuthGuard)
  async cancelMine(@CurrentUser() user: RequestUser, @Param('id') id: string) {
    const booking = await this.bookings.cancelForUser(user.userId, id);
    return apiSuccess(booking, 'OK');
  }
}
