/**
 * Seeder Script: Đổ toàn bộ mock dataset xuống Database PostgreSQL thực tế
 * Sử dụng TypeORM DataSource và các dữ liệu từ mock-data.factory.
 */

import dataSource from '../utils/config/database/config.service';
import { createFullMockDataset } from '../entities/__tests__/mock-data.factory';

async function seed() {
  console.log('🔄 Đang kết nối tới Database...');
  await dataSource.initialize();
  console.log('✅ Kết nối thành công!');

  const queryRunner = dataSource.createQueryRunner();
  await queryRunner.connect();
  await queryRunner.startTransaction();

  try {
    const ds = createFullMockDataset();

    console.log('🧹 Đang dọn dẹp dữ liệu cũ (TRUNCATE CASCADE)...');
    const tables = [
      'point_transaction',
      'payment',
      'booking_combo',
      'booking_detail',
      'booking',
      'showtime',
      'membership',
      'users',
      'promotion',
      'combo',
      'movie_format',
      'movie',
      'seat',
      'room',
      'seat_type',
      'format',
      'cinema',
    ];

    for (const table of tables) {
      await queryRunner.query(`TRUNCATE TABLE "${table}" CASCADE;`);
    }

    console.log('📥 Đang chèn dữ liệu vào các bảng...');

    // 1. Independent Tables
    // Cinemas
    for (const c of ds.cinemas) {
      await queryRunner.query(
        `INSERT INTO "cinema" (id, created_at, updated_at, name, phone, address, ward, city, is_active)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
        [c.id, c.created_at, c.updated_at, c.name, c.phone, c.address, c.ward ?? null, c.city ?? null, c.is_active],
      );
    }
    console.log(`  ✓ Đã chèn ${ds.cinemas.length} rạp chiếu (cinema)`);

    // Formats
    for (const f of ds.formats) {
      await queryRunner.query(
        `INSERT INTO "format" (id, created_at, updated_at, name, description, price, is_active)
         VALUES ($1, $2, $3, $4, $5, $6, $7)`,
        [f.id, f.created_at, f.updated_at, f.name, f.description, f.price, f.is_active],
      );
    }
    console.log(`  ✓ Đã chèn ${ds.formats.length} định dạng (format)`);

    // Seat Types
    for (const st of ds.seatTypes) {
      await queryRunner.query(
        `INSERT INTO "seat_type" (id, created_at, updated_at, name, code, surcharge, color, is_active)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
        [st.id, st.created_at, st.updated_at, st.name, st.code, st.surcharge, st.color ?? null, st.is_active],
      );
    }
    console.log(`  ✓ Đã chèn ${ds.seatTypes.length} loại ghế (seat_type)`);

    // Movies
    for (const m of ds.movies) {
      await queryRunner.query(
        `INSERT INTO "movie" (id, created_at, updated_at, name, description, duration, rated, is_active, display_order, languages, release_date, countries, genres, directors, actors, trailer_url, poster_url)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17)`,
        [
          m.id,
          m.created_at,
          m.updated_at,
          m.name,
          m.description,
          m.duration,
          m.rated,
          m.is_active,
          m.display_order,
          (m.languages ?? []).join(','),
          m.release_date,
          (m.countries ?? []).join(','),
          (m.genres ?? []).join(','),
          (m.directors ?? []).join(','),
          (m.actors ?? []).join(','),
          m.trailer_url ?? null,
          m.poster_url ?? null,
        ],
      );
    }
    console.log(`  ✓ Đã chèn ${ds.movies.length} phim (movie)`);

    // Combos
    for (const cb of ds.combos) {
      await queryRunner.query(
        `INSERT INTO "combo" (id, created_at, updated_at, name, description, category, size, price, image_url, is_available, is_e_combo, display_order)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)`,
        [
          cb.id,
          cb.created_at,
          cb.updated_at,
          cb.name,
          cb.description ?? null,
          cb.category,
          cb.size ?? null,
          cb.price,
          cb.image_url ?? null,
          cb.is_available,
          cb.is_e_combo,
          cb.display_order,
        ],
      );
    }
    console.log(`  ✓ Đã chèn ${ds.combos.length} combo bắp nước (combo)`);

    // Promotions
    for (const pr of ds.promotions) {
      await queryRunner.query(
        `INSERT INTO "promotion" (id, created_at, updated_at, name, description, code, type, scope, discount_value, max_discount_amount, min_order_amount, start_date, end_date, usage_limit, used_count, per_user_limit, is_active)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17)`,
        [
          pr.id,
          pr.created_at,
          pr.updated_at,
          pr.name,
          pr.description ?? null,
          pr.code ?? null,
          pr.type,
          pr.scope,
          pr.discount_value,
          pr.max_discount_amount ?? null,
          pr.min_order_amount ?? null,
          pr.start_date,
          pr.end_date,
          pr.usage_limit ?? null,
          pr.used_count,
          pr.per_user_limit ?? null,
          pr.is_active,
        ],
      );
    }
    console.log(`  ✓ Đã chèn ${ds.promotions.length} mã khuyến mãi (promotion)`);

    // 2. Level 1: Users, Rooms, Seats, Memberships
    for (const u of ds.users) {
      await queryRunner.query(
        `INSERT INTO "users" (id, created_at, updated_at, name, code, email, phone, province, password, salt, is_active, role)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)`,
        [u.id, u.created_at, u.updated_at, u.name, u.code, u.email, u.phone, u.province, u.password, u.salt, u.is_active, u.role],
      );
    }
    console.log(`  ✓ Đã chèn ${ds.users.length} người dùng (users)`);

    for (const r of ds.rooms) {
      await queryRunner.query(
        `INSERT INTO "room" (id, created_at, updated_at, name, cinema_id, "roomType")
         VALUES ($1, $2, $3, $4, $5, $6)`,
        [r.id, r.created_at, r.updated_at, r.name, r.cinema_id, r.roomType],
      );
    }
    console.log(`  ✓ Đã chèn ${ds.rooms.length} phòng chiếu (room)`);

    for (const s of ds.seats) {
      await queryRunner.query(
        `INSERT INTO "seat" (id, created_at, updated_at, room_id, seat_type_id, "row", col)
         VALUES ($1, $2, $3, $4, $5, $6, $7)`,
        [s.id, s.created_at, s.updated_at, s.room_id, s.seat_type_id, s.row, s.col],
      );
    }
    console.log(`  ✓ Đã chèn ${ds.seats.length} ghế ngồi (seat)`);

    for (const m of ds.memberships) {
      await queryRunner.query(
        `INSERT INTO "membership" (id, created_at, updated_at, user_id, member_code, tier, cgv_points, total_points_earned, tier_expiry_date, is_active)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`,
        [
          m.id,
          m.created_at,
          m.updated_at,
          m.user_id,
          m.member_code,
          m.tier,
          m.cgv_points,
          m.total_points_earned,
          m.tier_expiry_date ?? null,
          m.is_active,
        ],
      );
    }
    console.log(`  ✓ Đã chèn ${ds.memberships.length} thẻ thành viên (membership)`);

    // 3. Level 2: Showtimes, Point Transactions
    for (const st of ds.showtimes) {
      await queryRunner.query(
        `INSERT INTO "showtime" (id, created_at, updated_at, movie_id, room_id, start_time, end_time, language, subtitle_type, status, base_price, is_active)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)`,
        [
          st.id,
          st.created_at,
          st.updated_at,
          st.movie_id,
          st.room_id,
          st.start_time,
          st.end_time,
          st.language,
          st.subtitle_type ?? null,
          st.status,
          st.base_price,
          st.is_active,
        ],
      );
    }
    console.log(`  ✓ Đã chèn ${ds.showtimes.length} suất chiếu (showtime)`);

    // 4. Level 3: Bookings
    for (const b of ds.bookings) {
      await queryRunner.query(
        `INSERT INTO "booking" (id, created_at, updated_at, booking_code, user_id, showtime_id, ticket_total, combo_total, discount_amount, final_amount, promotion_id, status, points_earned, points_used, confirmed_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)`,
        [
          b.id,
          b.created_at,
          b.updated_at,
          b.booking_code,
          b.user_id,
          b.showtime_id,
          b.ticket_total,
          b.combo_total,
          b.discount_amount,
          b.final_amount,
          b.promotion_id ?? null,
          b.status,
          b.points_earned,
          b.points_used,
          b.confirmed_at ?? null,
        ],
      );
    }
    console.log(`  ✓ Đã chèn ${ds.bookings.length} đơn đặt vé (booking)`);

    // 5. Level 4: Booking Details, Combos, Payments, Point Transactions
    for (const bd of ds.bookingDetails) {
      await queryRunner.query(
        `INSERT INTO "booking_detail" (id, created_at, updated_at, booking_id, seat_id, seat_label, seat_type, price, status, qr_code)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`,
        [bd.id, bd.created_at, bd.updated_at, bd.booking_id, bd.seat_id, bd.seat_label, bd.seat_type, bd.price, bd.status, bd.qr_code ?? null],
      );
    }
    console.log(`  ✓ Đã chèn ${ds.bookingDetails.length} chi tiết vé (booking_detail)`);

    for (const bc of ds.bookingCombos) {
      await queryRunner.query(
        `INSERT INTO "booking_combo" (id, created_at, updated_at, booking_id, combo_id, quantity, unit_price, subtotal)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
        [bc.id, bc.created_at, bc.updated_at, bc.booking_id, bc.combo_id, bc.quantity, bc.unit_price, bc.subtotal],
      );
    }
    console.log(`  ✓ Đã chèn ${ds.bookingCombos.length} combo đặt theo vé (booking_combo)`);

    for (const p of ds.payments) {
      await queryRunner.query(
        `INSERT INTO "payment" (id, created_at, updated_at, booking_id, method, amount, status, transaction_id, paid_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
        [p.id, p.created_at, p.updated_at, p.booking_id, p.method, p.amount, p.status, p.transaction_id ?? null, p.paid_at ?? null],
      );
    }
    console.log(`  ✓ Đã chèn ${ds.payments.length} thanh toán (payment)`);

    for (const pt of ds.pointTransactions) {
      await queryRunner.query(
        `INSERT INTO "point_transaction" (id, created_at, updated_at, membership_id, type, points, balance_after, reference_id, note)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
        [pt.id, pt.created_at, pt.updated_at, pt.membership_id, pt.type, pt.points, pt.balance_after, pt.reference_id ?? null, pt.note ?? null],
      );
    }
    console.log(`  ✓ Đã chèn ${ds.pointTransactions.length} giao dịch tích điểm (point_transaction)`);

    await queryRunner.commitTransaction();
    console.log('\n🎉 ĐÃ SEED THÀNH CÔNG TOÀN BỘ DATA XUỐNG DATABASE!');
  } catch (error) {
    await queryRunner.rollbackTransaction();
    console.error('❌ Lỗi khi seed database:', error);
    process.exit(1);
  } finally {
    await queryRunner.release();
    await dataSource.destroy();
  }
}

seed();

