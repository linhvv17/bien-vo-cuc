-- Allow guest bookings (web / anonymous) without a User row.
ALTER TABLE "Booking" ALTER COLUMN "userId" DROP NOT NULL;
