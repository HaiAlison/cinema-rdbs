/**
 * Mock Data Factory cho toàn bộ entities của CGV Cinema Booking System.
 *
 * Tất cả entity kế thừa BaseTimeStampEntity (id: UUID, created_at, updated_at, deleted_at).
 * Các hàm factory tạo mock data có quan hệ đúng với nhau, hỗ trợ override từng trường.
 */

import { randomUUID } from 'crypto';

// ─── Enums ─────────────────────────────────────────────────
// Re-export from entities for convenience

export enum EUserRole {
  CUSTOMER = 'customer',
  STAFF = 'staff',
  ADMIN = 'admin',
}

export enum ERoomType {
  IMAX = 'imax',
  FOUR_DX = '4dx',
  ULTRA_4DX = 'ultra_4dx',
  STARIUM = 'starium',
  INFINITY = 'infinity',
  GOLDEN_CLASS = 'golden_class',
  LAMOUR = 'lamour',
  SWEET_BOX = 'sweet_box',
  STANDARD_2D = 'standard_2d',
  STANDARD_3D = 'standard_3d',
}

export enum ESeatTypeCode {
  STANDARD = 'standard',
  VIP = 'vip',
  SWEETBOX = 'sweetbox',
  DELUXE = 'deluxe',
}

export enum EComboCategory {
  POPCORN = 'popcorn',
  DRINK = 'drink',
  COMBO = 'combo',
  SNACK = 'snack',
  MEAL = 'meal',
  GIFT = 'gift',
}

export enum EComboSize {
  SMALL = 'S',
  MEDIUM = 'M',
  LARGE = 'L',
  EXTRA_LARGE = 'XL',
}

export enum EPromotionType {
  PERCENTAGE = 'percentage',
  FIXED_AMOUNT = 'fixed_amount',
  FREE_COMBO = 'free_combo',
  BUY_X_GET_Y = 'buy_x_get_y',
  GIFT_CARD = 'gift_card',
}

export enum EPromotionScope {
  ALL = 'all',
  TICKET_ONLY = 'ticket_only',
  COMBO_ONLY = 'combo_only',
  SPECIFIC_MOVIE = 'specific_movie',
  SPECIFIC_CINEMA = 'specific_cinema',
  SPECIFIC_DAY = 'specific_day',
}

export enum EMembershipTier {
  STANDARD = 'standard',
  VIP = 'vip',
  VVIP = 'vvip',
}

export enum EShowtimeStatus {
  UPCOMING = 'upcoming',
  OPEN = 'open',
  FULL = 'full',
  ENDED = 'ended',
  CANCELLED = 'cancelled',
}

export enum ESubtitleType {
  SUBTITLED = 'subtitled',
  DUBBED = 'dubbed',
  ORIGINAL = 'original',
}

export enum EBookingStatus {
  PENDING = 'pending',
  CONFIRMED = 'confirmed',
  CANCELLED = 'cancelled',
  EXPIRED = 'expired',
  REFUNDED = 'refunded',
}

export enum ETicketStatus {
  ACTIVE = 'active',
  USED = 'used',
  CANCELLED = 'cancelled',
}

export enum EPaymentMethod {
  CREDIT_CARD = 'credit_card',
  MOMO = 'momo',
  ZALOPAY = 'zalopay',
  VNPAY = 'vnpay',
  BANKING = 'banking',
  CGV_GIFTCARD = 'cgv_giftcard',
  CGV_POINT = 'cgv_point',
  CASH = 'cash',
  SHOPEEPAY = 'shopeepay',
}

export enum EPaymentStatus {
  PENDING = 'pending',
  SUCCESS = 'success',
  FAILED = 'failed',
  REFUNDED = 'refunded',
}

export enum EPointTransactionType {
  EARN = 'earn',
  REDEEM = 'redeem',
  EXPIRE = 'expire',
  ADJUST = 'adjust',
  BONUS = 'bonus',
  REFUND = 'refund',
}

// ─── Base Fields ───────────────────────────────────────────

interface BaseTimestamp {
  id: string;
  created_at: Date;
  updated_at: Date;
  deleted_at: Date | null;
}

