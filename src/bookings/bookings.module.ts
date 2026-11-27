import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { TypeOrmModule } from '@nestjs/typeorm';
import { BookingEntity } from '../entities/booking.entity';
import { BookingDetailEntity } from '../entities/booking-detail.entity';
import { BookingComboEntity } from '../entities/booking-combo.entity';
import { ComboEntity } from '../entities/combo.entity';
import { PaymentEntity } from '../entities/payment.entity';
import { PromotionEntity } from '../entities/promotion.entity';
import { BookingsController } from './bookings.controller';
import { BookingsService } from './bookings.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      BookingEntity,
      BookingDetailEntity,
      BookingComboEntity,
      ComboEntity,
      PaymentEntity,
      PromotionEntity,
    ]),
    JwtModule,
  ],
  controllers: [BookingsController],
  providers: [BookingsService],
  exports: [BookingsService, TypeOrmModule],
})
export class BookingsModule {}
