import { BadRequestException, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { RoomEntity } from '@entities/room.entity';
import { Repository } from 'typeorm';
import { CreateRoomDto } from './rooms.dto';
import { CinemaEntity } from '@/entities/cinema.entity';

@Injectable()
export class RoomsService {

    constructor(
        @InjectRepository(RoomEntity)
        private readonly roomRepository: Repository<RoomEntity>,
        @InjectRepository(CinemaEntity)
        private readonly cinemaRepository: Repository<CinemaEntity>,
    ) {}

    async createRoom(dto: CreateRoomDto): Promise<RoomEntity> {
        const cinema = await this.cinemaRepository.findOne({ where: { id: dto.cinema_id } });
        if (!cinema) {
            throw new BadRequestException('Cinema not found');
        }
        const roomEntity = this.roomRepository.create({
            name: dto.name,
            total_seats: dto.capacity,
            room_type: dto.room_type,
            cinema_id: cinema.id,
        });
        return this.roomRepository.save(roomEntity);
    }
}
