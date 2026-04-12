import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import apiClient from "@/lib/api-client";

const useMockOnly = import.meta.env.VITE_USE_MOCK === "true";

/** Khớp payload `GET /bookings/me` (include service + provider, combo). */
export type WebBookingMine = {
  id: string;
  date: string;
  quantity: number;
  totalPrice: number;
  status: "PENDING" | "CONFIRMED" | "CANCELLED";
  customerName: string;
  customerPhone: string;
  customerNote?: string | null;
  bookingGroupId?: string | null;
  comboId?: string | null;
  createdAt: string;
  service: {
    id: string;
    name: string;
    type: string;
    provider?: { name: string } | null;
  };
  combo?: {
    id: string;
    title?: string | null;
    hotel?: { name: string };
    food?: { name: string };
  } | null;
};

export type MyBookingsStatusFilter = WebBookingMine["status"] | null;

export function useMyBookings(enabled: boolean, status: MyBookingsStatusFilter = null) {
  return useQuery({
    queryKey: ["my-bookings", status],
    queryFn: async () => {
      if (useMockOnly) return [] as WebBookingMine[];
      const params = status ? { status } : undefined;
      const res = await apiClient.get<WebBookingMine[]>("bookings/me", { params });
      return res.data;
    },
    enabled,
  });
}

export function useCancelMyBooking() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (bookingId: string) => {
      if (useMockOnly) return;
      await apiClient.patch(`bookings/me/${bookingId}/cancel`);
    },
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: ["my-bookings"] });
    },
  });
}
