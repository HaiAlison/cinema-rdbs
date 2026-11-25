import { Module } from '@nestjs/common';
import { RoomsService } from './rooms.service';
import { RoomsController } from './rooms.controller';
import { TypeOrmModule } from '@nestjs/typeorm';
import { CinemaEntity } from '@/entities/cinema.entity';
import { RoomEntity } from '@/entities/room.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([CinemaEntity, RoomEntity]),
  ],
  controllers: [RoomsController],
  providers: [RoomsService]
})
export class RoomsModule {}
