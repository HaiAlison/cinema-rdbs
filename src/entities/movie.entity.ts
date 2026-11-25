import { BaseTimeStampEntity } from "src/utils/config/database/base-entity";
import { Column, Entity, ManyToMany } from "typeorm";
import { FormatEntity } from "./format.entity";

@Entity('movie')
export class MovieEntity extends BaseTimeStampEntity {

    @Column()
    name: string;

    @Column({ type: 'text' })
    description: string;

    @Column()
    duration: number; //minutes

    @Column({ type: 'varchar' })
    rated: string;

    @Column()
    is_active: boolean;

    @Column({ type: 'int', default: 0 })
    display_order: number;

    @Column({ type: 'simple-array', nullable: true })
    languages?: string[];

    @Column({ type: 'timestamptz' })
    release_date: Date;

    @Column({ type: 'simple-array', nullable: true })
    countries?: string[];

    @Column({ type: 'simple-array', nullable: true })
    genres?: string[];

    @Column({ type: 'simple-array', nullable: true })
    directors?: string[];

    @Column({ type: 'simple-array', nullable: true })
    actors?: string[];

    @Column({ type: 'varchar', nullable: true })
    trailer_url?: string;

    @Column({ type: 'varchar', nullable: true })
    poster_url?: string;

    @ManyToMany(() => FormatEntity, format => format.movies)
    formats: FormatEntity[];
}