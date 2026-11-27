import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
  Query,
  Res,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { Response } from 'express';
import { existsSync } from 'fs';
import { join } from 'path';
import { Public } from '../auth/decorators/public.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { BookingsService } from './bookings.service';
import {
  AddBookingComboDto,
  AddBookingSeatDto,
  AuditPromotionQueryDto,
  CreateBookingPaymentDto,
  CreateBookingProcedureDto,
  QueryBookingListProcedureDto,
  QueryShowtimeRevenueDto,
  ReconcileDailyPaymentsQueryDto,
  UpdateBookingProcedureDto,
} from './dto/booking-procedure.dto';

@ApiTags('Bookings Management (BTL2 - Member 5)')
@ApiBearerAuth('Authorization')
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('bookings')
export class BookingsController {
  constructor(private readonly bookingsService: BookingsService) {}

  // ===========================================================================
  // BTL2 MỤC 3: GIAO DIỆN WEB ỨNG DỤNG CHO THÀNH VIÊN 5
  // Truy cập trực tiếp tại: http://localhost:3001/bookings/app
  // ===========================================================================

  @Public()
  @Get('app')
  @ApiOperation({
    summary: '[BTL2 Mục 3] Giao diện Web Quản lý Booking, Combo & Payment (Thành viên 5)',
  })
  serveBookingWebApp(@Res() res: Response) {
    const distPath = join(__dirname, 'ui', 'booking-app.html');
    const srcPath = join(
      process.cwd(),
      'src',
      'bookings',
      'ui',
      'booking-app.html',
    );
    const htmlPath = existsSync(distPath) ? distPath : srcPath;
    return res.sendFile(htmlPath);
  }

  // ===========================================================================
  // BTL2 MỤC 3.1: INSERT / UPDATE / DELETE QUA STORED PROCEDURES (MỤC 2.1)
  // ===========================================================================

