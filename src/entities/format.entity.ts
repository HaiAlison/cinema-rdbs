import { BaseTimeStampEntity } from "src/utils/config/database/base-entity";
import { Column, Entity, JoinTable, ManyToMany } from "typeorm";
import { MovieEntity } from "./movie.entity";
import { ShowtimeEntity } from "./showtime.entity";

// Định dạng chiếu phim (2D, 3D, IMAX, 4DX, ScreenX...)
@Entity('format')
export class FormatEntity extends BaseTimeStampEntity {

    @Column()
    name: string;

    @Column()
    description: string;

    @Column()
    price: number;

    @Column()
    is_active: boolean;

    @ManyToMany(() => MovieEntity, movie => movie.formats)
    @JoinTable({
        name: 'movie_format',
        joinColumn: { name: 'format_id' },
        inverseJoinColumn: { name: 'movie_id' }
    })
    movies: MovieEntity[];

    @ManyToMany(() => ShowtimeEntity, (showtime) => showtime.formats)
    showtimes: ShowtimeEntity[];
}