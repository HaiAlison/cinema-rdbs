import {
  createMockUser,
  createMockCinema,
  createMockFormat,
  createMockSeatType,
  createMockMovie,
  createMockCombo,
  createMockPromotion,
  createMockMembership,
  createMockRoom,
  createMockSeat,
  createMockShowtime,
  createMockPointTransaction,
  createMockBooking,
  createMockBookingDetail,
  createMockBookingCombo,
  createMockPayment,
  createFullMockDataset,
  createMockCinemas,
  createMockFormats,
  createMockSeatTypes,
  createMockMovies,
  createMockCombos,
  createMockMemberships,
  resetCounters,
  EUserRole,
  ERoomType,
  ESeatTypeCode,
  EComboCategory,
  EComboSize,
  EPromotionType,
  EPromotionScope,
  EMembershipTier,
  EShowtimeStatus,
  ESubtitleType,
  EBookingStatus,
  ETicketStatus,
  EPaymentMethod,
  EPaymentStatus,
  EPointTransactionType,
} from './mock-data.factory';

beforeEach(() => {
  resetCounters();
});

// ──────────────────────────────────────────────
// Helper: kiểm tra base fields (UUID, timestamps)
// ──────────────────────────────────────────────
function expectBaseFields(entity: any) {
  expect(entity.id).toBeDefined();
  expect(typeof entity.id).toBe('string');
  expect(entity.id).toMatch(
    /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i,
  );
  expect(entity.created_at).toBeInstanceOf(Date);
  expect(entity.updated_at).toBeInstanceOf(Date);
  expect(entity.deleted_at).toBeNull();
}

// ══════════════════════════════════════════════
// 1. INDEPENDENT ENTITIES (Không có FK)
// ══════════════════════════════════════════════

describe('UserEntity Mock', () => {
  it('tạo user với giá trị mặc định', () => {
    const user = createMockUser();

    expectBaseFields(user);
    expect(user.name).toBe('Nguyễn Văn A');
    expect(user.code).toMatch(/^CGV\d{6}$/);
    expect(user.email).toContain('@example.com');
    expect(user.phone).toBe('0901234567');
    expect(user.province).toBe('Hà Nội');
    expect(user.password).toBeTruthy();
    expect(user.salt).toBeTruthy();
    expect(user.is_active).toBe(true);
    expect(user.role).toBe(EUserRole.CUSTOMER);
  });

  it('override từng trường', () => {
    const user = createMockUser({
      name: 'Trần Văn B',
      role: EUserRole.ADMIN,
      dob: new Date('1995-03-15'),
      sex: true,
    });

    expect(user.name).toBe('Trần Văn B');
    expect(user.role).toBe(EUserRole.ADMIN);
    expect(user.dob).toEqual(new Date('1995-03-15'));
    expect(user.sex).toBe(true);
  });

  it('tạo nhiều user có code tự tăng', () => {
    const u1 = createMockUser();
    const u2 = createMockUser();
    const u3 = createMockUser();

    expect(u1.code).toBe('CGV000001');
    expect(u2.code).toBe('CGV000002');
    expect(u3.code).toBe('CGV000003');
    // Email unique theo code
    expect(u1.email).not.toBe(u2.email);
  });
});

describe('CinemaEntity Mock', () => {
  it('tạo cinema với giá trị mặc định', () => {
    const cinema = createMockCinema();

    expectBaseFields(cinema);
    expect(cinema.name).toContain('CGV');
    expect(cinema.phone).toBeTruthy();
    expect(cinema.address).toBeTruthy();
    expect(cinema.city).toBe('Hà Nội');
    expect(cinema.is_active).toBe(true);
  });

  it('override từng trường và optional fields', () => {
    const cinema = createMockCinema({
      name: 'CGV Aeon Mall',
      city: 'TP.HCM',
      lat: 10.8231,
      long: 106.6297,
      hotline: '1800 1234',
      image_urls: ['https://example.com/img1.jpg'],
    });

    expect(cinema.name).toBe('CGV Aeon Mall');
    expect(cinema.lat).toBe(10.8231);
    expect(cinema.long).toBe(106.6297);
    expect(cinema.hotline).toBe('1800 1234');
    expect(cinema.image_urls).toHaveLength(1);
  });

  it('bulk: tạo nhiều cinemas', () => {
    const cinemas = createMockCinemas(3);

    expect(cinemas).toHaveLength(3);
    cinemas.forEach((c) => expectBaseFields(c));
    // IDs unique
    const ids = new Set(cinemas.map((c) => c.id));
    expect(ids.size).toBe(3);
  });
});