  @Public()
  @Post('procedure/create')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary:
      '[BTL2 Mục 2.1 & 3.1] Tạo đơn đặt vé qua Stored Procedure sp_insert_booking',
    description:
      'Kiểm tra mã đơn, user, suất chiếu, số dư điểm, điều kiện khuyến mãi và tự tính final_amount.',
  })
  async createViaProcedure(@Body() dto: CreateBookingProcedureDto) {
    return this.bookingsService.createBookingViaProcedure(dto);
  }

  @Public()
  @Patch('procedure/:id')
  @ApiOperation({
    summary:
      '[BTL2 Mục 2.1 & 3.1] Cập nhật đơn đặt vé qua Stored Procedure sp_update_booking',
    description:
      'Cập nhật trạng thái hoặc thông tin khuyến mãi/điểm sử dụng (khi pending) với kiểm tra logic.',
  })
  async updateViaProcedure(
    @Param('id') id: string,
    @Body() dto: UpdateBookingProcedureDto,
  ) {
    return this.bookingsService.updateBookingViaProcedure(id, dto);
  }

  @Public()
  @Delete('procedure/:id')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      '[BTL2 Mục 2.1 & 3.1] Xóa đơn đặt vé qua Stored Procedure sp_delete_booking',
    description:
      'Chỉ cho phép xóa đơn pending/cancelled/expired chưa có payment thành công; chặn xóa đơn confirmed/refunded.',
  })
  async deleteViaProcedure(@Param('id') id: string) {
    return this.bookingsService.deleteBookingViaProcedure(id);
  }

  // ===========================================================================
  // BTL2 MỤC 3.2: TRUY VẤN DANH SÁCH QUA STORED PROCEDURES (MỤC 2.3)
  // ===========================================================================

  @Public()
  @Get('procedure/list')
  @ApiOperation({
    summary:
      '[BTL2 Mục 2.3 & 3.2] Lấy danh sách đơn đặt vé (REFCURSOR, lọc, tìm kiếm, sắp xếp)',
  })
  async getBookingListViaProcedure(
    @Query() query: QueryBookingListProcedureDto,
  ) {
    return this.bookingsService.getBookingListViaProcedure(query);
  }

  @Public()
  @Get('procedure/showtime-revenue')
  @ApiOperation({
    summary:
      '[BTL2 Mục 2.3 & 3.3] Báo cáo doanh thu theo suất chiếu (Aggregate + GROUP BY + HAVING + ORDER BY)',
  })
  async getShowtimeRevenueViaProcedure(
    @Query() query: QueryShowtimeRevenueDto,
  ) {
    return this.bookingsService.getShowtimeRevenueReportViaProcedure(query);
  }

  @Public()
  @Get('procedure/lookups')
  @ApiOperation({
    summary:
      '[BTL2 Mục 3] Dữ liệu danh mục (users, showtimes, promotions, combos) cho dropdown giao diện',
  })
  async getFormLookups() {
    return this.bookingsService.getFormLookups();
  }

  // ===========================================================================
  // CHI TIẾT ĐƠN VÉ (GHẾ, COMBO, THANH TOÁN) - DEMO LIVE TRIGGERS MỤC 2.2
  // ===========================================================================

  @Public()
  @Get('procedure/:id/details')
  @ApiOperation({
    summary:
      '[BTL2 Mục 3] Lấy chi tiết ghế, combo, giao dịch thanh toán và sơ đồ ghế của đơn',
  })
  async getBookingDetails(@Param('id') id: string) {
    return this.bookingsService.getBookingDetails(id);
  }

  @Public()
  @Post('procedure/:id/seats')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary:
      '[BTL2 Mục 2.2 & 3] Thêm ghế vào đơn (Kích hoạt Trigger 2.2.1 chống trùng ghế & Trigger 2.2.2 tính tiền)',
  })
  async addSeatToBooking(
    @Param('id') id: string,
    @Body() dto: AddBookingSeatDto,
  ) {
    return this.bookingsService.addSeatToBooking(id, dto);
  }

  @Public()
  @Delete('procedure/:id/seats/:detailId')
  @ApiOperation({
    summary:
      '[BTL2 Mục 2.2 & 3] Xóa ghế khỏi đơn (Kích hoạt Trigger 2.2.2 cập nhật lại tổng tiền)',
  })
  async removeSeatFromBooking(
    @Param('id') id: string,
    @Param('detailId') detailId: string,
  ) {
    return this.bookingsService.removeSeatFromBooking(id, detailId);
  }

  @Public()
  @Post('procedure/:id/combos')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary:
      '[BTL2 Mục 2.2 & 3] Thêm combo bắp nước vào đơn (Kích hoạt Trigger 2.2.2 tính combo_total & final_amount)',
  })
  async addComboToBooking(
    @Param('id') id: string,
    @Body() dto: AddBookingComboDto,
  ) {
    return this.bookingsService.addComboToBooking(id, dto);
  }

  @Public()
  @Delete('procedure/:id/combos/:bookingComboId')
  @ApiOperation({
    summary:
      '[BTL2 Mục 2.2 & 3] Xóa combo khỏi đơn (Kích hoạt Trigger 2.2.2 tính lại tổng tiền)',
  })
  async removeComboFromBooking(
    @Param('id') id: string,
    @Param('bookingComboId') bookingComboId: string,
  ) {
    return this.bookingsService.removeComboFromBooking(id, bookingComboId);
  }

  @Public()
  @Post('procedure/:id/payments')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary:
      '[BTL2 Mục 3] Thanh toán đơn hàng & xác nhận trạng thái confirmed qua sp_update_booking',
  })
  async createPaymentForBooking(
    @Param('id') id: string,
    @Body() dto: CreateBookingPaymentDto,
  ) {
    return this.bookingsService.createPaymentForBooking(id, dto);
  }

  // ===========================================================================
  // BTL2 MỤC 3.3: GỌI FUNCTIONS TÍNH TOÁN (MỤC 2.4 - CURSOR + LOOP + IF)
  // ===========================================================================

  @Public()
  @Get('function/audit-promotion/:promotionId')
  @ApiOperation({
    summary:
      '[BTL2 Mục 2.4 & 3.3] Kiểm toán hiệu quả chiết khấu khuyến mãi qua fn_audit_promotion_discount_impact',
  })
  async auditPromotionViaFunction(
    @Param('promotionId') promotionId: string,
    @Query() query: AuditPromotionQueryDto,
  ) {
    return this.bookingsService.auditPromotionViaFunction(
      promotionId,
      query.min_booking_amount ?? 0,
    );
  }

  @Public()
  @Get('function/reconcile-daily')
  @ApiOperation({
    summary:
      '[BTL2 Mục 2.4 & 3.3] Đối soát tài chính booking vs payment theo ngày qua fn_reconcile_daily_booking_payments',
  })
  async reconcileDailyPaymentsViaFunction(
    @Query() query: ReconcileDailyPaymentsQueryDto,
  ) {
    return this.bookingsService.reconcileDailyPaymentsViaFunction(
      query.check_date,
      query.tolerance ?? 0.01,
    );
  }
}