function baseFields(): BaseTimestamp {
  const now = new Date();
  return {
    id: randomUUID(),
    created_at: now,
    updated_at: now,
    deleted_at: null,
  };
}

// ─── Interfaces (matching actual entities) ─────────────────

export interface MockUser extends BaseTimestamp {
  name: string;
  code: string;
  email: string;
  phone: string;
  dob?: Date;
  province: string;
  avatar?: string;
  password: string;
  sex?: boolean;
  salt: string;
  is_active: boolean;
  role: EUserRole;
}

export interface MockCinema extends BaseTimestamp {
  name: string;
  phone: string;
  address: string;
  ward?: string;
  city?: string;
  fax?: string;
  hotline?: string;
  image_urls?: string[];
  description?: string;
  lat?: number;
  long?: number;
  link_ggmap?: string;
  is_active: boolean;
}

export interface MockRoom extends BaseTimestamp {
  name: string;
  cinema_id: string;
  cinema?: MockCinema;
  roomType: ERoomType;
}

export interface MockSeatType extends BaseTimestamp {
  name: string;
  code: ESeatTypeCode;
  surcharge: number;
  color?: string;
  description?: string;
  is_active: boolean;
}

export interface MockSeat extends BaseTimestamp {
  room_id: string;
  room?: MockRoom;
  seat_type_id: string;
  seatType?: MockSeatType;
  row: string;
  col: string;
}

export interface MockFormat extends BaseTimestamp {
  name: string;
  description: string;
  price: number;
  is_active: boolean;
}

export interface MockMovie extends BaseTimestamp {
  name: string;
  description: string;
  duration: number;
  rated: string;
  is_active: boolean;
  display_order: number;
  languages?: string[];
  release_date: Date;
  countries?: string[];
  genres?: string[];
  directors?: string[];
  actors?: string[];
  trailer_url?: string;
  poster_url?: string;
}

export interface MockCombo extends BaseTimestamp {
  name: string;
  description?: string;
  category: EComboCategory;
  size?: EComboSize;
  price: number;
  image_url?: string;
  is_available: boolean;
  is_e_combo: boolean;
  display_order: number;
}

export interface MockPromotion extends BaseTimestamp {
  name: string;
  description?: string;
  code?: string;
  type: EPromotionType;
  scope: EPromotionScope;
  discount_value: number;
  max_discount_amount?: number;
  min_order_amount?: number;
  start_date: Date;
  end_date: Date;
  usage_limit?: number;
  used_count: number;
  per_user_limit?: number;
  banner_url?: string;
  applicable_movie_ids?: string[];
  applicable_cinema_ids?: string[];
  is_active: boolean;
}

export interface MockMembership extends BaseTimestamp {
  user_id: string;
  user?: MockUser;
  member_code: string;
  tier: EMembershipTier;
  cgv_points: number;
  total_points_earned: number;
  tier_expiry_date?: Date;
  is_active: boolean;
}

export interface MockShowtime extends BaseTimestamp {
  movie_id: string;
  movie?: MockMovie;
  room_id: string;
  room?: MockRoom;
  start_time: Date;
  end_time: Date;
  language: string;
  subtitle_type?: ESubtitleType;
  status: EShowtimeStatus;
  base_price: number;
  is_active: boolean;
}

export interface MockBooking extends BaseTimestamp {
  booking_code: string;
  user_id: string;
  user?: MockUser;
  showtime_id: string;
  showtime?: MockShowtime;
  ticket_total: number;
  combo_total: number;
  discount_amount: number;
  final_amount: number;
  promotion_id?: string;
  promotion?: MockPromotion;
  status: EBookingStatus;
  expired_at?: Date;
  confirmed_at?: Date;
  points_earned: number;
  points_used: number;
}

export interface MockBookingDetail extends BaseTimestamp {
  booking_id: string;
  booking?: MockBooking;
  seat_id: string;
  seat?: MockSeat;
  seat_label: string;
  seat_type: string;
  price: number;
  status: ETicketStatus;
  qr_code?: string;
}

export interface MockBookingCombo extends BaseTimestamp {
  booking_id: string;
  booking?: MockBooking;
  combo_id: string;
  combo?: MockCombo;
  quantity: number;
  unit_price: number;
  subtotal: number;
}