describe('FormatEntity Mock', () => {
  it('tạo format mặc định (2D)', () => {
    const format = createMockFormat();

    expectBaseFields(format);
    expect(format.name).toBe('2D');
    expect(format.price).toBe(0);
    expect(format.is_active).toBe(true);
    expect(format.description).toBeTruthy();
  });

  it('bulk: tạo tất cả formats', () => {
    const formats = createMockFormats();

    expect(formats).toHaveLength(5);
    expect(formats.map((f) => f.name)).toEqual([
      '2D',
      '3D',
      'IMAX',
      '4DX',
      'ScreenX',
    ]);
    expect(formats[0].price).toBe(0);
    expect(formats[1].price).toBe(30000);
    expect(formats[2].price).toBe(50000);
    expect(formats[3].price).toBe(70000);
    expect(formats[4].price).toBe(40000);
  });
});

describe('SeatTypeEntity Mock', () => {
  it('tạo seat type mặc định (Standard)', () => {
    const st = createMockSeatType();

    expectBaseFields(st);
    expect(st.name).toBe('Ghế thường');
    expect(st.code).toBe(ESeatTypeCode.STANDARD);
    expect(st.surcharge).toBe(0);
    expect(st.color).toBeTruthy();
    expect(st.is_active).toBe(true);
  });

  it('bulk: tạo tất cả seat types', () => {
    const types = createMockSeatTypes();

    expect(types).toHaveLength(4);
    expect(types.map((t) => t.code)).toEqual([
      ESeatTypeCode.STANDARD,
      ESeatTypeCode.VIP,
      ESeatTypeCode.SWEETBOX,
      ESeatTypeCode.DELUXE,
    ]);
    // Surcharge tăng dần
    for (let i = 1; i < types.length; i++) {
      expect(types[i].surcharge).toBeGreaterThan(types[i - 1].surcharge);
    }
  });
});

describe('MovieEntity Mock', () => {
  it('tạo movie với giá trị mặc định', () => {
    const movie = createMockMovie();

    expectBaseFields(movie);
    expect(movie.name).toBe('Avengers: Endgame');
    expect(movie.description).toBeTruthy();
    expect(movie.duration).toBe(181);
    expect(movie.rated).toBe('C13');
    expect(movie.is_active).toBe(true);
    expect(movie.release_date).toBeInstanceOf(Date);
    expect(movie.genres).toContain('Hành động');
    expect(movie.directors).toHaveLength(2);
    expect(movie.actors.length).toBeGreaterThan(0);
    expect(movie.poster_url).toBeTruthy();
    expect(movie.trailer_url).toBeTruthy();
  });

  it('bulk: tạo nhiều movies', () => {
    const movies = createMockMovies(5);

    expect(movies).toHaveLength(5);
    expect(movies[0].name).toBe('Avengers: Endgame');
    expect(movies[2].name).toContain('Doraemon');
    // 3 phim đầu active, 2 phim sau inactive
    expect(movies[0].is_active).toBe(true);
    expect(movies[3].is_active).toBe(false);
  });
});

