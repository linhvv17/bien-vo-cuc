import { useQuery } from "@tanstack/react-query";
import apiClient, { guestApiClient } from "@/lib/api-client";
import { mockTides, mockGoldenHours, mockTideRange } from "@/mocks/tides.mock";
import type { TideData } from "@/mocks/tides.mock";
import type { TideScheduleApi } from "@/types/tide-schedule";

const useMock = import.meta.env.VITE_USE_MOCK !== "false";
const useMockStrict = import.meta.env.VITE_USE_MOCK === "true";

export const useTides = (date?: string) =>
  useQuery<TideData[]>({
    queryKey: ["tides", date],
    queryFn: async () => {
      if (useMock) return mockTides;
      return apiClient.get(`tides${date ? `?date=${date}` : ""}`);
    },
    staleTime: 60 * 60 * 1000,
  });

export const useGoldenHours = (from?: string, to?: string) =>
  useQuery<TideData[]>({
    queryKey: ["tides", "golden", from, to],
    queryFn: async () => {
      if (useMock) return mockGoldenHours;
      return apiClient.get(`tides/golden-hours?from=${from}&to=${to}`);
    },
    staleTime: 60 * 60 * 1000,
    enabled: !!from && !!to,
  });

/** Lịch triều theo khoảng ngày — dùng chung với dự báo 7 ngày (web / mobile). */
export const useTidesRange = (from: string | undefined, to: string | undefined) =>
  useQuery<TideScheduleApi[]>({
    queryKey: ["tides", "range", from, to],
    queryFn: async () => {
      if (!from || !to) return [];
      if (useMockStrict) return mockTideRange(from, to);
      const res = await guestApiClient.get<TideScheduleApi[]>("tides/range", {
        params: { from, to },
      });
      return res.data;
    },
    staleTime: 60 * 60 * 1000,
    enabled: !!from && !!to,
  });
