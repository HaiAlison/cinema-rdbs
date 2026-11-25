import { BadRequestException, Injectable } from '@nestjs/common';
import { CreateMovieDto, ListMoviesDto } from './dto/movies.dto';
import { Repository } from 'typeorm';
import { pagination } from '@/utils/common/handle';
import { MovieEntity } from '@/entities/movie.entity';
import { FormatEntity } from '@/entities/format.entity';
import { InjectRepository } from '@nestjs/typeorm';

@Injectable()
export class MoviesService {
    constructor(
        @InjectRepository(MovieEntity)
        private readonly movieRepository: Repository<MovieEntity>,
        @InjectRepository(FormatEntity)
        private readonly formatRepository: Repository<FormatEntity>
    ) {}
    async listMovies(dto: ListMoviesDto) {
        const qb = this.movieRepository.createQueryBuilder('m')

        return pagination<MovieEntity>(qb, dto)
    }

    async findOne(id: string) {
        const movie = await this.movieRepository.findOne({
            where: { id },
            relations: {
                formats: true,
            },
        })
    }

    async createMovie(dto: CreateMovieDto) {
        const formats = await this.formatRepository
            .createQueryBuilder('mf')
            .where('mf.id IN (:...ids)', { ids: dto.format_ids })
            .getMany();
        if (formats.length != dto.format_ids.length) {
            throw new BadRequestException("Invalid format")
        }
        const movie = this.movieRepository.create({
            actors: dto.actors,
            duration: dto.duration_minutes,
            genres: dto.genres,
            rated: dto.rated,
            release_date: dto.release_date,
            countries: dto.countries,
            description: dto.description,
            display_order: dto.display_order,
            name: dto.name,
            poster_url: dto.poster_url,
            formats: formats,
            directors: dto.directors,
            is_active: true,
            trailer_url: dto.trailer_url,
        })
        return await this.movieRepository.save(movie);
    }
}