describe('ComboEntity Mock', () => {
  it('tạo combo mặc định', () => {
    const combo = createMockCombo();

    expectBaseFields(combo);
    expect(combo.name).toBe('Combo Solo');
    expect(combo.category).toBe(EComboCategory.COMBO);
    expect(combo.size).toBe(EComboSize.LARGE);
    expect(combo.price).toBe(89000);
    expect(combo.is_available).toBe(true);
    expect(combo.is_e_combo).toBe(false);
  });

  it('bulk: tạo tất cả combos', () => {
    const combos = createMockCombos();

    expect(combos).toHaveLength(4);
    const prices = combos.map((c) => c.price);
    expect(prices).toEqual([89000, 109000, 199000, 159000]);
    combos.forEach((c) => expect(c.category).toBe(EComboCategory.COMBO));
  });
});

describe('PromotionEntity Mock', () => {
  it('tạo promotion mặc định (percentage)', () => {
    const promo = createMockPromotion();

    expectBaseFields(promo);
    expect(promo.name).toContain('Hè 2024');
    expect(promo.code).toBe('SUMMER2024');
    expect(promo.type).toBe(EPromotionType.PERCENTAGE);
    expect(promo.scope).toBe(EPromotionScope.ALL);
    expect(promo.discount_value).toBe(20);
    expect(promo.max_discount_amount).toBe(50000);
    expect(promo.min_order_amount).toBe(100000);
    expect(promo.start_date).toBeInstanceOf(Date);
    expect(promo.end_date).toBeInstanceOf(Date);
    expect(promo.end_date.getTime()).toBeGreaterThan(
      promo.start_date.getTime(),
    );
    expect(promo.usage_limit).toBe(1000);
    expect(promo.used_count).toBeLessThanOrEqual(promo.usage_limit);
    expect(promo.per_user_limit).toBe(1);
    expect(promo.is_active).toBe(true);
  });

  it('tạo promotion fixed_amount', () => {
    const promo = createMockPromotion({
      code: 'FIXED50K',
      type: EPromotionType.FIXED_AMOUNT,
      discount_value: 50000,
      scope: EPromotionScope.TICKET_ONLY,
    });

    expect(promo.type).toBe(EPromotionType.FIXED_AMOUNT);
    expect(promo.discount_value).toBe(50000);
    expect(promo.scope).toBe(EPromotionScope.TICKET_ONLY);
  });

  it('tạo promotion cho rạp cụ thể', () => {
    const cinema = createMockCinema();
    const promo = createMockPromotion({
      scope: EPromotionScope.SPECIFIC_CINEMA,
      applicable_cinema_ids: [cinema.id],
    });

    expect(promo.scope).toBe(EPromotionScope.SPECIFIC_CINEMA);
    expect(promo.applicable_cinema_ids).toContain(cinema.id);
  });
});

// ══════════════════════════════════════════════
// 2. ENTITIES CÓ FK (Level 1)
// ══════════════════════════════════════════════

describe('RoomEntity Mock', () => {
  it('tạo room với auto-generated cinema', () => {
    const room = createMockRoom();

    expectBaseFields(room);
    expect(room.name).toBe('Screen 01');
    expect(room.roomType).toBe(ERoomType.STANDARD_2D);
    expect(room.cinema).toBeDefined();
    expect(room.cinema_id).toBe(room.cinema.id);
  });

  it('sử dụng cinema đã cho', () => {
    const cinema = createMockCinema({ name: 'CGV Crescent' });
    const room = createMockRoom({
      cinema,
      name: 'IMAX Hall',
      roomType: ERoomType.IMAX,
    });

    expect(room.cinema.name).toBe('CGV Crescent');
    expect(room.cinema_id).toBe(cinema.id);
    expect(room.roomType).toBe(ERoomType.IMAX);
  });
});