export interface MockPayment extends BaseTimestamp {
  booking_id: string;
  booking?: MockBooking;
  method: EPaymentMethod;
  amount: number;
  status: EPaymentStatus;
  transaction_id?: string;
  gateway_response?: string;
  paid_at?: Date;
}

export interface MockPointTransaction extends BaseTimestamp {
  membership_id: string;
  membership?: MockMembership;
  type: EPointTransactionType;
  points: number;
  balance_after: number;
  reference_id?: string;
  note?: string;
  expire_at?: Date;
}

// ──────────────────────────────────────────────────
// Factory Functions
// ──────────────────────────────────────────────────

let userCodeCounter = 1;
let bookingCodeCounter = 1;
let membershipCodeCounter = 1;

export function resetCounters() {
  userCodeCounter = 1;
  bookingCodeCounter = 1;
  membershipCodeCounter = 1;
}

// ─── Independent Entities ──────────────────────────────────

export function createMockUser(overrides: Partial<MockUser> = {}): MockUser {
  const code = `CGV${String(userCodeCounter++).padStart(6, '0')}`;
  return {
    ...baseFields(),
    name: 'Nguyễn Văn A',
    code,
    email: `${code.toLowerCase()}@example.com`,
    phone: '0901234567',
    province: 'Hà Nội',
    password: '$2b$10$mockhashvalue1234567890',
    salt: 'random_salt_value',
    is_active: true,
    role: EUserRole.CUSTOMER,
    ...overrides,
  };
}

export function createMockCinema(
  overrides: Partial<MockCinema> = {},
): MockCinema {
  return {
    ...baseFields(),
    name: 'CGV Vincom Center Bà Triệu',
    phone: '1900 6017',
    address: '191 Bà Triệu, Hai Bà Trưng',
    ward: 'Lê Đại Hành',
    city: 'Hà Nội',
    is_active: true,
    ...overrides,
  };
}

export function createMockFormat(
  overrides: Partial<MockFormat> = {},
): MockFormat {
  return {
    ...baseFields(),
    name: '2D',
    description: 'Định dạng chiếu phim 2D thông thường',
    price: 0,
    is_active: true,
    ...overrides,
  };
}

export function createMockSeatType(
  overrides: Partial<MockSeatType> = {},
): MockSeatType {
  return {
    ...baseFields(),
    name: 'Ghế thường',
    code: ESeatTypeCode.STANDARD,
    surcharge: 0,
    color: '#4CAF50',
    is_active: true,
    ...overrides,
  };
}

export function createMockMovie(overrides: Partial<MockMovie> = {}): MockMovie {
  return {
    ...baseFields(),
    name: 'Avengers: Endgame',
    description:
      'Sau sự kiện tàn khốc của Thanos, vũ trụ đang trong đống đổ nát.',
    duration: 181,
    rated: 'C13',
    is_active: true,
    display_order: 0,
    languages: ['en'],
    release_date: new Date('2024-04-26'),
    countries: ['US'],
    genres: ['Hành động', 'Phiêu lưu', 'Khoa học viễn tưởng'],
    directors: ['Anthony Russo', 'Joe Russo'],
    actors: ['Robert Downey Jr.', 'Chris Evans', 'Scarlett Johansson'],
    trailer_url: 'https://youtube.com/watch?v=example',
    poster_url: 'https://example.com/avengers.jpg',
    ...overrides,
  };
}

export function createMockCombo(overrides: Partial<MockCombo> = {}): MockCombo {
  return {
    ...baseFields(),
    name: 'Combo Solo',
    description: '1 Bắp Ngọt Lớn + 1 Nước Ngọt 32oz',
    category: EComboCategory.COMBO,
    size: EComboSize.LARGE,
    price: 89000,
    image_url: 'https://example.com/combo-solo.jpg',
    is_available: true,
    is_e_combo: false,
    display_order: 0,
    ...overrides,
  };
}

