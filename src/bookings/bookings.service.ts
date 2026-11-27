import {
  BadRequestException,
  ConflictException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { BookingEntity } from '../entities/booking.entity';
import {
  AddBookingComboDto,
  AddBookingSeatDto,
  CreateBookingPaymentDto,
  CreateBookingProcedureDto,
  QueryBookingListProcedureDto,
  QueryShowtimeRevenueDto,
  UpdateBookingProcedureDto,
} from './dto/booking-procedure.dto';

@Injectable()
export class BookingsService {
  private readonly logger = new Logger(BookingsService.name);

  constructor(
    @InjectRepository(BookingEntity)
    private readonly bookingRepository: Repository<BookingEntity>,
  ) {}

  private handleDatabaseError(context: string, error: any): never {
    const rawMessage: string =
      error?.driverError?.message ||
      error?.message ||
      'Lỗi cơ sở dữ liệu không xác định';
    this.logger.error(`${context}: ${rawMessage}`);

    if (rawMessage.startsWith('Không tìm thấy')) {
      throw new NotFoundException(rawMessage);
    }
    if (
      rawMessage.startsWith('Lỗi nhập liệu:') ||
      rawMessage.startsWith('Lỗi số tiền:') ||
      rawMessage.startsWith('Lỗi điểm thưởng:') ||
      rawMessage.startsWith('Lỗi tham số:') ||
      rawMessage.startsWith('Lỗi khoảng ngày:') ||
      rawMessage.startsWith('Tham số lọc không hợp lệ:')
    ) {
      throw new BadRequestException(rawMessage);
    }
    throw new ConflictException(rawMessage);
  }

  // ===========================================================================
  // BTL2 MỤC 2.1 & 3.1: GỌI STORED PROCEDURES INSERT / UPDATE / DELETE
  // ===========================================================================

  async createBookingViaProcedure(
    dto: CreateBookingProcedureDto,
  ): Promise<{ message: string; bookingId: string | null }> {
    try {
      const rows = await this.bookingRepository.query(
        `CALL public.sp_insert_booking($1, $2, $3, $4, $5, $6, $7, $8, NULL)`,
        [
          dto.booking_code,
          dto.user_id,
          dto.showtime_id,
          dto.ticket_total,
          dto.combo_total ?? 0,
          dto.discount_amount ?? 0,
          dto.promotion_id || null,
          dto.points_used ?? 0,
        ],
      );
      return {
        message: `Tạo đơn đặt vé "${dto.booking_code}" thành công qua Stored Procedure`,
        bookingId: rows?.[0]?.p_new_booking_id ?? null,
      };
    } catch (error) {
      this.handleDatabaseError('sp_insert_booking', error);
    }
  }

  async updateBookingViaProcedure(
    id: string,
    dto: UpdateBookingProcedureDto,
  ): Promise<{ message: string }> {
    try {
      await this.bookingRepository.query(
        `CALL public.sp_update_booking($1, $2, $3, $4, $5, $6, $7)`,
        [
          id,
          dto.status || null,
          dto.promotion_id || null,
          dto.clear_promotion ?? false,
          dto.discount_amount ?? null,
          dto.points_used ?? null,
          dto.expired_at || null,
        ],
      );
      return {
        message: `Cập nhật đơn đặt vé ${id} thành công qua Stored Procedure`,
      };
    } catch (error) {
      this.handleDatabaseError('sp_update_booking', error);
    }
  }

  async deleteBookingViaProcedure(id: string): Promise<{ message: string }> {
    try {
      await this.bookingRepository.query(`CALL public.sp_delete_booking($1)`, [
        id,
      ]);
      return {
        message: `Xóa đơn đặt vé ${id} thành công qua Stored Procedure`,
      };
    } catch (error) {
      this.handleDatabaseError('sp_delete_booking', error);
    }
  }

  // ===========================================================================
  // BTL2 MỤC 2.3 & 3.2: GỌI STORED PROCEDURES TRUY VẤN DỮ LIỆU (REFCURSOR)
  // ===========================================================================

  async getBookingListViaProcedure(
    query: QueryBookingListProcedureDto,
  ): Promise<any[]> {
    try {
      return await this.bookingRepository.manager.transaction(
        async (manager) => {
          await manager.query(
            `CALL public.sp_get_user_booking_history($1, $2, $3, $4, $5, 'cur_booking_history')`,
            [
              query.user_id || null,
              query.status || null,
              query.search || null,
              query.sort_by || 'created_at',
              (query.sort_dir || 'DESC').toUpperCase(),
            ],
          );
          return await manager.query(`FETCH ALL FROM "cur_booking_history"`);
        },
      );
    } catch (error) {
      this.handleDatabaseError('sp_get_user_booking_history', error);
    }
  }

  async getShowtimeRevenueReportViaProcedure(
    query: QueryShowtimeRevenueDto,
  ): Promise<any[]> {
    try {
      return await this.bookingRepository.manager.transaction(
        async (manager) => {
          await manager.query(
            `CALL public.sp_report_showtime_revenue($1, $2, $3, $4, 'cur_showtime_revenue')`,
            [
              query.from_date || null,
              query.to_date || null,
              query.min_revenue ?? 0,
              query.movie_name || null,
            ],
          );
          return await manager.query(`FETCH ALL FROM "cur_showtime_revenue"`);
        },
      );
    } catch (error) {
      this.handleDatabaseError('sp_report_showtime_revenue', error);
    }
  }

  // ===========================================================================
  // BTL2 MỤC 2.4 & 3.3: GỌI FUNCTIONS TÍNH TOÁN (CURSOR & LOOP)
  // ===========================================================================

  async auditPromotionViaFunction(
    promotionId: string,
    minBookingAmount = 0,
  ): Promise<any> {
    try {
      const result = await this.bookingRepository.query(
        `SELECT * FROM public.fn_audit_promotion_discount_impact($1, $2)`,
        [promotionId, minBookingAmount],
      );
      return result[0] ?? null;
    } catch (error) {
      this.handleDatabaseError('fn_audit_promotion_discount_impact', error);
    }
  }

  async reconcileDailyPaymentsViaFunction(
    checkDate: string,
    tolerance = 0.01,
  ): Promise<any> {
    try {
      const result = await this.bookingRepository.query(
        `SELECT * FROM public.fn_reconcile_daily_booking_payments($1::DATE, $2)`,
        [checkDate, tolerance],
      );
      return result[0] ?? null;
    } catch (error) {
      this.handleDatabaseError('fn_reconcile_daily_booking_payments', error);
    }
  }

  // ===========================================================================
  // CHI TIẾT ĐƠN ĐẶT VÉ: GHẾ (BOOKING_DETAIL), COMBO (BOOKING_COMBO), PAYMENT
  // Phục vụ trực tiếp demo Trigger 2.2.1 (chống trùng ghế) & Trigger 2.2.2 (tính tiền)
  // ===========================================================================

  async getBookingDetails(bookingId: string): Promise<{
    booking: any;
    details: any[];
    combos: any[];
    payments: any[];
    roomSeats: any[];
  }> {
    const bookings = await this.bookingRepository.query(
      `SELECT b.*, u.name AS customer_name, u.phone AS customer_phone,
              m.name AS movie_title, st.start_time, st.base_price, st.room_id,
              r.name AS room_name, c.name AS cinema_name, p.code AS promotion_code
       FROM public.booking b
       JOIN public.users u ON b.user_id = u.id
       JOIN public.showtime st ON b.showtime_id = st.id
       JOIN public.movie m ON st.movie_id = m.id
       JOIN public.room r ON st.room_id = r.id
       JOIN public.cinema c ON r.cinema_id = c.id
       LEFT JOIN public.promotion p ON b.promotion_id = p.id
       WHERE b.id = $1 AND b.deleted_at IS NULL`,
      [bookingId],
    );

    if (!bookings.length) {
      throw new NotFoundException(`Không tìm thấy đơn đặt vé ${bookingId}`);
    }

    const booking = bookings[0];

    const [details, combos, payments, roomSeats] = await Promise.all([
      this.bookingRepository.query(
        `SELECT bd.id, bd.seat_id, bd.seat_label, bd.seat_type, bd.price, bd.status, bd.qr_code
         FROM public.booking_detail bd
         WHERE bd.booking_id = $1 AND bd.deleted_at IS NULL
         ORDER BY bd.seat_label ASC`,
        [bookingId],
      ),
      this.bookingRepository.query(
        `SELECT bc.id, bc.combo_id, cb.name AS combo_name, bc.quantity, bc.unit_price, bc.subtotal
         FROM public.booking_combo bc
         JOIN public.combo cb ON bc.combo_id = cb.id
         WHERE bc.booking_id = $1 AND bc.deleted_at IS NULL
         ORDER BY bc.created_at ASC`,
        [bookingId],
      ),
      this.bookingRepository.query(
        `SELECT id, method, amount, status, transaction_id, gateway_response, paid_at, created_at
         FROM public.payment
         WHERE booking_id = $1 AND deleted_at IS NULL
         ORDER BY created_at DESC`,
        [bookingId],
      ),
      this.bookingRepository.query(
        `SELECT s.id, (s.row || s.col) AS seat_label, st_type.name AS seat_type_name,
                st_type.surcharge,
                EXISTS (
                  SELECT 1
                  FROM public.booking_detail bd
                  JOIN public.booking b2 ON bd.booking_id = b2.id
                  WHERE b2.showtime_id = $2
                    AND bd.seat_id = s.id
                    AND bd.status <> 'cancelled'
                    AND bd.deleted_at IS NULL
                    AND b2.deleted_at IS NULL
                    AND (
                      b2.status = 'confirmed'
                      OR (b2.status = 'pending' AND (b2.expired_at IS NULL OR b2.expired_at > now()))
                    )
                ) AS is_occupied
         FROM public.seat s
         JOIN public.seat_type st_type ON s.seat_type_id = st_type.id
         WHERE s.room_id = $1 AND s.deleted_at IS NULL
         ORDER BY s.row ASC, s.col ASC`,
        [booking.room_id, booking.showtime_id],
      ),
    ]);

    return { booking, details, combos, payments, roomSeats };
  }

  async addSeatToBooking(
    bookingId: string,
    dto: AddBookingSeatDto,
  ): Promise<{ message: string }> {
    try {
      const seatRows = await this.bookingRepository.query(
        `SELECT s.id, (s.row || s.col) AS seat_label, st_type.name AS seat_type_name,
                st_type.surcharge, sh.base_price, b.booking_code
         FROM public.booking b
         JOIN public.showtime sh ON b.showtime_id = sh.id
         JOIN public.seat s ON s.id = $2
         JOIN public.seat_type st_type ON s.seat_type_id = st_type.id
         WHERE b.id = $1 AND b.deleted_at IS NULL AND s.deleted_at IS NULL`,
        [bookingId, dto.seat_id],
      );

      if (!seatRows.length) {
        throw new NotFoundException(
          'Không tìm thấy đơn đặt vé hoặc ghế ngồi được chọn!',
        );
      }

      const info = seatRows[0];
      const computedPrice =
        Number(info.base_price || 0) + Number(info.surcharge || 0);
      const qrCode = `QR-${info.booking_code}-${info.seat_label}`;

      await this.bookingRepository.query(
        `INSERT INTO public.booking_detail (booking_id, seat_id, seat_label, seat_type, price, status, qr_code)
         VALUES ($1, $2, $3, $4, $5, 'active', $6)`,
        [
          bookingId,
          dto.seat_id,
          info.seat_label,
          info.seat_type_name,
          computedPrice,
          qrCode,
        ],
      );

      return {
        message: `Đã thêm ghế ${info.seat_label} (${computedPrice.toLocaleString('vi-VN')} đ) và tự động tính lại tổng tiền đơn`,
      };
    } catch (error) {
      if (error instanceof NotFoundException) throw error;
      this.handleDatabaseError('addSeatToBooking', error);
    }
  }

  async removeSeatFromBooking(
    bookingId: string,
    detailId: string,
  ): Promise<{ message: string }> {
    try {
      const res = await this.bookingRepository.query(
        `DELETE FROM public.booking_detail WHERE id = $1 AND booking_id = $2 RETURNING seat_label`,
        [detailId, bookingId],
      );
      if (!res.length) {
        throw new NotFoundException('Không tìm thấy vé ghế cần xóa!');
      }
      return {
        message: `Đã xóa ghế ${res[0].seat_label} khỏi đơn và trigger đã tự tính lại tổng tiền`,
      };
    } catch (error) {
      if (error instanceof NotFoundException) throw error;
      this.handleDatabaseError('removeSeatFromBooking', error);
    }
  }

  async addComboToBooking(
    bookingId: string,
    dto: AddBookingComboDto,
  ): Promise<{ message: string }> {
    try {
      const comboRows = await this.bookingRepository.query(
        `SELECT id, name, price, is_available FROM public.combo WHERE id = $1 AND deleted_at IS NULL`,
        [dto.combo_id],
      );
      if (!comboRows.length) {
        throw new NotFoundException('Không tìm thấy combo bắp nước!');
      }
      const combo = comboRows[0];
      if (!combo.is_available) {
        throw new ConflictException(`Combo "${combo.name}" hiện đã tạm ngưng!`);
      }

      const unitPrice = Number(combo.price);
      await this.bookingRepository.query(
        `INSERT INTO public.booking_combo (booking_id, combo_id, quantity, unit_price, subtotal)
         VALUES ($1, $2, $3, $4, $5)
         ON CONFLICT (booking_id, combo_id) DO UPDATE
         SET quantity = public.booking_combo.quantity + EXCLUDED.quantity,
             unit_price = EXCLUDED.unit_price,
             subtotal = (public.booking_combo.quantity + EXCLUDED.quantity) * EXCLUDED.unit_price,
             updated_at = now()`,
        [
          bookingId,
          dto.combo_id,
          dto.quantity,
          unitPrice,
          dto.quantity * unitPrice,
        ],
      );

      return {
        message: `Đã thêm ${dto.quantity}x "${combo.name}" vào đơn; Trigger 2.2.2 đã tự động cập nhật combo_total và final_amount`,
      };
    } catch (error) {
      if (
        error instanceof NotFoundException ||
        error instanceof ConflictException
      ) {
        throw error;
      }
      this.handleDatabaseError('addComboToBooking', error);
    }
  }

  async removeComboFromBooking(
    bookingId: string,
    bookingComboId: string,
  ): Promise<{ message: string }> {
    try {
      const res = await this.bookingRepository.query(
        `DELETE FROM public.booking_combo WHERE id = $1 AND booking_id = $2 RETURNING id`,
        [bookingComboId, bookingId],
      );
      if (!res.length) {
        throw new NotFoundException('Không tìm thấy combo trong đơn!');
      }
      return {
        message: 'Đã xóa combo khỏi đơn và trigger đã tự tính lại tổng tiền',
      };
    } catch (error) {
      if (error instanceof NotFoundException) throw error;
      this.handleDatabaseError('removeComboFromBooking', error);
    }
  }

  async createPaymentForBooking(
    bookingId: string,
    dto: CreateBookingPaymentDto,
  ): Promise<{ message: string }> {
    try {
      return await this.bookingRepository.manager.transaction(
        async (manager) => {
          const rows = await manager.query(
            `SELECT id, booking_code, status, final_amount FROM public.booking WHERE id = $1 AND deleted_at IS NULL`,
            [bookingId],
          );
          if (!rows.length) {
            throw new NotFoundException(`Không tìm thấy đơn đặt vé ${bookingId}`);
          }
          const booking = rows[0];
          if (booking.status !== 'pending') {
            throw new ConflictException(
              `Đơn "${booking.booking_code}" đang ở trạng thái "${booking.status}", chỉ thanh toán được đơn "pending"!`,
            );
          }

          const payStatus = dto.status || 'success';
          const txnId =
            dto.transaction_id ||
            `${dto.method.toUpperCase()}_${Date.now()}`;
          const paidAt = payStatus === 'success' ? new Date() : null;

          await manager.query(
            `INSERT INTO public.payment (booking_id, method, amount, status, transaction_id, gateway_response, paid_at)
             VALUES ($1, $2, $3, $4, $5, $6, $7)`,
            [
              bookingId,
              dto.method,
              dto.amount,
              payStatus,
              txnId,
              JSON.stringify({ source: 'BTL2_WEB_UI', status: payStatus }),
              paidAt,
            ],
          );

          if (payStatus === 'success') {
            await manager.query(
              `CALL public.sp_update_booking($1, 'confirmed', NULL, false, NULL, NULL, NULL)`,
              [bookingId],
            );
          }

          return {
            message:
              payStatus === 'success'
                ? `Thanh toán thành công qua ${dto.method}; đơn "${booking.booking_code}" đã chuyển sang trạng thái confirmed!`
                : `Đã ghi nhận giao dịch thanh toán (${payStatus}) qua ${dto.method}`,
          };
        },
      );
    } catch (error) {
      if (
        error instanceof NotFoundException ||
        error instanceof ConflictException
      ) {
        throw error;
      }
      this.handleDatabaseError('createPaymentForBooking', error);
    }
  }

  // ===========================================================================
  // DỮ LIỆU DANH MỤC PHỤC VỤ COMBO-BOX GIAO DIỆN MỤC 3 (USERS, SHOWTIMES, PROMOS)
  // ===========================================================================

  async getFormLookups(): Promise<{
    users: any[];
    showtimes: any[];
    promotions: any[];
    combos: any[];
  }> {
    const [users, showtimes, promotions, combos] = await Promise.all([
      this.bookingRepository.query(
        `SELECT u.id, u.code, u.name, u.email, u.phone, COALESCE(m.cgv_points, 0) AS cgv_points
         FROM public.users u
         LEFT JOIN public.membership m ON m.user_id = u.id AND m.deleted_at IS NULL
         WHERE u.deleted_at IS NULL AND u.is_active = true
         ORDER BY u.name ASC`,
      ),
      this.bookingRepository.query(
        `SELECT st.id, m.name AS movie_title, r.name AS room_name, c.name AS cinema_name,
                st.start_time, st.base_price, st.status
         FROM public.showtime st
         JOIN public.movie m ON st.movie_id = m.id
         JOIN public.room r ON st.room_id = r.id
         JOIN public.cinema c ON r.cinema_id = c.id
         WHERE st.deleted_at IS NULL AND st.is_active = true
         ORDER BY st.start_time DESC`,
      ),
      this.bookingRepository.query(
        `SELECT id, code, name, type, discount_value, max_discount_amount,
                min_order_amount, start_date, end_date, is_active
         FROM public.promotion
         WHERE deleted_at IS NULL
         ORDER BY is_active DESC, start_date DESC`,
      ),
      this.bookingRepository.query(
        `SELECT id, name, category, size, price, is_available
         FROM public.combo
         WHERE deleted_at IS NULL
         ORDER BY display_order ASC, name ASC`,
      ),
    ]);

    return { users, showtimes, promotions, combos };
  }
}