describe('SeatEntity Mock', () => {
  it('tạo seat với auto-generated room và seat type', () => {
    const seat = createMockSeat();

    expectBaseFields(seat);
    expect(seat.row).toBe('A');
    expect(seat.col).toBe('01');
    expect(seat.room).toBeDefined();
    expect(seat.room_id).toBe(seat.room.id);
    expect(seat.seatType).toBeDefined();
    expect(seat.seat_type_id).toBe(seat.seatType.id);
  });

  it('sử dụng room và seat type đã cho', () => {
    const room = createMockRoom({ name: 'VIP Room' });
    const vipType = createMockSeatType({
      name: 'VIP',
      code: ESeatTypeCode.VIP,
      surcharge: 20000,
    });
    const seat = createMockSeat({
      room,
      seatType: vipType,
      row: 'B',
      col: '05',
    });

    expect(seat.room.name).toBe('VIP Room');
    expect(seat.seatType.code).toBe(ESeatTypeCode.VIP);
    expect(seat.row).toBe('B');
    expect(seat.col).toBe('05');
    // FK IDs khớp với entity
    expect(seat.room_id).toBe(room.id);
    expect(seat.seat_type_id).toBe(vipType.id);
  });
});

describe('MembershipEntity Mock', () => {
  it('tạo membership với auto-generated user', () => {
    const membership = createMockMembership();

    expectBaseFields(membership);
    expect(membership.user).toBeDefined();
    expect(membership.user_id).toBe(membership.user.id);
    expect(membership.member_code).toBeTruthy();
    expect(membership.tier).toBe(EMembershipTier.STANDARD);
    expect(membership.cgv_points).toBe(0);
    expect(membership.total_points_earned).toBe(0);
    expect(membership.is_active).toBe(true);
  });

  it('bulk: tạo memberships với tiers tăng dần', () => {
    const memberships = createMockMemberships();

    expect(memberships).toHaveLength(3);
    expect(memberships[0].tier).toBe(EMembershipTier.STANDARD);
    expect(memberships[1].tier).toBe(EMembershipTier.VIP);
    expect(memberships[2].tier).toBe(EMembershipTier.VVIP);
    // Points tăng dần
    expect(memberships[0].cgv_points).toBeLessThan(memberships[1].cgv_points);
    expect(memberships[1].cgv_points).toBeLessThan(memberships[2].cgv_points);
    // VVIP có tier_expiry_date
    expect(memberships[2].tier_expiry_date).toBeInstanceOf(Date);
  });
});

// ══════════════════════════════════════════════
// 3. ENTITIES CÓ FK (Level 2)
// ══════════════════════════════════════════════

describe('ShowtimeEntity Mock', () => {
  it('tạo showtime với tất cả relations', () => {
    const showtime = createMockShowtime();

    expectBaseFields(showtime);
    expect(showtime.movie).toBeDefined();
    expect(showtime.movie_id).toBe(showtime.movie.id);
    expect(showtime.room).toBeDefined();
    expect(showtime.room_id).toBe(showtime.room.id);
    expect(showtime.start_time).toBeInstanceOf(Date);
    expect(showtime.end_time).toBeInstanceOf(Date);
    expect(showtime.end_time.getTime()).toBeGreaterThan(
      showtime.start_time.getTime(),
    );
    expect(showtime.language).toBe('vi');
    expect(showtime.subtitle_type).toBe(ESubtitleType.SUBTITLED);
    expect(showtime.status).toBe(EShowtimeStatus.OPEN);
    expect(showtime.base_price).toBe(90000);
    expect(showtime.is_active).toBe(true);
  });

  it('end_time tự tính từ movie.duration', () => {
    const movie = createMockMovie({ duration: 120 }); // 2 giờ
    const startTime = new Date('2024-07-15T19:00:00Z');
    const showtime = createMockShowtime({ movie, start_time: startTime });

    const expectedEnd = new Date(startTime.getTime() + 120 * 60 * 1000);
    expect(showtime.end_time.getTime()).toBe(expectedEnd.getTime());
  });

  it('sử dụng movie, room đã cho', () => {
    const movie = createMockMovie({ name: 'Test Film' });
    const room = createMockRoom({ name: 'IMAX Hall' });

    const showtime = createMockShowtime({ movie, room, base_price: 150000 });

    expect(showtime.movie.name).toBe('Test Film');
    expect(showtime.room.name).toBe('IMAX Hall');
    expect(showtime.base_price).toBe(150000);
  });
});