export function createMockPromotion(
  overrides: Partial<MockPromotion> = {},
): MockPromotion {
  return {
    ...baseFields(),
    name: 'Khuyến mãi Hè 2024',
    description: 'Giảm 20% cho tất cả các phim trong mùa hè',
    code: 'SUMMER2024',
    type: EPromotionType.PERCENTAGE,
    scope: EPromotionScope.ALL,
    discount_value: 20,
    max_discount_amount: 50000,
    min_order_amount: 100000,
    start_date: new Date('2024-06-01'),
    end_date: new Date('2024-08-31'),
    usage_limit: 1000,
    used_count: 150,
    per_user_limit: 1,
    is_active: true,
    ...overrides,
  };
}

// ─── Level 1 Dependencies ──────────────────────────────────

export function createMockRoom(overrides: Partial<MockRoom> = {}): MockRoom {
  const cinema = overrides.cinema ?? createMockCinema();
  return {
    ...baseFields(),
    name: 'Screen 01',
    cinema,
    cinema_id: overrides.cinema_id ?? cinema.id,
    roomType: ERoomType.STANDARD_2D,
    ...overrides,
  };
}

export function createMockSeat(overrides: Partial<MockSeat> = {}): MockSeat {
  const room = overrides.room ?? createMockRoom();
  const seatType = overrides.seatType ?? createMockSeatType();
  return {
    ...baseFields(),
    room,
    room_id: overrides.room_id ?? room.id,
    seatType,
    seat_type_id: overrides.seat_type_id ?? seatType.id,
    row: 'A',
    col: '01',
    ...overrides,
  };
}

export function createMockMembership(
  overrides: Partial<MockMembership> = {},
): MockMembership {
  const user = overrides.user ?? createMockUser();
  return {
    ...baseFields(),
    user,
    user_id: overrides.user_id ?? user.id,
    member_code:
      overrides.member_code ??
      `MBR${String(membershipCodeCounter++).padStart(6, '0')}`,
    tier: EMembershipTier.STANDARD,
    cgv_points: 0,
    total_points_earned: 0,
    is_active: true,
    ...overrides,
  };
}

// ─── Level 2 Dependencies ──────────────────────────────────

export function createMockShowtime(
  overrides: Partial<MockShowtime> = {},
): MockShowtime {
  const movie = overrides.movie ?? createMockMovie();
  const room = overrides.room ?? createMockRoom();
  const startTime =
    overrides.start_time ?? new Date('2024-07-15T19:00:00+07:00');
  const endTime =
    overrides.end_time ??
    new Date(startTime.getTime() + movie.duration * 60 * 1000);

  return {
    ...baseFields(),
    movie,
    movie_id: overrides.movie_id ?? movie.id,
    room,
    room_id: overrides.room_id ?? room.id,
    start_time: startTime,
    end_time: endTime,
    language: 'vi',
    subtitle_type: ESubtitleType.SUBTITLED,
    status: EShowtimeStatus.OPEN,
    base_price: 90000,
    is_active: true,
    ...overrides,
  };
}

export function createMockPointTransaction(
  overrides: Partial<MockPointTransaction> = {},
): MockPointTransaction {
  const membership = overrides.membership ?? createMockMembership();
  return {
    ...baseFields(),
    membership,
    membership_id: overrides.membership_id ?? membership.id,
    type: EPointTransactionType.EARN,
    points: 100,
    balance_after: membership.cgv_points + 100,
    note: 'Tích điểm từ đơn đặt vé',
    ...overrides,
  };
}

// ─── Level 3 Dependencies ──────────────────────────────────

export function createMockBooking(
  overrides: Partial<MockBooking> = {},
): MockBooking {
  const user = overrides.user ?? createMockUser();
  const showtime = overrides.showtime ?? createMockShowtime();
  const bookingCode = `CGV${new Date().getFullYear()}${String(
    bookingCodeCounter++,
  ).padStart(6, '0')}`;
  const ticketTotal = overrides.ticket_total ?? 180000;
  const comboTotal = overrides.combo_total ?? 89000;
  const discountAmount = overrides.discount_amount ?? 0;
  const finalAmount =
    overrides.final_amount ?? ticketTotal + comboTotal - discountAmount;

  return {
    ...baseFields(),
    booking_code: bookingCode,
    user,
    user_id: overrides.user_id ?? user.id,
    showtime,
    showtime_id: overrides.showtime_id ?? showtime.id,
    ticket_total: ticketTotal,
    combo_total: comboTotal,
    discount_amount: discountAmount,
    final_amount: finalAmount,
    status: EBookingStatus.CONFIRMED,
    points_earned: Math.floor(finalAmount / 1000),
    points_used: 0,
    ...overrides,
  };
}

