import { Module } from '@nestjs/common';

import { AdminBookingsController } from './admin-bookings.controller';
import { BookingsController } from './bookings.controller';
import { BookingsService } from './bookings.service';
import { MerchantBookingsController } from './merchant-bookings.controller';

@Module({
  controllers: [
    BookingsController,
    AdminBookingsController,
    MerchantBookingsController,
  ],
  providers: [BookingsService],
})
export class BookingsModule {}
