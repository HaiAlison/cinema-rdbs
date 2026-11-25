import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsEnum, IsOptional, IsString } from 'class-validator';
import { EUserRole } from 'src/entities/user.entity';
import { CommonDto } from 'src/utils/common/dto';

export class ListUsersDto extends CommonDto {
  @ApiPropertyOptional({ enum: EUserRole })
  @IsOptional()
  @IsEnum(EUserRole)
  role?: EUserRole;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  is_active?: boolean;
}

