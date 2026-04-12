import { createParamDecorator, ExecutionContext } from '@nestjs/common';

export type RequestUser = {
  userId: string;
  email: string;
  role: string;
  userKind: string;
  providerId: string | null;
};

export const CurrentUser = createParamDecorator(
  (_: unknown, ctx: ExecutionContext): RequestUser => {
    const req = ctx.switchToHttp().getRequest<{ user: RequestUser }>();
    return req.user;
  },
);