describe('PointTransactionEntity Mock', () => {
  it('tạo point transaction mặc định (earn)', () => {
    const pt = createMockPointTransaction();

    expectBaseFields(pt);
    expect(pt.membership).toBeDefined();
    expect(pt.membership_id).toBe(pt.membership.id);
    expect(pt.type).toBe(EPointTransactionType.EARN);
    expect(pt.points).toBe(100);
    expect(pt.balance_after).toBe(pt.membership.cgv_points + 100);
    expect(pt.note).toBeTruthy();
  });

  it('tạo redeem transaction (điểm âm)', () => {
    const membership = createMockMembership({ cgv_points: 500 });
    const pt = createMockPointTransaction({
      membership,
      type: EPointTransactionType.REDEEM,
      points: -200,
      balance_after: 300,
      note: 'Dùng điểm đổi vé',
    });

    expect(pt.type).toBe(EPointTransactionType.REDEEM);
    expect(pt.points).toBe(-200);
    expect(pt.balance_after).toBe(300);
  });

  it('tạo transaction có reference_id', () => {
    const booking = createMockBooking();
    const pt = createMockPointTransaction({
      reference_id: booking.id,
      note: `Tích điểm từ đơn ${booking.booking_code}`,
    });

    expect(pt.reference_id).toBe(booking.id);
  });
});

// ══════════════════════════════════════════════
// 4. ENTITIES CÓ FK (Level 3-4)
// ══════════════════════════════════════════════

describe('BookingEntity Mock', () => {
  it('tạo booking với tất cả relations', () => {
    const booking = createMockBooking();

    expectBaseFields(booking);
    expect(booking.booking_code).toMatch(/^CGV\d{10}$/);
    expect(booking.user).toBeDefined();
    expect(booking.user_id).toBe(booking.user.id);
    expect(booking.showtime).toBeDefined();
    expect(booking.showtime_id).toBe(booking.showtime.id);
    expect(booking.ticket_total).toBeGreaterThan(0);
    expect(booking.combo_total).toBeGreaterThanOrEqual(0);
    expect(booking.final_amount).toBeGreaterThan(0);
    expect(booking.status).toBe(EBookingStatus.CONFIRMED);
    expect(booking.points_earned).toBeGreaterThanOrEqual(0);
    expect(booking.points_used).toBe(0);
  });

  it('final_amount = ticket_total + combo_total - discount_amount', () => {
    const booking = createMockBooking({
      ticket_total: 180000,
      combo_total: 89000,
      discount_amount: 50000,
    });

    expect(booking.final_amount).toBe(180000 + 89000 - 50000);
  });

  it('booking với promotion', () => {
    const promo = createMockPromotion({ code: 'TEST20', discount_value: 20 });
    const booking = createMockBooking({
      promotion: promo,
      promotion_id: promo.id,
      discount_amount: 53800,
    });

    expect(booking.promotion).toBeDefined();
    expect(booking.promotion.code).toBe('TEST20');
    expect(booking.promotion_id).toBe(promo.id);
    expect(booking.discount_amount).toBe(53800);
  });

  it('booking_code tự tăng', () => {
    const b1 = createMockBooking();
    const b2 = createMockBooking();

    expect(b1.booking_code).not.toBe(b2.booking_code);
  });

  it('booking pending với expired_at', () => {
    const expiredAt = new Date(Date.now() + 15 * 60 * 1000); // 15 phút
    const booking = createMockBooking({
      status: EBookingStatus.PENDING,
      expired_at: expiredAt,
    });

    expect(booking.status).toBe(EBookingStatus.PENDING);
    expect(booking.expired_at).toBe(expiredAt);
  });
});

