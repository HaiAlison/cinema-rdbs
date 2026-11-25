import { Body, Controller, Get, Param, Post, Query } from '@nestjs/common';
import { MoviesService } from './movies.service';
import { CreateMovieDto, ListMoviesDto } from './dto/movies.dto';

@Controller('movies')
export class MoviesController {
  constructor(private readonly moviesService: MoviesService) {}

  @Post()
  createMovie(@Body() dto: CreateMovieDto) {
    return this.moviesService.createMovie(dto);
  }

  @Get()
  findAll(@Query() dto: ListMoviesDto) {
    return this.moviesService.listMovies(dto);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.moviesService.findOne(id);
  }
}
