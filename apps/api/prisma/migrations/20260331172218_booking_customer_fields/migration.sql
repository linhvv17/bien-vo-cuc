/*
  Warnings:

  - Added the required column `customerName` to the `Booking` table without a default value. This is not possible if the table is not empty.
  - Added the required column `customerPhone` to the `Booking` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "Booking" ADD COLUMN     "customerName" TEXT NOT NULL,
ADD COLUMN     "customerNote" TEXT,
ADD COLUMN     "customerPhone" TEXT NOT NULL;
