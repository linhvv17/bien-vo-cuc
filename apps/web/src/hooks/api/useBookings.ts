import { useMutation } from "@tanstack/react-query";
import apiClient, { guestApiClient } from "@/lib/api-client";

const useMockOnly = import.meta.env.VITE_USE_MOCK === "true";

/** Body khớp `POST /bookings/public` (có JWT) hoặc `POST /bookings/guest` (không đăng nhập). */
export type CreatePublicBookingBody = {
  serviceId: string;
  date: string;
  quantity: number;
  customerName: string;
  customerPhone: string;
  customerNote?: string;
};

/** `asGuest` lấy từ UI (`!session`) — không dựa vào token trong storage (tránh JWT hết hạn gọi nhầm public). */
export type CreatePublicBookingInput = CreatePublicBookingBody & { asGuest: boolean };

export const useCreatePublicBooking = () =>
  useMutation({
    mutationFn: async (input: CreatePublicBookingInput) => {
      if (useMockOnly) {
        await new Promise((r) => setTimeout(r, 700));
        return { demo: true };
      }
      const { asGuest, ...body } = input;
      if (asGuest) {
        return guestApiClient.post("bookings/guest", body);
      }
      return apiClient.post("bookings/public", body);
    },
  });
