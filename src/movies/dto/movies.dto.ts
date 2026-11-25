import { CommonDto } from "@/utils/common/dto";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import { IsArray, IsBoolean, IsDate, IsNotEmpty, IsNumber, IsOptional, IsString } from "class-validator";


export class ListMoviesDto extends CommonDto {

}

export class CreateMovieDto {
    @ApiProperty()
    @IsString()
    @IsNotEmpty()
    name: string;


    @ApiPropertyOptional()
    @IsString()
    @IsOptional()
    description?: string;

    @ApiProperty()
    @IsString()
    @IsNotEmpty()
    type: string;

    @ApiProperty()
    @IsString()
    @IsNotEmpty()
    rated: string;

    @ApiProperty()
    @IsBoolean()
    @IsNotEmpty()
    is_active: boolean;

    @ApiProperty()
    @IsArray()
    @IsString({ each: true })
    @IsNotEmpty()
    languages: string[];

    @ApiProperty()
    @IsNumber()
    @IsNotEmpty()
    duration_minutes: number;

    @ApiProperty()
    @IsDate()
    @IsNotEmpty()
    release_date: Date;


    @ApiProperty()
    @IsArray()
    @IsString({ each: true })
    @IsOptional()
    countries: string[];

    @ApiProperty()
    @IsArray()
    @IsString({ each: true })
    @IsOptional()
    genres?: string[];


    @ApiProperty()
    @IsArray()
    @IsString({ each: true })
    @IsOptional()
    directors: string[];


    @ApiProperty()
    @IsArray()
    @IsString({ each: true })
    @IsOptional()
    actors: string[];


    @ApiProperty()
    @IsString()
    @IsOptional()
    trailer_url?: string;


    @ApiProperty()
    @IsString()
    @IsOptional()
    poster_url?: string;

    @ApiProperty()
    @IsNumber()
    @IsOptional()
    display_order?: number;

    @ApiProperty()
    @IsString({ each: true })
    @IsArray()
    @IsNotEmpty()
    format_ids: string[];


}