import { BaseTimeStampEntity } from "src/utils/config/database/base-entity";
import { Column, Entity, JoinColumn, ManyToOne } from "typeorm";
import { RoomEntity } from "./room.entity";
import { SeatTypeEntity } from "./seat-type.entity";

@Entity('seat')
export class SeatEntity extends BaseTimeStampEntity {
    @Column()
    room_id: string;

    @ManyToOne(() => RoomEntity, room => room.seats)
    @JoinColumn({ name: 'room_id' })
    room: RoomEntity;

    @Column()
    seat_type_id: string;

    @ManyToOne(() => SeatTypeEntity, seatType => seatType.seats)
    @JoinColumn({ name: 'seat_type_id' })
    seatType: SeatTypeEntity;

    @Column({ type: 'varchar', length: 10 })
    row: string;

    @Column({ type: 'varchar', length: 10 })
    col: string;
}