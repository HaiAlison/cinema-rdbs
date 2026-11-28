jest.mock('../entities/booking.entity', () => ({
  BookingEntity: class BookingEntity {},
}));

import { Test, TestingModule } from '@nestjs/testing';
import { BookingsController } from './bookings.controller';
import { BookingsService } from './bookings.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';

describe('BookingsController', () => {
  let controller: BookingsController;
  let service: BookingsService;

  const mockBookingsService = {
    createBookingViaProcedure: jest.fn().mockResolvedValue({
      message: 'Tạo đơn đặt vé thành công',
      bookingId: 'b1111111-1111-4111-a111-111111111111',
    }),
    updateBookingViaProcedure: jest.fn().mockResolvedValue({
      message: 'Cập nhật đơn đặt vé thành công',
    }),
    deleteBookingViaProcedure: jest.fn().mockResolvedValue({
      message: 'Xóa đơn đặt vé thành công',
    }),
    getBookingListViaProcedure: jest.fn().mockResolvedValue([
      {
        id: '8993f8f5-9255-471f-b9c5-d0daaf04fdf5',
        booking_code: 'CGV2026000001',
        status: 'confirmed',
        final_amount: '215200.00',
      },
    ]),
    getShowtimeRevenueReportViaProcedure: jest.fn().mockResolvedValue([]),
    auditPromotionViaFunction: jest.fn().mockResolvedValue({
      promotion_code: 'SUMMER2024',
      confirmed_bookings_count: 1,
    }),
    reconcileDailyPaymentsViaFunction: jest.fn().mockResolvedValue({
      reconcile_date: '2026-11-02',
      unbalanced_orders: 0,
    }),
    getFormLookups: jest.fn().mockResolvedValue({
      users: [],
      showtimes: [],
      promotions: [],
      combos: [],
    }),
    getBookingDetails: jest.fn(),
    addSeatToBooking: jest.fn(),
    removeSeatFromBooking: jest.fn(),
    addComboToBooking: jest.fn(),
    removeComboFromBooking: jest.fn(),
    createPaymentForBooking: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [BookingsController],
      providers: [
        {
          provide: BookingsService,
          useValue: mockBookingsService,
        },
      ],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue({ canActivate: () => true })
      .overrideGuard(RolesGuard)
      .useValue({ canActivate: () => true })
      .compile();

    controller = module.get<BookingsController>(BookingsController);
    service = module.get<BookingsService>(BookingsService);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  it('should call createBookingViaProcedure', async () => {
    const dto = {
      booking_code: 'CGV2026000099',
      user_id: 'bb656c14-68e8-4803-a80e-b2ac4e8804a9',
      showtime_id: '90359f2d-ff72-4a20-9118-c2601fa82aad',
      ticket_total: 180000,
    };
    const res = await controller.createViaProcedure(dto);
    expect(res.bookingId).toBe('b1111111-1111-4111-a111-111111111111');
    expect(service.createBookingViaProcedure).toHaveBeenCalledWith(dto);
  });

  it('should call getBookingListViaProcedure', async () => {
    const query = { status: 'confirmed', search: 'CGV2026' };
    const res = await controller.getBookingListViaProcedure(query);
    expect(res).toHaveLength(1);
    expect(service.getBookingListViaProcedure).toHaveBeenCalledWith(query);
  });

  it('should call reconcileDailyPaymentsViaFunction', async () => {
    const query = { check_date: '2026-11-02', tolerance: 0.01 };
    const res = await controller.reconcileDailyPaymentsViaFunction(query);
    expect(res.unbalanced_orders).toBe(0);
    expect(service.reconcileDailyPaymentsViaFunction).toHaveBeenCalledWith(
      '2026-11-02',
      0.01,
    );
  });
});
