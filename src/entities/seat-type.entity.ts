import { BaseTimeStampEntity } from "src/utils/config/database/base-entity";
import { Column, Entity, OneToMany } from "typeorm";
import { SeatEntity } from "./seat.entity";

export enum ESeatTypeCode {
    STANDARD = 'standard',   // Ghế thường
    VIP = 'vip',             // Ghế VIP
    SWEETBOX = 'sweetbox',   // Ghế đôi
    DELUXE = 'deluxe',       // Ghế hạng sang / giường nằm
}

// Phân loại ghế ngồi trong rạp (Standard, VIP, Sweetbox...)
@Entity('seat_type')
export class SeatTypeEntity extends BaseTimeStampEntity {

    @Column({ type: 'varchar', length: 100 })
    name: string; // Tên hiển thị: 'Ghế thường', 'Ghế VIP', 'Sweetbox'

    @Column({ type: 'enum', enum: ESeatTypeCode, unique: true, default: ESeatTypeCode.STANDARD })
    code: ESeatTypeCode;

    // Phụ thu theo loại ghế (VNĐ) — cộng thêm vào giá vé cơ bản của suất chiếu
    @Column({ type: 'decimal', precision: 12, scale: 2, default: 0 })
    surcharge: number;

    // Mã màu HEX để hiển thị trực quan sơ đồ ghế trên giao diện (VD: #6C757D, #E50914, #FF69B4)
    @Column({ type: 'varchar', length: 20, nullable: true })
    color?: string;

    @Column({ type: 'text', nullable: true })
    description?: string;

    @Column({ type: 'boolean', default: true })
    is_active: boolean;

    @OneToMany(() => SeatEntity, seat => seat.seatType)
    seats: SeatEntity[];
}
