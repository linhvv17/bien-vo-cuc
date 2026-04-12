import axios, { type AxiosError, type AxiosResponse } from "axios";
import { getApiBaseUrl } from "./api-config";
import { loadSession } from "./auth-storage";

function unwrapEnvelope<T>(response: AxiosResponse) {
  const body = response.data as { success?: boolean; data?: T; message?: string };
  if (body && typeof body === "object" && body.success === true) {
    return { ...response, data: body.data as T };
  }
  throw new Error((body as { message?: string })?.message || "Request failed");
}

function errorToMessage(error: AxiosError<{ message?: string }>) {
  const msg = error.response?.data?.message || error.message || "Có lỗi xảy ra";
  return new Error(msg);
}

const apiClient = axios.create({
  baseURL: getApiBaseUrl(),
  timeout: 15000,
  headers: { "Content-Type": "application/json", Accept: "application/json" },
});

apiClient.interceptors.request.use((config) => {
  const s = loadSession();
  if (s?.accessToken) {
    config.headers.Authorization = `Bearer ${s.accessToken}`;
  }
  return config;
});

apiClient.interceptors.response.use(unwrapEnvelope, (error: AxiosError<{ message?: string }>) => {
  throw errorToMessage(error);
});

/**
 * Gọi API không kèm JWT (đặt chỗ khách). Tránh token cũ trong storage làm gọi nhầm `/bookings/public` và 401.
 */
export const guestApiClient = axios.create({
  baseURL: getApiBaseUrl(),
  timeout: 15000,
  headers: { "Content-Type": "application/json", Accept: "application/json" },
});

guestApiClient.interceptors.response.use(unwrapEnvelope, (error: AxiosError<{ message?: string }>) => {
  throw errorToMessage(error);
});

export default apiClient;
