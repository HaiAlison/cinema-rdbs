import { MigrationInterface, QueryRunner } from "typeorm";

export class init1793610462490 implements MigrationInterface {
    name = 'init1793610462490'

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`CREATE TYPE "public"."users_role_enum" AS ENUM('customer', 'staff', 'admin')`);
        await queryRunner.query(`CREATE TABLE "users" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT now(), "deleted_at" TIMESTAMP WITH TIME ZONE, "name" character varying(100) NOT NULL, "code" character varying(100) NOT NULL, "email" character varying(100) NOT NULL, "phone" character varying(15) NOT NULL, "dob" date, "province" character varying(100) NOT NULL, "avatar" character varying, "password" character varying NOT NULL, "sex" boolean, "salt" character varying NOT NULL, "is_active" boolean NOT NULL DEFAULT true, "role" "public"."users_role_enum" NOT NULL, CONSTRAINT "UQ_1f7a2b11e29b1422a2622beab36" UNIQUE ("code"), CONSTRAINT "PK_a3ffb1c0c8416b9fc6f907b7433" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE INDEX "idx_users_code" ON "users" ("code") `);
        await queryRunner.query(`CREATE TABLE "format" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT now(), "deleted_at" TIMESTAMP WITH TIME ZONE, "name" character varying NOT NULL, "description" character varying NOT NULL, "price" integer NOT NULL, "is_active" boolean NOT NULL, CONSTRAINT "PK_f9f8ca2f11b7b80bef08cef66fa" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TABLE "movie" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT now(), "deleted_at" TIMESTAMP WITH TIME ZONE, "name" character varying NOT NULL, "description" text NOT NULL, "duration" integer NOT NULL, "rated" character varying NOT NULL, "is_active" boolean NOT NULL, "display_order" integer NOT NULL DEFAULT '0', "languages" text, "release_date" TIMESTAMP WITH TIME ZONE NOT NULL, "countries" text, "genres" text, "directors" text, "actors" text, "trailer_url" character varying, "poster_url" character varying, CONSTRAINT "PK_cb3bb4d61cf764dc035cbedd422" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TABLE "cinema" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT now(), "deleted_at" TIMESTAMP WITH TIME ZONE, "name" character varying NOT NULL, "phone" character varying NOT NULL, "address" character varying NOT NULL, "ward" character varying, "city" character varying, "fax" character varying, "hotline" character varying, "image_urls" character varying array, "description" text, "lat" double precision, "long" double precision, "link_ggmap" character varying, "is_active" boolean NOT NULL DEFAULT true, CONSTRAINT "PK_65912fd9911f64e56eadf654912" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TYPE "public"."seat_type_code_enum" AS ENUM('standard', 'vip', 'sweetbox', 'deluxe')`);
        await queryRunner.query(`CREATE TABLE "seat_type" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT now(), "deleted_at" TIMESTAMP WITH TIME ZONE, "name" character varying(100) NOT NULL, "code" "public"."seat_type_code_enum" NOT NULL DEFAULT 'standard', "surcharge" numeric(12,2) NOT NULL DEFAULT '0', "color" character varying(20), "description" text, "is_active" boolean NOT NULL DEFAULT true, CONSTRAINT "UQ_2cc9a3eee0502890e2846ad500f" UNIQUE ("code"), CONSTRAINT "PK_d970400a133c4fd645ac8112f74" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TABLE "seat" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT now(), "deleted_at" TIMESTAMP WITH TIME ZONE, "room_id" uuid NOT NULL, "seat_type_id" uuid NOT NULL, "row" character varying(10) NOT NULL, "col" character varying(10) NOT NULL, CONSTRAINT "PK_4e72ae40c3fbd7711ccb380ac17" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TYPE "public"."room_roomtype_enum" AS ENUM('imax', '4dx', 'ultra_4dx', 'starium', 'infinity', 'golden_class', 'lamour', 'sweet_box', 'standard_2d', 'standard_3d')`);
        await queryRunner.query(`CREATE TABLE "room" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT now(), "deleted_at" TIMESTAMP WITH TIME ZONE, "name" character varying NOT NULL, "cinema_id" uuid NOT NULL, "roomType" "public"."room_roomtype_enum" NOT NULL, CONSTRAINT "PK_c6d46db005d623e691b2fbcba23" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TYPE "public"."showtime_subtitle_type_enum" AS ENUM('subtitled', 'dubbed', 'original')`);
        await queryRunner.query(`CREATE TYPE "public"."showtime_status_enum" AS ENUM('upcoming', 'open', 'full', 'ended', 'cancelled')`);
        await queryRunner.query(`CREATE TABLE "showtime" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT now(), "deleted_at" TIMESTAMP WITH TIME ZONE, "movie_id" uuid NOT NULL, "room_id" uuid NOT NULL, "start_time" TIMESTAMP WITH TIME ZONE NOT NULL, "end_time" TIMESTAMP WITH TIME ZONE NOT NULL, "language" character varying(10) NOT NULL DEFAULT 'vi', "subtitle_type" "public"."showtime_subtitle_type_enum", "status" "public"."showtime_status_enum" NOT NULL DEFAULT 'upcoming', "base_price" numeric(12,2) NOT NULL, "is_active" boolean NOT NULL DEFAULT true, CONSTRAINT "PK_46e9942cf953d98b7dc4392a3e8" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TYPE "public"."promotion_type_enum" AS ENUM('percentage', 'fixed_amount', 'free_combo', 'buy_x_get_y', 'gift_card')`);
        await queryRunner.query(`CREATE TYPE "public"."promotion_scope_enum" AS ENUM('all', 'ticket_only', 'combo_only', 'specific_movie', 'specific_cinema', 'specific_day')`);
        await queryRunner.query(`CREATE TABLE "promotion" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT now(), "deleted_at" TIMESTAMP WITH TIME ZONE, "name" character varying(200) NOT NULL, "description" text, "code" character varying(100), "type" "public"."promotion_type_enum" NOT NULL, "scope" "public"."promotion_scope_enum" NOT NULL DEFAULT 'all', "discount_value" numeric(12,2) NOT NULL, "max_discount_amount" numeric(12,2), "min_order_amount" numeric(12,2), "start_date" TIMESTAMP WITH TIME ZONE NOT NULL, "end_date" TIMESTAMP WITH TIME ZONE NOT NULL, "usage_limit" integer, "used_count" integer NOT NULL DEFAULT '0', "per_user_limit" integer, "banner_url" character varying, "applicable_movie_ids" text, "applicable_cinema_ids" text, "is_active" boolean NOT NULL DEFAULT true, CONSTRAINT "UQ_969359329a22440d2b8f7d491d4" UNIQUE ("code"), CONSTRAINT "PK_fab3630e0789a2002f1cadb7d38" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TYPE "public"."booking_status_enum" AS ENUM('pending', 'confirmed', 'cancelled', 'expired', 'refunded')`);
        await queryRunner.query(`CREATE TABLE "booking" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT now(), "deleted_at" TIMESTAMP WITH TIME ZONE, "booking_code" character varying NOT NULL, "user_id" uuid NOT NULL, "showtime_id" uuid NOT NULL, "ticket_total" numeric(12,2) NOT NULL, "combo_total" numeric(12,2) NOT NULL DEFAULT '0', "discount_amount" numeric(12,2) NOT NULL DEFAULT '0', "final_amount" numeric(12,2) NOT NULL, "promotion_id" uuid, "status" "public"."booking_status_enum" NOT NULL DEFAULT 'pending', "expired_at" TIMESTAMP WITH TIME ZONE, "confirmed_at" TIMESTAMP WITH TIME ZONE, "points_earned" integer NOT NULL DEFAULT '0', "points_used" integer NOT NULL DEFAULT '0', CONSTRAINT "UQ_baf7e49c4f7b05acfefbf9dbb18" UNIQUE ("booking_code"), CONSTRAINT "PK_49171efc69702ed84c812f33540" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TYPE "public"."combo_category_enum" AS ENUM('popcorn', 'drink', 'combo', 'snack', 'meal', 'gift')`);
        await queryRunner.query(`CREATE TYPE "public"."combo_size_enum" AS ENUM('S', 'M', 'L', 'XL')`);
        await queryRunner.query(`CREATE TABLE "combo" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT now(), "deleted_at" TIMESTAMP WITH TIME ZONE, "name" character varying(200) NOT NULL, "description" text, "category" "public"."combo_category_enum" NOT NULL, "size" "public"."combo_size_enum", "price" numeric(12,2) NOT NULL, "image_url" character varying, "is_available" boolean NOT NULL DEFAULT true, "is_e_combo" boolean NOT NULL DEFAULT false, "display_order" integer NOT NULL DEFAULT '0', CONSTRAINT "PK_7f13547266097aa634ddefd34f9" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TABLE "booking_combo" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT now(), "deleted_at" TIMESTAMP WITH TIME ZONE, "booking_id" uuid NOT NULL, "combo_id" uuid NOT NULL, "quantity" integer NOT NULL DEFAULT '1', "unit_price" numeric(12,2) NOT NULL, "subtotal" numeric(12,2) NOT NULL, CONSTRAINT "PK_4654c186d2f71e582ac7a1ae4b9" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TYPE "public"."membership_tier_enum" AS ENUM('standard', 'vip', 'vvip')`);
        await queryRunner.query(`CREATE TABLE "membership" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT now(), "deleted_at" TIMESTAMP WITH TIME ZONE, "user_id" uuid NOT NULL, "member_code" character varying NOT NULL, "tier" "public"."membership_tier_enum" NOT NULL DEFAULT 'standard', "cgv_points" integer NOT NULL DEFAULT '0', "total_points_earned" integer NOT NULL DEFAULT '0', "tier_expiry_date" date, "is_active" boolean NOT NULL DEFAULT true, CONSTRAINT "UQ_e9c72e8d29784031c96f5c6af8d" UNIQUE ("user_id"), CONSTRAINT "UQ_6172cc6fd5ac367412d2563e93a" UNIQUE ("member_code"), CONSTRAINT "REL_e9c72e8d29784031c96f5c6af8" UNIQUE ("user_id"), CONSTRAINT "PK_83c1afebef3059472e7c37e8de8" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TYPE "public"."point_transaction_type_enum" AS ENUM('earn', 'redeem', 'expire', 'adjust', 'bonus', 'refund')`);
        await queryRunner.query(`CREATE TABLE "point_transaction" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT now(), "deleted_at" TIMESTAMP WITH TIME ZONE, "membership_id" uuid NOT NULL, "type" "public"."point_transaction_type_enum" NOT NULL, "points" integer NOT NULL, "balance_after" integer NOT NULL, "reference_id" character varying, "note" text, "expire_at" TIMESTAMP WITH TIME ZONE, CONSTRAINT "PK_b56b792bcf7f60a32758005caf7" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TYPE "public"."booking_detail_status_enum" AS ENUM('active', 'used', 'cancelled')`);
        await queryRunner.query(`CREATE TABLE "booking_detail" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT now(), "deleted_at" TIMESTAMP WITH TIME ZONE, "booking_id" uuid NOT NULL, "seat_id" uuid NOT NULL, "seat_label" character varying(50) NOT NULL, "seat_type" character varying(50) NOT NULL, "price" numeric(12,2) NOT NULL, "status" "public"."booking_detail_status_enum" NOT NULL DEFAULT 'active', "qr_code" character varying, CONSTRAINT "PK_6e95d603aebbeed01303d73c50b" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TYPE "public"."payment_method_enum" AS ENUM('credit_card', 'momo', 'zalopay', 'vnpay', 'banking', 'cgv_giftcard', 'cgv_point', 'cash', 'shopeepay')`);
        await queryRunner.query(`CREATE TYPE "public"."payment_status_enum" AS ENUM('pending', 'success', 'failed', 'refunded')`);
        await queryRunner.query(`CREATE TABLE "payment" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT now(), "deleted_at" TIMESTAMP WITH TIME ZONE, "booking_id" uuid NOT NULL, "method" "public"."payment_method_enum" NOT NULL, "amount" numeric(12,2) NOT NULL, "status" "public"."payment_status_enum" NOT NULL DEFAULT 'pending', "transaction_id" character varying, "gateway_response" character varying, "paid_at" TIMESTAMP WITH TIME ZONE, CONSTRAINT "PK_fcaec7df5adf9cac408c686b2ab" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TABLE "movie_format" ("format_id" uuid NOT NULL, "movie_id" uuid NOT NULL, CONSTRAINT "PK_d653c6db2fef0275ff3e1a1a118" PRIMARY KEY ("format_id", "movie_id"))`);
        await queryRunner.query(`CREATE INDEX "IDX_9f49184ac0833c9e6894dbf697" ON "movie_format" ("format_id") `);
        await queryRunner.query(`CREATE INDEX "IDX_e304632bbf4321f3fe8c164f9a" ON "movie_format" ("movie_id") `);
        await queryRunner.query(`ALTER TABLE "seat" ADD CONSTRAINT "FK_5d28198242955d0e31856a44306" FOREIGN KEY ("room_id") REFERENCES "room"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "seat" ADD CONSTRAINT "FK_a8ffc17dea7290cae79ca2b90cd" FOREIGN KEY ("seat_type_id") REFERENCES "seat_type"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "room" ADD CONSTRAINT "FK_51fb27bdd72a12d0513629670b3" FOREIGN KEY ("cinema_id") REFERENCES "cinema"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "showtime" ADD CONSTRAINT "FK_bc94f84c1bccb64bbf6a785fadf" FOREIGN KEY ("movie_id") REFERENCES "movie"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "showtime" ADD CONSTRAINT "FK_cd90bd7850edc068c28a1d9b783" FOREIGN KEY ("room_id") REFERENCES "room"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "booking" ADD CONSTRAINT "FK_276896d1a1a30be6de9d7d43f53" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "booking" ADD CONSTRAINT "FK_819e5cda0eecac462cb584c733e" FOREIGN KEY ("showtime_id") REFERENCES "showtime"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "booking" ADD CONSTRAINT "FK_f7dfd9c53ce9f287c27e2bdec16" FOREIGN KEY ("promotion_id") REFERENCES "promotion"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "booking_combo" ADD CONSTRAINT "FK_c53fbb22779cbc6ebc3ced7f3f1" FOREIGN KEY ("booking_id") REFERENCES "booking"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "booking_combo" ADD CONSTRAINT "FK_310d3549938a056ff273ae4727f" FOREIGN KEY ("combo_id") REFERENCES "combo"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "membership" ADD CONSTRAINT "FK_e9c72e8d29784031c96f5c6af8d" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "point_transaction" ADD CONSTRAINT "FK_e5f4b5e3f80a63665c24427bc18" FOREIGN KEY ("membership_id") REFERENCES "membership"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "booking_detail" ADD CONSTRAINT "FK_9d653303b2704bb03eba7c71c8b" FOREIGN KEY ("booking_id") REFERENCES "booking"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "booking_detail" ADD CONSTRAINT "FK_a69fdc805e5b26fe4a0cc7cd711" FOREIGN KEY ("seat_id") REFERENCES "seat"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "payment" ADD CONSTRAINT "FK_cee78453638dfaf440f1aa63c26" FOREIGN KEY ("booking_id") REFERENCES "booking"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "movie_format" ADD CONSTRAINT "FK_9f49184ac0833c9e6894dbf697e" FOREIGN KEY ("format_id") REFERENCES "format"("id") ON DELETE CASCADE ON UPDATE CASCADE`);
        await queryRunner.query(`ALTER TABLE "movie_format" ADD CONSTRAINT "FK_e304632bbf4321f3fe8c164f9a5" FOREIGN KEY ("movie_id") REFERENCES "movie"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "movie_format" DROP CONSTRAINT "FK_e304632bbf4321f3fe8c164f9a5"`);
        await queryRunner.query(`ALTER TABLE "movie_format" DROP CONSTRAINT "FK_9f49184ac0833c9e6894dbf697e"`);
        await queryRunner.query(`ALTER TABLE "payment" DROP CONSTRAINT "FK_cee78453638dfaf440f1aa63c26"`);
        await queryRunner.query(`ALTER TABLE "booking_detail" DROP CONSTRAINT "FK_a69fdc805e5b26fe4a0cc7cd711"`);
        await queryRunner.query(`ALTER TABLE "booking_detail" DROP CONSTRAINT "FK_9d653303b2704bb03eba7c71c8b"`);
        await queryRunner.query(`ALTER TABLE "point_transaction" DROP CONSTRAINT "FK_e5f4b5e3f80a63665c24427bc18"`);
        await queryRunner.query(`ALTER TABLE "membership" DROP CONSTRAINT "FK_e9c72e8d29784031c96f5c6af8d"`);
        await queryRunner.query(`ALTER TABLE "booking_combo" DROP CONSTRAINT "FK_310d3549938a056ff273ae4727f"`);
        await queryRunner.query(`ALTER TABLE "booking_combo" DROP CONSTRAINT "FK_c53fbb22779cbc6ebc3ced7f3f1"`);
        await queryRunner.query(`ALTER TABLE "booking" DROP CONSTRAINT "FK_f7dfd9c53ce9f287c27e2bdec16"`);
        await queryRunner.query(`ALTER TABLE "booking" DROP CONSTRAINT "FK_819e5cda0eecac462cb584c733e"`);
        await queryRunner.query(`ALTER TABLE "booking" DROP CONSTRAINT "FK_276896d1a1a30be6de9d7d43f53"`);
        await queryRunner.query(`ALTER TABLE "showtime" DROP CONSTRAINT "FK_cd90bd7850edc068c28a1d9b783"`);
        await queryRunner.query(`ALTER TABLE "showtime" DROP CONSTRAINT "FK_bc94f84c1bccb64bbf6a785fadf"`);
        await queryRunner.query(`ALTER TABLE "room" DROP CONSTRAINT "FK_51fb27bdd72a12d0513629670b3"`);
        await queryRunner.query(`ALTER TABLE "seat" DROP CONSTRAINT "FK_a8ffc17dea7290cae79ca2b90cd"`);
        await queryRunner.query(`ALTER TABLE "seat" DROP CONSTRAINT "FK_5d28198242955d0e31856a44306"`);
        await queryRunner.query(`DROP INDEX "public"."IDX_e304632bbf4321f3fe8c164f9a"`);
        await queryRunner.query(`DROP INDEX "public"."IDX_9f49184ac0833c9e6894dbf697"`);
        await queryRunner.query(`DROP TABLE "movie_format"`);
        await queryRunner.query(`DROP TABLE "payment"`);
        await queryRunner.query(`DROP TYPE "public"."payment_status_enum"`);
        await queryRunner.query(`DROP TYPE "public"."payment_method_enum"`);
        await queryRunner.query(`DROP TABLE "booking_detail"`);
        await queryRunner.query(`DROP TYPE "public"."booking_detail_status_enum"`);
        await queryRunner.query(`DROP TABLE "point_transaction"`);
        await queryRunner.query(`DROP TYPE "public"."point_transaction_type_enum"`);
        await queryRunner.query(`DROP TABLE "membership"`);
        await queryRunner.query(`DROP TYPE "public"."membership_tier_enum"`);
        await queryRunner.query(`DROP TABLE "booking_combo"`);
        await queryRunner.query(`DROP TABLE "combo"`);
        await queryRunner.query(`DROP TYPE "public"."combo_size_enum"`);
        await queryRunner.query(`DROP TYPE "public"."combo_category_enum"`);
        await queryRunner.query(`DROP TABLE "booking"`);
        await queryRunner.query(`DROP TYPE "public"."booking_status_enum"`);
        await queryRunner.query(`DROP TABLE "promotion"`);
        await queryRunner.query(`DROP TYPE "public"."promotion_scope_enum"`);
        await queryRunner.query(`DROP TYPE "public"."promotion_type_enum"`);
        await queryRunner.query(`DROP TABLE "showtime"`);
        await queryRunner.query(`DROP TYPE "public"."showtime_status_enum"`);
        await queryRunner.query(`DROP TYPE "public"."showtime_subtitle_type_enum"`);
        await queryRunner.query(`DROP TABLE "room"`);
        await queryRunner.query(`DROP TYPE "public"."room_roomtype_enum"`);
        await queryRunner.query(`DROP TABLE "seat"`);
        await queryRunner.query(`DROP TABLE "seat_type"`);
        await queryRunner.query(`DROP TYPE "public"."seat_type_code_enum"`);
        await queryRunner.query(`DROP TABLE "cinema"`);
        await queryRunner.query(`DROP TABLE "movie"`);
        await queryRunner.query(`DROP TABLE "format"`);
        await queryRunner.query(`DROP INDEX "public"."idx_users_code"`);
        await queryRunner.query(`DROP TABLE "users"`);
        await queryRunner.query(`DROP TYPE "public"."users_role_enum"`);
    }

}
