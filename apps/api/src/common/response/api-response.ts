export type ApiResponse<T> = {
  success: boolean;
  data: T;
  message: string;
  meta?: Record<string, unknown>;
};

export function apiSuccess<T>(
  data: T,
  message = 'OK',
  meta?: Record<string, unknown>,
): ApiResponse<T> {
  return { success: true, data, message, meta };
}

export function apiError(
  message = 'Error',
  meta?: Record<string, unknown>,
): ApiResponse<null> {
  return { success: false, data: null, message, meta };
}
