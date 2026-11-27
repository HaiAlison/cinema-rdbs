import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import {
  IsBoolean,
  IsDateString,
  IsIn,
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  Min,
} from 'class-validator';

const emptyToUndefined = ({ value }: { value: unknown }) =>
  value === '' || value === null ? undefined : value;

export class CreateBookingProcedureDto {
  @ApiProperty({ example: 'CGV2026000099' })
  @IsString()
  @IsNotEmpty()
  booking_code: string;

  @ApiProperty({ example: 'bb656c14-68e8-4803-a80e-b2ac4e8804a9' })
  @IsUUID()
  user_id: string;

  @ApiProperty({ example: '90359f2d-ff72-4a20-9118-c2601fa82aad' })
  @IsUUID()
  showtime_id: string;

  @ApiProperty({ example: 180000 })
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  ticket_total: number;

  @ApiPropertyOptional({ example: 89000, default: 0 })
  @Transform(emptyToUndefined)
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  combo_total?: number;

  @ApiPropertyOptional({ example: 0, default: 0 })
  @Transform(emptyToUndefined)
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  discount_amount?: number;

  @ApiPropertyOptional({ example: 'b5e7c943-91b6-4f4a-9846-a92fef15a242' })
  @Transform(emptyToUndefined)
  @IsOptional()
  @IsUUID()
  promotion_id?: string;

  @ApiPropertyOptional({ example: 0, default: 0 })
  @Transform(emptyToUndefined)
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  points_used?: number;
}

export class UpdateBookingProcedureDto {
  @ApiPropertyOptional({
    example: 'confirmed',
    enum: ['pending', 'confirmed', 'cancelled', 'expired', 'refunded'],
  })
  @Transform(emptyToUndefined)
  @IsOptional()
  @IsIn(['pending', 'confirmed', 'cancelled', 'expired', 'refunded'])
  status?: string;

  @ApiPropertyOptional({ example: 'a3d45699-819d-43ce-945f-3b5c9a06d076' })
  @Transform(emptyToUndefined)
  @IsOptional()
  @IsUUID()
  promotion_id?: string;

  @ApiPropertyOptional({ example: false, default: false })
  @IsOptional()
  @Transform(({ value }) => value === true || value === 'true')
  @IsBoolean()
  clear_promotion?: boolean;

  @ApiPropertyOptional({ example: 50000 })
  @Transform(emptyToUndefined)
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  discount_amount?: number;

  @ApiPropertyOptional({ example: 0 })
  @Transform(emptyToUndefined)
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  points_used?: number;

  @ApiPropertyOptional({ example: '2026-12-31T23:59:59+07:00' })
  @Transform(emptyToUndefined)
  @IsOptional()
  @IsDateString()
  expired_at?: string;
}

export class QueryBookingListProcedureDto {
  @ApiPropertyOptional({ example: 'bb656c14-68e8-4803-a80e-b2ac4e8804a9' })
  @Transform(emptyToUndefined)
  @IsOptional()
  @IsUUID()
  user_id?: string;

  @ApiPropertyOptional({
    example: 'confirmed',
    enum: ['pending', 'confirmed', 'cancelled', 'expired', 'refunded'],
  })
  @Transform(emptyToUndefined)
  @IsOptional()
  @IsString()
  status?: string;

  @ApiPropertyOptional({ example: 'CGV2026' })
  @Transform(emptyToUndefined)
  @IsOptional()
  @IsString()
  search?: string;

  @ApiPropertyOptional({
    example: 'created_at',
    enum: ['created_at', 'final_amount', 'booking_code', 'show_time'],
  })
  @Transform(emptyToUndefined)
  @IsOptional()
  @IsIn(['created_at', 'final_amount', 'booking_code', 'show_time'])
  sort_by?: string;

  @ApiPropertyOptional({ example: 'DESC', enum: ['ASC', 'DESC'] })
  @Transform(emptyToUndefined)
  @IsOptional()
  @IsIn(['ASC', 'DESC', 'asc', 'desc'])
  sort_dir?: string;
}

export class QueryShowtimeRevenueDto {
  @ApiPropertyOptional({ example: '2026-01-01T00:00:00+07:00' })
  @Transform(emptyToUndefined)
  @IsOptional()
  @IsDateString()
  from_date?: string;

  @ApiPropertyOptional({ example: '2026-12-31T23:59:59+07:00' })
  @Transform(emptyToUndefined)
  @IsOptional()
  @IsDateString()
  to_date?: string;

  @ApiPropertyOptional({ example: 100000 })
  @Transform(emptyToUndefined)
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  min_revenue?: number;

  @ApiPropertyOptional({ example: 'Mai' })
  @Transform(emptyToUndefined)
  @IsOptional()
  @IsString()
  movie_name?: string;
}

export class AuditPromotionQueryDto {
  @ApiPropertyOptional({ example: 0, default: 0 })
  @Transform(emptyToUndefined)
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  min_booking_amount?: number;
}

export class ReconcileDailyPaymentsQueryDto {
  @ApiProperty({ example: '2026-11-02' })
  @IsDateString()
  check_date: string;

  @ApiPropertyOptional({ example: 0.01, default: 0.01 })
  @Transform(emptyToUndefined)
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  tolerance?: number;
}

export class AddBookingSeatDto {
  @ApiProperty({ example: 'ef1a3285-bf57-406a-a188-4d86e81afe5a' })
  @IsUUID()
  seat_id: string;
}

export class AddBookingComboDto {
  @ApiProperty({ example: 'cb4fb778-334e-4afe-bdf5-981b8a7f69da' })
  @IsUUID()
  combo_id: string;

  @ApiProperty({ example: 1, default: 1 })
  @Type(() => Number)
  @IsInt()
  @Min(1)
  quantity: number;
}

export class CreateBookingPaymentDto {
  @ApiProperty({
    example: 'momo',
    enum: [
      'credit_card',
      'momo',
      'zalopay',
      'vnpay',
      'banking',
      'cgv_giftcard',
      'cgv_point',
      'cash',
      'shopeepay',
    ],
  })
  @IsIn([
    'credit_card',
    'momo',
    'zalopay',
    'vnpay',
    'banking',
    'cgv_giftcard',
    'cgv_point',
    'cash',
    'shopeepay',
  ])
  method: string;

  @ApiProperty({ example: 165000 })
  @Type(() => Number)
  @IsNumber()
  @Min(1)
  amount: number;

  @ApiPropertyOptional({
    example: 'success',
    enum: ['pending', 'success', 'failed'],
  })
  @Transform(emptyToUndefined)
  @IsOptional()
  @IsIn(['pending', 'success', 'failed'])
  status?: string;

  @ApiPropertyOptional({ example: 'MOMO_DEMO_001' })
  @Transform(emptyToUndefined)
  @IsOptional()
  @IsString()
  transaction_id?: string;
}