describe('BookingDetailEntity Mock', () => {
  it('tạo booking detail với đầy đủ relations', () => {
    const detail = createMockBookingDetail();

    expectBaseFields(detail);
    expect(detail.booking).toBeDefined();
    expect(detail.booking_id).toBe(detail.booking.id);
    expect(detail.seat).toBeDefined();
    expect(detail.seat_id).toBe(detail.seat.id);
    expect(detail.seat_label).toBeTruthy(); // VD: "A01"
    expect(detail.seat_type).toBeTruthy();
    expect(detail.price).toBeGreaterThan(0);
    expect(detail.status).toBe(ETicketStatus.ACTIVE);
    expect(detail.qr_code).toBeTruthy();
  });

  it('seat_label tự động từ seat.row + seat.col', () => {
    const seat = createMockSeat({ row: 'C', col: '07' });
    const detail = createMockBookingDetail({ seat });

    expect(detail.seat_label).toBe('C07');
  });

  it('qr_code chứa booking_code', () => {
    const booking = createMockBooking();
    const seat = createMockSeat({ row: 'A', col: '01' });
    const detail = createMockBookingDetail({ booking, seat });

    expect(detail.qr_code).toContain(booking.booking_code);
    expect(detail.qr_code).toContain('A01');
  });

  it('vé đã sử dụng', () => {
    const detail = createMockBookingDetail({ status: ETicketStatus.USED });
    expect(detail.status).toBe(ETicketStatus.USED);
  });
});

describe('BookingComboEntity Mock', () => {
  it('tạo booking combo đầy đủ', () => {
    const bc = createMockBookingCombo();

    expectBaseFields(bc);
    expect(bc.booking).toBeDefined();
    expect(bc.booking_id).toBe(bc.booking.id);
    expect(bc.combo).toBeDefined();
    expect(bc.combo_id).toBe(bc.combo.id);
    expect(bc.quantity).toBeGreaterThan(0);
    expect(bc.unit_price).toBeGreaterThan(0);
    expect(bc.subtotal).toBe(bc.quantity * bc.unit_price);
  });

  it('subtotal tự tính = quantity × unit_price', () => {
    const bc = createMockBookingCombo({ quantity: 3, unit_price: 89000 });

    expect(bc.subtotal).toBe(3 * 89000);
  });

  it('unit_price lấy từ combo.price nếu không override', () => {
    const combo = createMockCombo({ price: 159000 });
    const bc = createMockBookingCombo({ combo, quantity: 2 });

    expect(bc.unit_price).toBe(159000);
    expect(bc.subtotal).toBe(318000);
  });
});

describe('PaymentEntity Mock', () => {
  it('tạo payment mặc định (MoMo, success)', () => {
    const payment = createMockPayment();

    expectBaseFields(payment);
    expect(payment.booking).toBeDefined();
    expect(payment.booking_id).toBe(payment.booking.id);
    expect(payment.method).toBe(EPaymentMethod.MOMO);
    expect(payment.amount).toBe(payment.booking.final_amount);
    expect(payment.status).toBe(EPaymentStatus.SUCCESS);
    expect(payment.transaction_id).toBeTruthy();
    expect(payment.paid_at).toBeInstanceOf(Date);
  });

  it('payment pending (chưa thanh toán)', () => {
    const payment = createMockPayment({
      status: EPaymentStatus.PENDING,
      transaction_id: undefined,
      paid_at: undefined,
    });

    expect(payment.status).toBe(EPaymentStatus.PENDING);
    expect(payment.transaction_id).toBeUndefined();
    expect(payment.paid_at).toBeUndefined();
  });

  it('payment với phương thức khác', () => {
    const payment = createMockPayment({ method: EPaymentMethod.VNPAY });
    expect(payment.method).toBe(EPaymentMethod.VNPAY);
  });

  it('payment failed', () => {
    const payment = createMockPayment({
      status: EPaymentStatus.FAILED,
      gateway_response: '{"error": "insufficient_funds"}',
    });

    expect(payment.status).toBe(EPaymentStatus.FAILED);
    expect(payment.gateway_response).toContain('insufficient_funds');
  });

  it('amount khớp với booking.final_amount', () => {
    const booking = createMockBooking({ final_amount: 215200 });
    const payment = createMockPayment({ booking });

    expect(payment.amount).toBe(215200);
  });
});

