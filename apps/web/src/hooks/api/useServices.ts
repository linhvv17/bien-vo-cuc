import { useQuery } from "@tanstack/react-query";
import apiClient from "@/lib/api-client";
import { mockServices } from "@/mocks/services.mock";

const useMock = import.meta.env.VITE_USE_MOCK !== "false";

export const useServices = () =>
  useQuery({
    queryKey: ["services"],
    queryFn: async () => {
      if (useMock) return mockServices;
      return apiClient.get("services?isActive=true");
    },
    staleTime: 5 * 60 * 1000,
  });
