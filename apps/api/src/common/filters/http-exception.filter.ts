import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
} from '@nestjs/common';
import type { Request, Response } from 'express';

import { apiError } from '../response/api-response';

@Catch(HttpException)
export class HttpExceptionFilter implements ExceptionFilter {
  catch(exception: HttpException, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const res = ctx.getResponse<Response>();
    const req = ctx.getRequest<Request>();

    const status = exception.getStatus();
    const responseBody = exception.getResponse();

    const raw =
      typeof responseBody === 'string'
        ? responseBody
        : ((responseBody as Record<string, unknown>)?.message ??
          exception.message ??
          'Request failed');

    const messageText = (() => {
      if (Array.isArray(raw)) return raw.map(String).join(', ');
      if (raw != null && typeof raw === 'object') return JSON.stringify(raw);
      if (typeof raw === 'string') return raw;
      if (
        typeof raw === 'number' ||
        typeof raw === 'boolean' ||
        typeof raw === 'bigint'
      )
        return String(raw);
      if (raw == null) return '';
      return JSON.stringify(raw);
    })();

    const meta = {
      path: req.url,
      statusCode: status,
    };

    res.status(status).json(apiError(messageText, meta));
  }
}
