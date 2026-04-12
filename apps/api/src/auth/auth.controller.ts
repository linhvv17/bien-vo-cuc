import { Body, Controller, Post } from '@nestjs/common';

import { apiSuccess } from '../common/response/api-response';
import { AuthService } from './auth.service';
import { LoginDto } from './dto/login.dto';
import { RefreshDto } from './dto/refresh.dto';
import { RegisterDto } from './dto/register.dto';

@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Post('login')
  async login(@Body() dto: LoginDto) {
    const data = await this.auth.login(dto);
    return apiSuccess(data, 'OK');
  }

  @Post('register')
  async register(@Body() dto: RegisterDto) {
    const data = await this.auth.register(dto);
    return apiSuccess(data, 'OK');
  }

  @Post('refresh')
  async refresh(@Body() dto: RefreshDto) {
    const data = await this.auth.refresh(dto.refreshToken);
    return apiSuccess(data, 'OK');
  }
}
