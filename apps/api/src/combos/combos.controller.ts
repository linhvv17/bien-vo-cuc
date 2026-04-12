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

import { apiSuccess } from '../common/response/api-response';
import { CombosService } from './combos.service';
import { CreateComboDto, UpdateComboDto } from './dto/mutate-combo.dto';

@Controller('combos')
export class CombosController {
  constructor(private readonly combos: CombosService) {}

  @Get()
  async list() {
    const data = await this.combos.list();
    return apiSuccess(data, 'OK', { count: data.length });
  }

  @Get('deals')
  async deals(@Query('limit') limit?: string) {
    const data = await this.combos.deals({
      limit: limit ? Number(limit) : undefined,
    });
    return apiSuccess(data, 'OK', { count: data.length });
  }

  @Post()
  async create(@Body() dto: CreateComboDto) {
    const data = await this.combos.create(dto);
    return apiSuccess(data, 'OK');
  }

  @Put(':id')
  async update(@Param('id') id: string, @Body() dto: UpdateComboDto) {
    const data = await this.combos.update(id, dto);
    return apiSuccess(data, 'OK');
  }

  @Delete(':id')
  async remove(@Param('id') id: string) {
    const data = await this.combos.softDelete(id);
    return apiSuccess(data, 'OK');
  }
}
