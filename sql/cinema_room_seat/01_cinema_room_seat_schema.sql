-- 1. Bổ sung cột dẫn xuất & ràng buộc cho bảng CINEMA
ALTER TABLE "cinema" ADD COLUMN IF NOT EXISTS "total_rooms" integer NOT NULL DEFAULT 0;
ALTER TABLE "cinema" ADD COLUMN IF NOT EXISTS "total_capacity" integer NOT NULL DEFAULT 0;

-- Số điện thoại / tổng đài rạp gồm 8-15 chữ số
ALTER TABLE "cinema" DROP CONSTRAINT IF EXISTS "chk_cinema_phone_format";
ALTER TABLE "cinema" ADD CONSTRAINT "chk_cinema_phone_format"
    CHECK ("phone" ~ '^[0-9]{8,15}$');

-- Tọa độ địa lý hợp lệ (nếu có nhập)
ALTER TABLE "cinema" DROP CONSTRAINT IF EXISTS "chk_cinema_lat";
ALTER TABLE "cinema" DROP CONSTRAINT IF EXISTS "chk_cinema_lat_range";
ALTER TABLE "cinema" ADD CONSTRAINT "chk_cinema_lat_range"
    CHECK ("lat" IS NULL OR ("lat" >= -90 AND "lat" <= 90));

ALTER TABLE "cinema" DROP CONSTRAINT IF EXISTS "chk_cinema_long";
ALTER TABLE "cinema" DROP CONSTRAINT IF EXISTS "chk_cinema_long_range";
ALTER TABLE "cinema" ADD CONSTRAINT "chk_cinema_long_range"
    CHECK ("long" IS NULL OR ("long" >= -180 AND "long" <= 180));

-- Đường dẫn Google Maps hợp lệ (nếu có nhập)
ALTER TABLE "cinema" DROP CONSTRAINT IF EXISTS "chk_cinema_link_ggmap";
ALTER TABLE "cinema" ADD CONSTRAINT "chk_cinema_link_ggmap"
    CHECK ("link_ggmap" IS NULL OR TRIM("link_ggmap") = '' OR "link_ggmap" ~* '^https?://');

-- Tổng số phòng và tổng sức chứa không được âm
ALTER TABLE "cinema" DROP CONSTRAINT IF EXISTS "chk_cinema_stats_non_negative";
ALTER TABLE "cinema" ADD CONSTRAINT "chk_cinema_stats_non_negative"
    CHECK ("total_rooms" >= 0 AND "total_capacity" >= 0);

-- 2. Bổ sung ràng buộc cho bảng SEAT_TYPE
ALTER TABLE "seat_type" DROP CONSTRAINT IF EXISTS "chk_seat_type_surcharge";
ALTER TABLE "seat_type" DROP CONSTRAINT IF EXISTS "chk_seat_type_surcharge_non_negative";
ALTER TABLE "seat_type" ADD CONSTRAINT "chk_seat_type_surcharge_non_negative"
    CHECK ("surcharge" >= 0);

ALTER TABLE "seat_type" DROP CONSTRAINT IF EXISTS "chk_seat_type_color_hex";
ALTER TABLE "seat_type" ADD CONSTRAINT "chk_seat_type_color_hex"
    CHECK ("color" IS NULL OR "color" ~* '^#[0-9A-F]{6}$');

-- 3. Bổ sung ràng buộc cho bảng ROOM
ALTER TABLE "room" ADD COLUMN IF NOT EXISTS "total_seats" integer DEFAULT 0;
UPDATE "room" SET "total_seats" = 0 WHERE "total_seats" IS NULL;
ALTER TABLE "room" ALTER COLUMN "total_seats" SET DEFAULT 0;
ALTER TABLE "room" ALTER COLUMN "total_seats" SET NOT NULL;

ALTER TABLE "room" DROP CONSTRAINT IF EXISTS "chk_room_total_seats_non_negative";
ALTER TABLE "room" ADD CONSTRAINT "chk_room_total_seats_non_negative"
    CHECK ("total_seats" >= 0);

ALTER TABLE "room" DROP CONSTRAINT IF EXISTS "uq_room_cinema_name";
ALTER TABLE "room" ADD CONSTRAINT "uq_room_cinema_name"
    UNIQUE ("cinema_id", "name");

-- 4. Bổ sung ràng buộc cho bảng SEAT
ALTER TABLE "seat" DROP CONSTRAINT IF EXISTS "chk_seat_row_col_not_blank";
ALTER TABLE "seat" DROP CONSTRAINT IF EXISTS "chk_seat_row_format";
ALTER TABLE "seat" ADD CONSTRAINT "chk_seat_row_format"
    CHECK ("row" ~ '^[A-Z]{1,2}$');

ALTER TABLE "seat" DROP CONSTRAINT IF EXISTS "chk_seat_col_format";
ALTER TABLE "seat" ADD CONSTRAINT "chk_seat_col_format"
    CHECK ("col" ~ '^0*[1-9][0-9]*$');

ALTER TABLE "seat" DROP CONSTRAINT IF EXISTS "uq_seat_room_row_col";
ALTER TABLE "seat" DROP CONSTRAINT IF EXISTS "uq_seat_room_position";
ALTER TABLE "seat" ADD CONSTRAINT "uq_seat_room_position"
    UNIQUE ("room_id", "row", "col");