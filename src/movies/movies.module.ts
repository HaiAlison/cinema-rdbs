import { Module } from '@nestjs/common';
import { MoviesService } from './movies.service';
import { MoviesController } from './movies.controller';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MovieEntity } from '@/entities/movie.entity';
import { FormatEntity } from '@/entities/format.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([MovieEntity, FormatEntity]),
  ],
  controllers: [MoviesController],
  providers: [MoviesService]
})
export class MoviesModule {}
