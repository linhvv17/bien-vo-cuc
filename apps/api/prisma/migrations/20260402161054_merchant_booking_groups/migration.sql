-- AlterEnum
ALTER TYPE "Role" ADD VALUE 'MERCHANT';

-- AlterTable
ALTER TABLE "Booking" ADD COLUMN     "bookingGroupId" TEXT,
ADD COLUMN     "comboId" TEXT;

-- AlterTable
ALTER TABLE "User" ADD COLUMN     "providerId" TEXT;

-- CreateIndex
CREATE INDEX "Booking_customerPhone_idx" ON "Booking"("customerPhone");

-- CreateIndex
CREATE INDEX "Booking_comboId_idx" ON "Booking"("comboId");

-- CreateIndex
CREATE INDEX "Booking_bookingGroupId_idx" ON "Booking"("bookingGroupId");

-- CreateIndex
CREATE INDEX "User_providerId_idx" ON "User"("providerId");

-- AddForeignKey
ALTER TABLE "User" ADD CONSTRAINT "User_providerId_fkey" FOREIGN KEY ("providerId") REFERENCES "Provider"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Booking" ADD CONSTRAINT "Booking_comboId_fkey" FOREIGN KEY ("comboId") REFERENCES "Combo"("id") ON DELETE SET NULL ON UPDATE CASCADE;