// ─── Level 4 Dependencies ──────────────────────────────────

export function createMockBookingDetail(
  overrides: Partial<MockBookingDetail> = {},
): MockBookingDetail {
  const booking = overrides.booking ?? createMockBooking();
  const seat = overrides.seat ?? createMockSeat();

  return {
    ...baseFields(),
    booking,
    booking_id: overrides.booking_id ?? booking.id,
    seat,
    seat_id: overrides.seat_id ?? seat.id,
    seat_label: `${seat.row}${seat.col}`,
    seat_type: seat.seatType?.name ?? 'Standard',
    price: 90000,
    status: ETicketStatus.ACTIVE,
    qr_code: `QR-${booking.booking_code}-${seat.row}${seat.col}`,
    ...overrides,
  };
}

export function createMockBookingCombo(
  overrides: Partial<MockBookingCombo> = {},
): MockBookingCombo {
  const booking = overrides.booking ?? createMockBooking();
  const combo = overrides.combo ?? createMockCombo();
  const quantity = overrides.quantity ?? 1;
  const unitPrice = overrides.unit_price ?? combo.price;

  return {
    ...baseFields(),
    booking,
    booking_id: overrides.booking_id ?? booking.id,
    combo,
    combo_id: overrides.combo_id ?? combo.id,
    quantity,
    unit_price: unitPrice,
    subtotal: overrides.subtotal ?? quantity * unitPrice,
    ...overrides,
  };
}

export function createMockPayment(
  overrides: Partial<MockPayment> = {},
): MockPayment {
  const booking = overrides.booking ?? createMockBooking();
  return {
    ...baseFields(),
    booking,
    booking_id: overrides.booking_id ?? booking.id,
    method: EPaymentMethod.MOMO,
    amount: booking.final_amount,
    status: EPaymentStatus.SUCCESS,
    transaction_id: `MOMO_TXN_${Date.now()}`,
    paid_at: new Date(),
    ...overrides,
  };
}

// ──────────────────────────────────────────────────
// Bulk Generators
// ──────────────────────────────────────────────────

export function createMockCinemas(count: number): MockCinema[] {
  const data = [
    {
      name: 'CGV Vincom Center Bà Triệu',
      city: 'Hà Nội',
      address: '191 Bà Triệu, Hai Bà Trưng',
    },
    {
      name: 'CGV Aeon Mall Tân Phú',
      city: 'TP.HCM',
      address: '30 Bờ Bao Tân Thắng, Sơn Kỳ, Tân Phú',
    },
    {
      name: 'CGV Crescent Mall',
      city: 'TP.HCM',
      address: '101 Tôn Dật Tiên, Tân Phú, Quận 7',
    },
    {
      name: 'CGV Liberty Citypoint',
      city: 'TP.HCM',
      address: '59 Pasteur, Bến Nghé, Quận 1',
    },
    {
      name: 'CGV Sư Vạn Hạnh',
      city: 'TP.HCM',
      address: '11 Sư Vạn Hạnh, Phường 12, Quận 10',
    },
  ];
  return Array.from({ length: count }, (_, i) =>
    createMockCinema(data[i % data.length]),
  );
}

export function createMockFormats(): MockFormat[] {
  return [
    createMockFormat({
      name: '2D',
      description: 'Phim 2D thông thường',
      price: 0,
    }),
    createMockFormat({
      name: '3D',
      description: 'Phim 3D kính 3D',
      price: 30000,
    }),
    createMockFormat({
      name: 'IMAX',
      description: 'Phim trên màn IMAX',
      price: 50000,
    }),
    createMockFormat({
      name: '4DX',
      description: 'Trải nghiệm 4D',
      price: 70000,
    }),
    createMockFormat({
      name: 'ScreenX',
      description: 'Màn 270 độ',
      price: 40000,
    }),
  ];
}

