import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsDateString, IsEnum, IsNotEmpty, IsNumber, IsOptional, IsString } from 'class-validator';
import { Type } from 'class-transformer';

export class CreateUserProcedureDto {
  @ApiProperty({ example: 'DEMO99' })
  @IsString()
  @IsNotEmpty()
  code: string;

  @ApiProperty({ example: 'Nguyễn Văn Mẫu' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({ example: 'mau.nguyen@example.com' })
  @IsString()
  @IsNotEmpty()
  email: string;

  @ApiProperty({ example: '0912345678' })
  @IsString()
  @IsNotEmpty()
  phone: string;

  @ApiPropertyOptional({ example: '2000-01-01' })
  @IsOptional()
  @IsDateString()
  dob?: string;

  @ApiProperty({ example: 'Hồ Chí Minh' })
  @IsString()
  @IsNotEmpty()
  province: string;

  @ApiProperty({ example: 'Password123' })
  @IsString()
  @IsNotEmpty()
  password: string;

  @ApiPropertyOptional({ example: 'customer', enum: ['customer', 'staff', 'admin'] })
  @IsOptional()
  @IsString()
  role?: string;
}

export class UpdateUserProcedureDto {
  @ApiPropertyOptional({ example: 'Nguyễn Văn Mẫu Đổi Tên' })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional({ example: '0988776655' })
  @IsOptional()
  @IsString()
  phone?: string;

  @ApiPropertyOptional({ example: 'Hà Nội' })
  @IsOptional()
  @IsString()
  province?: string;

  @ApiPropertyOptional({ example: true })
  @IsOptional()
  is_active?: boolean;
}

export class QueryUserProcedureDto {
  @ApiPropertyOptional({ example: 'Hồ Chí Minh' })
  @IsOptional()
  @IsString()
  province?: string;

  @ApiPropertyOptional({ example: 'standard', enum: ['standard', 'vip', 'vvip'] })
  @IsOptional()
  @IsString()
  tier?: string;
}

export class QuerySpendingReportDto {
  @ApiPropertyOptional({ example: 'vip', enum: ['standard', 'vip', 'vvip'] })
  @IsOptional()
  @IsString()
  tier?: string;

  @ApiPropertyOptional({ example: 500000 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  min_total_spent?: number;
}
