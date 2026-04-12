-- CreateEnum
CREATE TYPE "UserKind" AS ENUM ('APP_CUSTOMER', 'PROVIDER_ACCOUNT', 'SYSTEM_STAFF');

-- AlterTable
ALTER TABLE "User" ADD COLUMN "userKind" "UserKind" NOT NULL DEFAULT 'APP_CUSTOMER';

-- Backfill theo role hiện có
UPDATE "User" SET "userKind" = 'PROVIDER_ACCOUNT' WHERE "role" = 'MERCHANT';
UPDATE "User" SET "userKind" = 'SYSTEM_STAFF' WHERE "role" IN ('ADMIN', 'MODERATOR', 'CONTENT_EDITOR');
