import { useInfiniteQuery } from "@tanstack/react-query";
import apiClient from "@/lib/api-client";
import { mockGallery } from "@/mocks/gallery.mock";
import type { GalleryItem } from "@/mocks/gallery.mock";

const useMock = import.meta.env.VITE_USE_MOCK !== "false";
const PAGE_SIZE = 12;

export const useGallery = () =>
  useInfiniteQuery<GalleryItem[]>({
    queryKey: ["gallery"],
    queryFn: async ({ pageParam = 1 }) => {
      if (useMock) {
        const start = ((pageParam as number) - 1) * PAGE_SIZE;
        return mockGallery.slice(start, start + PAGE_SIZE);
      }
      return apiClient.get(`gallery?page=${pageParam}&limit=${PAGE_SIZE}&sort=createdAt&order=desc`);
    },
    getNextPageParam: (lastPage, allPages) => {
      if (lastPage.length < PAGE_SIZE) return undefined;
      return allPages.length + 1;
    },
    initialPageParam: 1,
  });
