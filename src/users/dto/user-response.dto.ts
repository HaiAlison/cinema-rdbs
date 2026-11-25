import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { UserStatus } from '../enums/user-status.enum';
import { PaginationResponse } from '../../utils/common/interface';
import { EUserRole } from 'src/entities/user.entity';

export class UserResponseDto {
  @ApiProperty({ example: '3fa85f64-5717-4562-b3fc-2c963f66afa6' })
  id: string;

  @ApiProperty({ example: 'Nguyen Van Admin' })
  name: string;

  @ApiProperty({ example: 'admin@tmc.com' })
  email: string;

  @ApiProperty({ enum: EUserRole, example: EUserRole.ADMIN })
  role: EUserRole;

  @ApiProperty()
  is_active: boolean;

  @ApiPropertyOptional()
  last_login?: Date | null;

  @ApiProperty()
  created_at: Date;
}
