import { Body, Controller, HttpCode, Post } from '@nestjs/common';
import { RoomsService } from './rooms.service';
import { CreateRoomDto } from './rooms.dto';

@Controller('rooms')
export class RoomsController {
  constructor(private readonly roomsService: RoomsService) {}

  @Post()
  @HttpCode(201)
  createRoom(@Body() room: CreateRoomDto) {
    return this.roomsService.createRoom(room);
  }
}
