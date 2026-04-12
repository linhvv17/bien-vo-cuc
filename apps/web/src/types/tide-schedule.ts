/** Khớp `TideSchedule` từ `GET /tides/range` (Prisma → JSON). */
export type TideScheduleApi = {
  id: string;
  date: string;
  lowTime1: string;
  lowHeight1: number;
  lowTime2: string | null;
  lowHeight2: number | null;
  isGolden: boolean;
  note: string | null;
};
