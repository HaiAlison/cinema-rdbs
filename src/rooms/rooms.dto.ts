import { ERoomType } from "@/entities/room.entity";
import { ApiProperty } from "@nestjs/swagger";

export class CreateRoomDto {

    @ApiProperty()
    name: string;

    @ApiProperty()
    capacity: number;

    @ApiProperty()
    description: string;

    @ApiProperty()
    cinema_id: string;

    @ApiProperty({ enum: ERoomType, example: ERoomType.STANDARD_2D })
    room_type: ERoomType;
}

export class UpdateRoomDto extends CreateRoomDto {
    @ApiProperty()
    id: string;
}