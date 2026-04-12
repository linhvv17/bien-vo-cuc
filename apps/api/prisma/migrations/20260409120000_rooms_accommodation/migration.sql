-- CreateEnum
CREATE TYPE "RoomType" AS ENUM ('SINGLE', 'DOUBLE', 'TWIN', 'FAMILY', 'DORM', 'SUITE', 'QUAD');

-- AlterTable Service
ALTER TABLE "Service" ADD COLUMN "addressLine" TEXT;
ALTER TABLE "Service" ADD COLUMN "locationSummary" TEXT;

-- CreateTable
CREATE TABLE "Room" (
    "id" TEXT NOT NULL,
    "serviceId" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "roomType" "RoomType" NOT NULL,
    "maxGuests" INTEGER NOT NULL DEFAULT 2,
    "floor" INTEGER,
    "images" TEXT[],
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Room_pkey" PRIMARY KEY ("id")
);

-- AlterTable Booking
ALTER TABLE "Booking" ADD COLUMN "roomId" TEXT;
ALTER TABLE "Booking" ADD COLUMN "roomAssignment" TEXT;
ALTER TABLE "Booking" ADD COLUMN "guestPreferences" TEXT[] DEFAULT ARRAY[]::TEXT[];

-- CreateIndex
CREATE UNIQUE INDEX "Room_serviceId_code_key" ON "Room"("serviceId", "code");
CREATE INDEX "Room_serviceId_idx" ON "Room"("serviceId");
CREATE INDEX "Room_isActive_idx" ON "Room"("isActive");
CREATE INDEX "Booking_roomId_idx" ON "Booking"("roomId");

-- AddForeignKey
ALTER TABLE "Room" ADD CONSTRAINT "Room_serviceId_fkey" FOREIGN KEY ("serviceId") REFERENCES "Service"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Booking" ADD CONSTRAINT "Booking_roomId_fkey" FOREIGN KEY ("roomId") REFERENCES "Room"("id") ON DELETE SET NULL ON UPDATE CASCADE;
