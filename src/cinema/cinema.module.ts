import { Module } from '@nestjs/common';
import { CinemaService } from './cinema.service';
import { CinemaController } from './cinema.controller';
import { TypeOrmModule } from '@nestjs/typeorm';
import { CinemaEntity } from '@entities/cinema.entity';

@Module({
  imports: [TypeOrmModule.forFeature([CinemaEntity])],
  controllers: [CinemaController],
  providers: [CinemaService],
})
export class CinemaModule {}
