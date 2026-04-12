import { Module } from '@nestjs/common';
import { ScheduleModule } from '@nestjs/schedule';

import { SyncController } from './sync.controller';
import { TideSyncService } from './tide-sync.service';

@Module({
  imports: [ScheduleModule.forRoot()],
  controllers: [SyncController],
  providers: [TideSyncService],
})
export class SyncModule {}