export function createMockSeatTypes(): MockSeatType[] {
  return [
    createMockSeatType({
      name: 'Ghế thường',
      code: ESeatTypeCode.STANDARD,
      surcharge: 0,
      color: '#4CAF50',
    }),
    createMockSeatType({
      name: 'Ghế VIP',
      code: ESeatTypeCode.VIP,
      surcharge: 20000,
      color: '#FF9800',
    }),
    createMockSeatType({
      name: 'Sweetbox',
      code: ESeatTypeCode.SWEETBOX,
      surcharge: 40000,
      color: '#E91E63',
    }),
    createMockSeatType({
      name: 'Deluxe',
      code: ESeatTypeCode.DELUXE,
      surcharge: 100000,
      color: '#9C27B0',
    }),
  ];
}

export function createMockMovies(count: number): MockMovie[] {
  const data = [
    {
      name: 'Avengers: Endgame',
      genres: ['Hành động', 'Phiêu lưu'],
      duration: 181,
      rated: 'C13',
    },
    {
      name: 'Lật Mặt 7: Một Điều Ước',
      genres: ['Hành động', 'Gia đình'],
      duration: 132,
      rated: 'C16',
    },
    {
      name: 'Doraemon: Nobita và Bản Giao Hưởng Địa Cầu',
      genres: ['Hoạt hình'],
      duration: 115,
      rated: 'P',
    },
    { name: 'Quỷ Cẩu', genres: ['Kinh dị'], duration: 100, rated: 'C18' },
    {
      name: 'Kung Fu Panda 4',
      genres: ['Hoạt hình', 'Hài'],
      duration: 94,
      rated: 'P',
    },
  ];
  return Array.from({ length: count }, (_, i) =>
    createMockMovie({
      ...data[i % data.length],
      is_active: i < 3,
      display_order: i,
      release_date: new Date(2024, i, 15),
    }),
  );
}

export function createMockCombos(): MockCombo[] {
  return [
    createMockCombo({
      name: 'Combo Solo',
      category: EComboCategory.COMBO,
      size: EComboSize.MEDIUM,
      price: 89000,
      description: '1 Bắp Ngọt Lớn + 1 Nước 32oz',
    }),
    createMockCombo({
      name: 'Combo Couple',
      category: EComboCategory.COMBO,
      size: EComboSize.LARGE,
      price: 109000,
      description: '1 Bắp Ngọt Lớn + 2 Nước 32oz',
    }),
    createMockCombo({
      name: 'Combo Family',
      category: EComboCategory.COMBO,
      size: EComboSize.EXTRA_LARGE,
      price: 199000,
      description: '2 Bắp Ngọt Lớn + 4 Nước 32oz',
    }),
    createMockCombo({
      name: 'CGV Deluxe Combo',
      category: EComboCategory.COMBO,
      size: EComboSize.LARGE,
      price: 159000,
      description: '1 Bắp Mix + 2 Nước 32oz + 1 Snack',
    }),
  ];
}

export function createMockMemberships(): MockMembership[] {
  const users = [
    createMockUser({ name: 'Nguyễn Văn A' }),
    createMockUser({ name: 'Trần Thị B' }),
    createMockUser({ name: 'Lê Hoàng C' }),
  ];
  return [
    createMockMembership({
      user: users[0],
      tier: EMembershipTier.STANDARD,
      cgv_points: 500,
      total_points_earned: 500,
    }),
    createMockMembership({
      user: users[1],
      tier: EMembershipTier.VIP,
      cgv_points: 6200,
      total_points_earned: 12000,
    }),
    createMockMembership({
      user: users[2],
      tier: EMembershipTier.VVIP,
      cgv_points: 25000,
      total_points_earned: 50000,
      tier_expiry_date: new Date('2025-12-31'),
    }),
  ];
}

// ──────────────────────────────────────────────────
// Full Dataset — Tạo toàn bộ data có quan hệ đúng
// ──────────────────────────────────────────────────

