import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpStatus,
} from '@nestjs/common';
import { PrismaClientKnownRequestError } from '@prisma/client/runtime/client';
import type { Request, Response } from 'express';

import { apiError } from '../response/api-response';

function prismaClientMessage(exception: PrismaClientKnownRequestError): string {
  switch (exception.code) {
    case 'P2011':
      return 'Lưu đơn thất bại: ràng buộc NOT NULL trên database (thường là userId cho đặt khách). Trong apps/api chạy: npm run prisma:deploy rồi khởi động lại API.';
    case 'P2002':
      return 'Dữ liệu trùng với bản ghi đã tồn tại.';
    case 'P2003':
      return 'Tham chiếu không hợp lệ (foreign key).';
    case 'P2025':
      return 'Không tìm thấy bản ghi liên quan.';
    default:
      return exception.message;
  }
}

@Catch(PrismaClientKnownRequestError)
export class PrismaClientExceptionFilter implements ExceptionFilter {
  catch(exception: PrismaClientKnownRequestError, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const res = ctx.getResponse<Response>();
    const req = ctx.getRequest<Request>();
    const message = prismaClientMessage(exception);

    res.status(HttpStatus.BAD_REQUEST).json(
      apiError(message, {
        path: req.url,
        statusCode: HttpStatus.BAD_REQUEST,
        prismaCode: exception.code,
      }),
    );
  }
}