// ══════════════════════════════════════════════
// 5. FULL DATASET — Integration Tests
// ══════════════════════════════════════════════

describe('Full Mock Dataset', () => {
  it('tạo đầy đủ dataset với số lượng đúng', () => {
    const ds = createFullMockDataset();

    expect(ds.cinemas).toHaveLength(3);
    expect(ds.formats).toHaveLength(5);
    expect(ds.seatTypes).toHaveLength(4);
    expect(ds.movies).toHaveLength(5);
    expect(ds.combos).toHaveLength(4);
    expect(ds.promotions).toHaveLength(2);
    expect(ds.rooms).toHaveLength(6); // 3 cinemas × 2 rooms
    expect(ds.seats).toHaveLength(300); // 6 rooms × 5 rows × 10 seats
    expect(ds.users).toHaveLength(3);
    expect(ds.memberships).toHaveLength(3);
    expect(ds.showtimes).toHaveLength(6); // 3 movies × 2 rooms
    expect(ds.bookings).toHaveLength(3);
    expect(ds.bookingDetails).toHaveLength(6); // 3 bookings × 2 seats
    expect(ds.bookingCombos).toHaveLength(3);
    expect(ds.payments).toHaveLength(3);
    expect(ds.pointTransactions).toHaveLength(3);
  });

  it('tất cả entities có UUID hợp lệ', () => {
    const ds = createFullMockDataset();
    const uuidRegex =
      /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

    const allEntities = [
      ...ds.cinemas,
      ...ds.formats,
      ...ds.seatTypes,
      ...ds.movies,
      ...ds.combos,
      ...ds.promotions,
      ...ds.rooms,
      ...ds.seats,
      ...ds.users,
      ...ds.memberships,
      ...ds.showtimes,
      ...ds.bookings,
      ...ds.bookingDetails,
      ...ds.bookingCombos,
      ...ds.payments,
      ...ds.pointTransactions,
    ];

    allEntities.forEach((e) => {
      expect(e.id).toMatch(uuidRegex);
    });
  });

  it('tất cả IDs là unique', () => {
    const ds = createFullMockDataset();

    const allIds = [
      ...ds.cinemas,
      ...ds.formats,
      ...ds.seatTypes,
      ...ds.movies,
      ...ds.combos,
      ...ds.promotions,
      ...ds.rooms,
      ...ds.seats,
      ...ds.users,
      ...ds.memberships,
      ...ds.showtimes,
      ...ds.bookings,
      ...ds.bookingDetails,
      ...ds.bookingCombos,
      ...ds.payments,
      ...ds.pointTransactions,
    ].map((e) => e.id);

    expect(new Set(allIds).size).toBe(allIds.length);
  });

  it('FK relationships nhất quán: Room → Cinema', () => {
    const ds = createFullMockDataset();
    const cinemaIds = new Set(ds.cinemas.map((c) => c.id));

    ds.rooms.forEach((room) => {
      expect(cinemaIds.has(room.cinema_id)).toBe(true);
      expect(room.cinema).toBeDefined();
      expect(room.cinema_id).toBe(room.cinema.id);
    });
  });

  it('FK relationships nhất quán: Seat → Room & SeatType', () => {
    const ds = createFullMockDataset();
    const roomIds = new Set(ds.rooms.map((r) => r.id));
    const seatTypeIds = new Set(ds.seatTypes.map((s) => s.id));

    ds.seats.forEach((seat) => {
      expect(roomIds.has(seat.room_id)).toBe(true);
      expect(seatTypeIds.has(seat.seat_type_id)).toBe(true);
    });
  });

  it('FK relationships nhất quán: Showtime → Movie & Room', () => {
    const ds = createFullMockDataset();
    const movieIds = new Set(ds.movies.map((m) => m.id));
    const roomIds = new Set(ds.rooms.map((r) => r.id));

    ds.showtimes.forEach((st) => {
      expect(movieIds.has(st.movie_id)).toBe(true);
      expect(roomIds.has(st.room_id)).toBe(true);
      expect(st.end_time.getTime()).toBeGreaterThan(st.start_time.getTime());
    });
  });

  it('FK relationships nhất quán: Booking → User & Showtime', () => {
    const ds = createFullMockDataset();
    const userIds = new Set(ds.users.map((u) => u.id));
    const showtimeIds = new Set(ds.showtimes.map((s) => s.id));

    ds.bookings.forEach((booking) => {
      expect(userIds.has(booking.user_id)).toBe(true);
      expect(showtimeIds.has(booking.showtime_id)).toBe(true);
    });
  });

  it('FK relationships nhất quán: BookingDetail → Booking & Seat', () => {
    const ds = createFullMockDataset();
    const bookingIds = new Set(ds.bookings.map((b) => b.id));
    const seatIds = new Set(ds.seats.map((s) => s.id));

    ds.bookingDetails.forEach((detail) => {
      expect(bookingIds.has(detail.booking_id)).toBe(true);
      expect(seatIds.has(detail.seat_id)).toBe(true);
    });
  });

  it('FK relationships nhất quán: BookingCombo → Booking & Combo', () => {
    const ds = createFullMockDataset();
    const bookingIds = new Set(ds.bookings.map((b) => b.id));
    const comboIds = new Set(ds.combos.map((c) => c.id));

    ds.bookingCombos.forEach((bc) => {
      expect(bookingIds.has(bc.booking_id)).toBe(true);
      expect(comboIds.has(bc.combo_id)).toBe(true);
      expect(bc.subtotal).toBe(bc.quantity * bc.unit_price);
    });
  });

  it('FK relationships nhất quán: Payment → Booking', () => {
    const ds = createFullMockDataset();
    const bookingIds = new Set(ds.bookings.map((b) => b.id));

    ds.payments.forEach((payment) => {
      expect(bookingIds.has(payment.booking_id)).toBe(true);
    });
  });

  it('FK relationships nhất quán: Membership → User', () => {
    const ds = createFullMockDataset();
    const userIds = new Set(ds.users.map((u) => u.id));

    ds.memberships.forEach((m) => {
      expect(userIds.has(m.user_id)).toBe(true);
    });
  });

  it('FK relationships nhất quán: PointTransaction → Membership', () => {
    const ds = createFullMockDataset();
    const membershipIds = new Set(ds.memberships.map((m) => m.id));

    ds.pointTransactions.forEach((pt) => {
      expect(membershipIds.has(pt.membership_id)).toBe(true);
    });
  });

  it('dữ liệu tài chính nhất quán trong bookings', () => {
    const ds = createFullMockDataset();

    ds.bookings.forEach((booking) => {
      // final_amount = ticket_total + combo_total - discount_amount
      expect(booking.final_amount).toBe(
        booking.ticket_total + booking.combo_total - booking.discount_amount,
      );
      expect(booking.final_amount).toBeGreaterThan(0);
    });
  });

  it('payment.amount khớp booking.final_amount', () => {
    const ds = createFullMockDataset();

    ds.payments.forEach((payment, i) => {
      expect(payment.amount).toBe(ds.bookings[i].final_amount);
    });
  });

  it('booking đầu tiên có promotion, booking 2-3 không có', () => {
    const ds = createFullMockDataset();

    expect(ds.bookings[0].promotion).toBeDefined();
    expect(ds.bookings[0].promotion_id).toBeDefined();
    expect(ds.bookings[0].discount_amount).toBeGreaterThan(0);

    expect(ds.bookings[1].promotion).toBeUndefined();
    expect(ds.bookings[1].discount_amount).toBe(0);

    expect(ds.bookings[2].promotion).toBeUndefined();
    expect(ds.bookings[2].discount_amount).toBe(0);
  });

  it('point transactions có reference_id trỏ về booking', () => {
    const ds = createFullMockDataset();
    const bookingIds = new Set(ds.bookings.map((b) => b.id));

    ds.pointTransactions.forEach((pt) => {
      expect(bookingIds.has(pt.reference_id)).toBe(true);
    });
  });
});