export function createFullMockDataset() {
  resetCounters();

  // Independent
  const cinemas = createMockCinemas(3);
  const formats = createMockFormats();
  const seatTypes = createMockSeatTypes();
  const movies = createMockMovies(5);
  const combos = createMockCombos();
  const promotions = [
    createMockPromotion({
      code: 'SUMMER2024',
      type: EPromotionType.PERCENTAGE,
      discount_value: 20,
    }),
    createMockPromotion({
      code: 'NEWUSER50K',
      type: EPromotionType.FIXED_AMOUNT,
      discount_value: 50000,
      name: 'Ưu đãi thành viên mới',
    }),
  ];

  // Level 1
  const rooms = cinemas.flatMap((cinema) => [
    createMockRoom({
      cinema,
      name: 'Screen 01',
      roomType: ERoomType.STANDARD_2D,
    }),
    createMockRoom({ cinema, name: 'Screen 02', roomType: ERoomType.IMAX }),
  ]);

  const seats = rooms.flatMap((room) => {
    const rows = ['A', 'B', 'C', 'D', 'E'];
    return rows.flatMap((row, rowIdx) =>
      Array.from({ length: 10 }, (_, seatIdx) =>
        createMockSeat({
          room,
          seatType: seatTypes[rowIdx < 3 ? 0 : rowIdx < 4 ? 1 : 2],
          row,
          col: String(seatIdx + 1).padStart(2, '0'),
        }),
      ),
    );
  });

  const users = [
    createMockUser({
      name: 'Nguyễn Văn A',
      email: 'nguyenvana@gmail.com',
      province: 'Hà Nội',
    }),
    createMockUser({
      name: 'Trần Thị B',
      email: 'tranthib@gmail.com',
      province: 'TP.HCM',
    }),
    createMockUser({
      name: 'Lê Hoàng C',
      email: 'lehoangc@gmail.com',
      province: 'Đà Nẵng',
    }),
  ];

  const memberships = [
    createMockMembership({
      user: users[0],
      tier: EMembershipTier.STANDARD,
      cgv_points: 500,
    }),
    createMockMembership({
      user: users[1],
      tier: EMembershipTier.VIP,
      cgv_points: 6200,
    }),
    createMockMembership({
      user: users[2],
      tier: EMembershipTier.VVIP,
      cgv_points: 25000,
    }),
  ];

  // Level 2
  const showtimes = movies.slice(0, 3).flatMap((movie, i) =>
    rooms.slice(0, 2).map((room, j) =>
      createMockShowtime({
        movie,
        room,
        start_time: new Date(2024, 6, 15, 14 + i * 3 + j, 0, 0),
        base_price: 90000,
        status: EShowtimeStatus.OPEN,
      }),
    ),
  );

  // Level 3
  const bookings = users.map((user, i) =>
    createMockBooking({
      user,
      showtime: showtimes[i],
      promotion: i === 0 ? promotions[0] : undefined,
      promotion_id: i === 0 ? promotions[0].id : undefined,
      ticket_total: 180000,
      combo_total: 89000,
      discount_amount: i === 0 ? 53800 : 0,
      final_amount: i === 0 ? 215200 : 269000,
      status: EBookingStatus.CONFIRMED,
      confirmed_at: new Date(),
    }),
  );

  // Level 4
  const bookingDetails = bookings.flatMap((booking, i) => [
    createMockBookingDetail({ booking, seat: seats[i * 2], price: 90000 }),
    createMockBookingDetail({ booking, seat: seats[i * 2 + 1], price: 90000 }),
  ]);

  const bookingCombos = bookings.map((booking, i) =>
    createMockBookingCombo({
      booking,
      combo: combos[i % combos.length],
      quantity: 1,
      unit_price: combos[i % combos.length].price,
    }),
  );

  const payments = bookings.map((booking) =>
    createMockPayment({
      booking,
      amount: booking.final_amount,
      method: EPaymentMethod.MOMO,
      status: EPaymentStatus.SUCCESS,
    }),
  );

  const pointTransactions = memberships.map((membership, i) =>
    createMockPointTransaction({
      membership,
      points: bookings[i].points_earned,
      balance_after: membership.cgv_points + bookings[i].points_earned,
      type: EPointTransactionType.EARN,
      reference_id: bookings[i].id,
      note: `Tích điểm từ đơn ${bookings[i].booking_code}`,
    }),
  );

  return {
    cinemas,
    formats,
    seatTypes,
    movies,
    combos,
    promotions,
    rooms,
    seats,
    users,
    memberships,
    showtimes,
    bookings,
    bookingDetails,
    bookingCombos,
    payments,
    pointTransactions,
  };
}
