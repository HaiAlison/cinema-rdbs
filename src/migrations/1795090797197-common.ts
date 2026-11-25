import { MigrationInterface, QueryRunner } from "typeorm";

export class common1795090797197 implements MigrationInterface {
    name = 'common1795090797197'

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "room" DROP COLUMN "roomType"`);
        await queryRunner.query(`DROP TYPE "public"."room_roomtype_enum"`);
        await queryRunner.query(`ALTER TABLE "users" ADD "refresh_token_hash" character varying(255)`);
        await queryRunner.query(`ALTER TABLE "users" ADD "last_login" TIMESTAMP WITH TIME ZONE`);
        await queryRunner.query(`CREATE TYPE "public"."room_room_type_enum" AS ENUM('imax', '4dx', 'ultra_4dx', 'starium', 'infinity', 'golden_class', 'lamour', 'sweet_box', 'standard_2d', 'standard_3d')`);
        await queryRunner.query(`ALTER TABLE "room" ADD "room_type" "public"."room_room_type_enum"`);
        await queryRunner.query(`ALTER TABLE "room" ADD "total_seats" integer `);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "room" DROP COLUMN "total_seats"`);
        await queryRunner.query(`ALTER TABLE "room" DROP COLUMN "room_type"`);
        await queryRunner.query(`DROP TYPE "public"."room_room_type_enum"`);
        await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "last_login"`);
        await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "refresh_token_hash"`);
        await queryRunner.query(`CREATE TYPE "public"."room_roomtype_enum" AS ENUM('imax', '4dx', 'ultra_4dx', 'starium', 'infinity', 'golden_class', 'lamour', 'sweet_box', 'standard_2d', 'standard_3d')`);
        await queryRunner.query(`ALTER TABLE "room" ADD "roomType" "public"."room_roomtype_enum" NOT NULL`);
    }

}
