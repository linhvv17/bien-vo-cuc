import { Module } from '@nestjs/common';

import { TidesController } from './tides.controller';
import { TidesService } from './tides.service';

@Module({
  controllers: [TidesController],
  providers: [TidesService],
})
export class TidesModule {}
