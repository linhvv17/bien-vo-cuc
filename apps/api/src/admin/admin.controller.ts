import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { Role } from '@prisma/client';

import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { CreateProviderUserDto } from '../auth/dto/create-provider-user.dto';
import { UpdateProviderAccountDto } from '../auth/dto/update-provider-account.dto';
import { CreateProviderDto } from './dto/create-provider.dto';
import { apiSuccess } from '../common/response/api-response';
import { AdminUsersService } from './admin-users.service';

@Controller('admin')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(Role.ADMIN)
export class AdminController {
  constructor(private readonly adminUsers: AdminUsersService) {}

  @Get('providers')
  async listProviders() {
    const data = await this.adminUsers.listProviders();
    return apiSuccess(data, 'OK');
  }

  @Post('providers')
  async createProvider(@Body() dto: CreateProviderDto) {
    const data = await this.adminUsers.createProvider(dto);
    return apiSuccess(data, 'OK');
  }

  @Get('provider-accounts')
  async listProviderAccounts() {
    const data = await this.adminUsers.listProviderAccounts();
    return apiSuccess(data, 'OK');
  }

  @Post('provider-accounts')
  async createProviderAccount(@Body() dto: CreateProviderUserDto) {
    const data = await this.adminUsers.createProviderAccount(dto);
    return apiSuccess(data, 'OK');
  }

  @Patch('provider-accounts/:id')
  async updateProviderAccount(
    @Param('id') id: string,
    @Body() dto: UpdateProviderAccountDto,
  ) {
    const data = await this.adminUsers.updateProviderAccount(id, dto);
    return apiSuccess(data, 'OK');
  }

  @Delete('provider-accounts/:id')
  async deleteProviderAccount(@Param('id') id: string) {
    const data = await this.adminUsers.deleteProviderAccount(id);
    return apiSuccess(data, 'OK');
  }
}
