-- =============================================================================
-- BÀI TẬP LỚN 2 - HỆ CƠ SỞ DỮ LIỆU (HK261)
-- MODULE 5: BOOKING, COMBO & PAYMENT (THÀNH VIÊN 5)
-- FILE: 01_booking_module_schema.sql
-- YÊU CẦU: Mục 1.1 - Tạo bảng, Khóa chính, Khóa ngoại, CHECK & Semantic Constraints
-- Các bảng phụ trách: booking, booking_detail, booking_combo, combo, payment, promotion
-- Tương thích đồng thời cả DB mới và DB đã chạy TypeORM migration.
-- =============================================================================

SET client_encoding = 'UTF8';

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 1. KHỞI TẠO CÁC KIỂU ENUM (ĐỒNG BỘ VỚI TYPEORM ENTITIES)
-- =============================================================================

DO $$ BEGIN
    CREATE TYPE public.combo_category_enum AS ENUM (
        'popcorn', 'drink', 'combo', 'snack', 'meal', 'gift'
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE public.combo_size_enum AS ENUM (
        'S', 'M', 'L', 'XL'
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE public.promotion_type_enum AS ENUM (
        'percentage', 'fixed_amount', 'free_combo', 'buy_x_get_y', 'gift_card'
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE public.promotion_scope_enum AS ENUM (
        'all', 'ticket_only', 'combo_only', 'specific_movie', 'specific_cinema', 'specific_day'
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE public.booking_status_enum AS ENUM (
        'pending', 'confirmed', 'cancelled', 'expired', 'refunded'
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE public.booking_detail_status_enum AS ENUM (
        'active', 'used', 'cancelled'
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE public.payment_method_enum AS ENUM (
        'credit_card', 'momo', 'zalopay', 'vnpay', 'banking',
        'cgv_giftcard', 'cgv_point', 'cash', 'shopeepay'
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE public.payment_status_enum AS ENUM (
        'pending', 'success', 'failed', 'refunded'
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;


-- =============================================================================
-- 2. TẠO CÁC BẢNG THUỘC PHÂN HỆ THÀNH VIÊN 5 (NẾU CHƯA TỒN TẠI)
-- =============================================================================

-- 2.1 BẢNG COMBO (Bắp nước & Sản phẩm F&B)
CREATE TABLE IF NOT EXISTS public.combo (
    id UUID DEFAULT public.uuid_generate_v4() NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now(),
    deleted_at TIMESTAMPTZ,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    category public.combo_category_enum NOT NULL,
    size public.combo_size_enum,
    price NUMERIC(12,2) NOT NULL,
    image_url VARCHAR,
    is_available BOOLEAN DEFAULT true NOT NULL,
    is_e_combo BOOLEAN DEFAULT false NOT NULL,
    display_order INTEGER DEFAULT 0 NOT NULL,
    CONSTRAINT PK_combo PRIMARY KEY (id)
);

-- 2.2 BẢNG PROMOTION (Chương trình khuyến mãi / Voucher)
CREATE TABLE IF NOT EXISTS public.promotion (
    id UUID DEFAULT public.uuid_generate_v4() NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now(),
    deleted_at TIMESTAMPTZ,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    code VARCHAR(100),
    type public.promotion_type_enum NOT NULL,
    scope public.promotion_scope_enum DEFAULT 'all'::public.promotion_scope_enum NOT NULL,
    discount_value NUMERIC(12,2) NOT NULL,
    max_discount_amount NUMERIC(12,2),
    min_order_amount NUMERIC(12,2),
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL,
    usage_limit INTEGER,
    used_count INTEGER DEFAULT 0 NOT NULL,
    per_user_limit INTEGER,
    banner_url VARCHAR,
    applicable_movie_ids TEXT,
    applicable_cinema_ids TEXT,
    is_active BOOLEAN DEFAULT true NOT NULL,
    CONSTRAINT PK_promotion PRIMARY KEY (id),
    CONSTRAINT UQ_promotion_code UNIQUE (code)
);

-- 2.3 BẢNG BOOKING (Hóa đơn đặt vé)
CREATE TABLE IF NOT EXISTS public.booking (
    id UUID DEFAULT public.uuid_generate_v4() NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now(),
    deleted_at TIMESTAMPTZ,
    booking_code VARCHAR(50) NOT NULL,
    user_id UUID NOT NULL,
    showtime_id UUID NOT NULL,
    ticket_total NUMERIC(12,2) NOT NULL,
    combo_total NUMERIC(12,2) DEFAULT 0 NOT NULL,
    discount_amount NUMERIC(12,2) DEFAULT 0 NOT NULL,
    final_amount NUMERIC(12,2) NOT NULL,
    promotion_id UUID,
    status public.booking_status_enum DEFAULT 'pending'::public.booking_status_enum NOT NULL,
    expired_at TIMESTAMPTZ,
    confirmed_at TIMESTAMPTZ,
    points_earned INTEGER DEFAULT 0 NOT NULL,
    points_used INTEGER DEFAULT 0 NOT NULL,
    CONSTRAINT PK_booking PRIMARY KEY (id),
    CONSTRAINT UQ_booking_booking_code UNIQUE (booking_code),
    CONSTRAINT FK_booking_users FOREIGN KEY (user_id) REFERENCES public.users(id),
    CONSTRAINT FK_booking_showtime FOREIGN KEY (showtime_id) REFERENCES public.showtime(id),
    CONSTRAINT FK_booking_promotion FOREIGN KEY (promotion_id) REFERENCES public.promotion(id)
);

-- 2.4 BẢNG BOOKING_DETAIL (Chi tiết vé từng ghế trong đơn)
CREATE TABLE IF NOT EXISTS public.booking_detail (
    id UUID DEFAULT public.uuid_generate_v4() NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now(),
    deleted_at TIMESTAMPTZ,
    booking_id UUID NOT NULL,
    seat_id UUID NOT NULL,
    seat_label VARCHAR(50) NOT NULL,
    seat_type VARCHAR(50) NOT NULL,
    price NUMERIC(12,2) NOT NULL,
    status public.booking_detail_status_enum DEFAULT 'active'::public.booking_detail_status_enum NOT NULL,
    qr_code VARCHAR(255),
    CONSTRAINT PK_booking_detail PRIMARY KEY (id),
    CONSTRAINT FK_booking_detail_booking FOREIGN KEY (booking_id) REFERENCES public.booking(id) ON DELETE CASCADE,
    CONSTRAINT FK_booking_detail_seat FOREIGN KEY (seat_id) REFERENCES public.seat(id)
);

-- 2.5 BẢNG BOOKING_COMBO (Chi tiết bắp nước mua kèm trong đơn)
CREATE TABLE IF NOT EXISTS public.booking_combo (
    id UUID DEFAULT public.uuid_generate_v4() NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now(),
    deleted_at TIMESTAMPTZ,
    booking_id UUID NOT NULL,
    combo_id UUID NOT NULL,
    quantity INTEGER DEFAULT 1 NOT NULL,
    unit_price NUMERIC(12,2) NOT NULL,
    subtotal NUMERIC(12,2) NOT NULL,
    CONSTRAINT PK_booking_combo PRIMARY KEY (id),
    CONSTRAINT FK_booking_combo_booking FOREIGN KEY (booking_id) REFERENCES public.booking(id) ON DELETE CASCADE,
    CONSTRAINT FK_booking_combo_combo FOREIGN KEY (combo_id) REFERENCES public.combo(id)
);

-- 2.6 BẢNG PAYMENT (Giao dịch thanh toán hóa đơn)
CREATE TABLE IF NOT EXISTS public.payment (
    id UUID DEFAULT public.uuid_generate_v4() NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now(),
    deleted_at TIMESTAMPTZ,
    booking_id UUID NOT NULL,
    method public.payment_method_enum NOT NULL,
    amount NUMERIC(12,2) NOT NULL,
    status public.payment_status_enum DEFAULT 'pending'::public.payment_status_enum NOT NULL,
    transaction_id VARCHAR(100),
    gateway_response VARCHAR(1000),
    paid_at TIMESTAMPTZ,
    CONSTRAINT PK_payment PRIMARY KEY (id),
    CONSTRAINT FK_payment_booking FOREIGN KEY (booking_id) REFERENCES public.booking(id) ON DELETE CASCADE
);


-- =============================================================================
-- 3. ÁP DỤNG BỔ SUNG CÁC RÀNG BUỘC CHECK / UNIQUE / CASCADE QUA ALTER TABLE
-- (Đảm bảo áp dụng đầy đủ kể cả khi bảng đã được tạo sẵn từ TypeORM migration)
-- =============================================================================

-- 3.1 Ràng buộc bảng COMBO
ALTER TABLE public.combo DROP CONSTRAINT IF EXISTS CK_combo_name_not_empty;
ALTER TABLE public.combo ADD CONSTRAINT CK_combo_name_not_empty
    CHECK (length(trim(name)) >= 2);

ALTER TABLE public.combo DROP CONSTRAINT IF EXISTS CK_combo_price_non_negative;
ALTER TABLE public.combo ADD CONSTRAINT CK_combo_price_non_negative
    CHECK (price >= 0);

ALTER TABLE public.combo DROP CONSTRAINT IF EXISTS CK_combo_display_order;
ALTER TABLE public.combo ADD CONSTRAINT CK_combo_display_order
    CHECK (display_order >= 0);

-- 3.2 Ràng buộc bảng PROMOTION
ALTER TABLE public.promotion DROP CONSTRAINT IF EXISTS CK_promotion_discount_value;
ALTER TABLE public.promotion ADD CONSTRAINT CK_promotion_discount_value
    CHECK (discount_value > 0);

ALTER TABLE public.promotion DROP CONSTRAINT IF EXISTS CK_promotion_percentage_range;
ALTER TABLE public.promotion ADD CONSTRAINT CK_promotion_percentage_range
    CHECK (type <> 'percentage'::public.promotion_type_enum OR (discount_value > 0 AND discount_value <= 100));

ALTER TABLE public.promotion DROP CONSTRAINT IF EXISTS CK_promotion_date_range;
ALTER TABLE public.promotion ADD CONSTRAINT CK_promotion_date_range
    CHECK (end_date > start_date);

ALTER TABLE public.promotion DROP CONSTRAINT IF EXISTS CK_promotion_max_discount;
ALTER TABLE public.promotion ADD CONSTRAINT CK_promotion_max_discount
    CHECK (max_discount_amount IS NULL OR max_discount_amount >= 0);

ALTER TABLE public.promotion DROP CONSTRAINT IF EXISTS CK_promotion_min_order;
ALTER TABLE public.promotion ADD CONSTRAINT CK_promotion_min_order
    CHECK (min_order_amount IS NULL OR min_order_amount >= 0);

ALTER TABLE public.promotion DROP CONSTRAINT IF EXISTS CK_promotion_usage_count;
ALTER TABLE public.promotion ADD CONSTRAINT CK_promotion_usage_count
    CHECK (used_count >= 0 AND (usage_limit IS NULL OR (usage_limit > 0 AND used_count <= usage_limit)));

ALTER TABLE public.promotion DROP CONSTRAINT IF EXISTS CK_promotion_per_user_limit;
ALTER TABLE public.promotion ADD CONSTRAINT CK_promotion_per_user_limit
    CHECK (per_user_limit IS NULL OR per_user_limit > 0);

-- 3.3 Ràng buộc bảng BOOKING
ALTER TABLE public.booking DROP CONSTRAINT IF EXISTS CK_booking_ticket_total;
ALTER TABLE public.booking ADD CONSTRAINT CK_booking_ticket_total
    CHECK (ticket_total >= 0);

ALTER TABLE public.booking DROP CONSTRAINT IF EXISTS CK_booking_combo_total;
ALTER TABLE public.booking ADD CONSTRAINT CK_booking_combo_total
    CHECK (combo_total >= 0);

ALTER TABLE public.booking DROP CONSTRAINT IF EXISTS CK_booking_discount_amount;
ALTER TABLE public.booking ADD CONSTRAINT CK_booking_discount_amount
    CHECK (discount_amount >= 0);

ALTER TABLE public.booking DROP CONSTRAINT IF EXISTS CK_booking_final_amount;
ALTER TABLE public.booking ADD CONSTRAINT CK_booking_final_amount
    CHECK (final_amount >= 0);

ALTER TABLE public.booking DROP CONSTRAINT IF EXISTS CK_booking_points_earned;
ALTER TABLE public.booking ADD CONSTRAINT CK_booking_points_earned
    CHECK (points_earned >= 0);

ALTER TABLE public.booking DROP CONSTRAINT IF EXISTS CK_booking_points_used;
ALTER TABLE public.booking ADD CONSTRAINT CK_booking_points_used
    CHECK (points_used >= 0);

ALTER TABLE public.booking DROP CONSTRAINT IF EXISTS CK_booking_confirmed_time;
ALTER TABLE public.booking ADD CONSTRAINT CK_booking_confirmed_time
    CHECK (status <> 'confirmed'::public.booking_status_enum OR confirmed_at IS NOT NULL);

-- 3.4 Ràng buộc bảng BOOKING_DETAIL
ALTER TABLE public.booking_detail DROP CONSTRAINT IF EXISTS UQ_booking_detail_booking_seat;
ALTER TABLE public.booking_detail ADD CONSTRAINT UQ_booking_detail_booking_seat
    UNIQUE (booking_id, seat_id);

ALTER TABLE public.booking_detail DROP CONSTRAINT IF EXISTS CK_booking_detail_price;
ALTER TABLE public.booking_detail ADD CONSTRAINT CK_booking_detail_price
    CHECK (price >= 0);

-- 3.5 Ràng buộc bảng BOOKING_COMBO
ALTER TABLE public.booking_combo DROP CONSTRAINT IF EXISTS UQ_booking_combo_booking_combo;
ALTER TABLE public.booking_combo ADD CONSTRAINT UQ_booking_combo_booking_combo
    UNIQUE (booking_id, combo_id);

ALTER TABLE public.booking_combo DROP CONSTRAINT IF EXISTS CK_booking_combo_quantity;
ALTER TABLE public.booking_combo ADD CONSTRAINT CK_booking_combo_quantity
    CHECK (quantity > 0);

ALTER TABLE public.booking_combo DROP CONSTRAINT IF EXISTS CK_booking_combo_unit_price;
ALTER TABLE public.booking_combo ADD CONSTRAINT CK_booking_combo_unit_price
    CHECK (unit_price >= 0);

ALTER TABLE public.booking_combo DROP CONSTRAINT IF EXISTS CK_booking_combo_subtotal;
ALTER TABLE public.booking_combo ADD CONSTRAINT CK_booking_combo_subtotal
    CHECK (subtotal = quantity * unit_price);

-- 3.6 Ràng buộc bảng PAYMENT
ALTER TABLE public.payment DROP CONSTRAINT IF EXISTS CK_payment_amount;
ALTER TABLE public.payment ADD CONSTRAINT CK_payment_amount
    CHECK (amount > 0);

ALTER TABLE public.payment DROP CONSTRAINT IF EXISTS CK_payment_paid_at;
ALTER TABLE public.payment ADD CONSTRAINT CK_payment_paid_at
    CHECK (status <> 'success'::public.payment_status_enum OR paid_at IS NOT NULL);

-- 3.7 Chuẩn hóa các FK trỏ từ bảng con về public.booking sang ON DELETE CASCADE
-- (Phòng trường hợp TypeORM migration trước đó tạo FK với ON DELETE NO ACTION)
DO $$
DECLARE
    v_con RECORD;
BEGIN
    FOR v_con IN
        SELECT c.conname, t.relname AS table_name
        FROM pg_constraint c
        JOIN pg_class t ON c.conrelid = t.oid
        JOIN pg_class r ON c.confrelid = r.oid
        JOIN pg_namespace n ON t.relnamespace = n.oid
        WHERE n.nspname = 'public'
          AND t.relname IN ('booking_detail', 'booking_combo', 'payment')
          AND r.relname = 'booking'
          AND c.contype = 'f'
          AND c.confdeltype <> 'c'
    LOOP
        EXECUTE format('ALTER TABLE public.%I DROP CONSTRAINT %I', v_con.table_name, v_con.conname);
        EXECUTE format(
            'ALTER TABLE public.%I ADD CONSTRAINT %I FOREIGN KEY (booking_id) REFERENCES public.booking(id) ON DELETE CASCADE',
            v_con.table_name,
            'FK_' || v_con.table_name || '_booking'
        );
    END LOOP;
END $$;


-- =============================================================================
-- 4. CHỈ MỤC TỐI ƯU HÓA TRUY VẤN (INDEXES)
-- =============================================================================

CREATE INDEX IF NOT EXISTS IDX_combo_category ON public.combo(category);
CREATE INDEX IF NOT EXISTS IDX_promotion_code ON public.promotion(code);
CREATE INDEX IF NOT EXISTS IDX_promotion_active_dates ON public.promotion(is_active, start_date, end_date);
CREATE INDEX IF NOT EXISTS IDX_booking_user_id ON public.booking(user_id);
CREATE INDEX IF NOT EXISTS IDX_booking_showtime_id ON public.booking(showtime_id);
CREATE INDEX IF NOT EXISTS IDX_booking_status ON public.booking(status);
CREATE INDEX IF NOT EXISTS IDX_booking_detail_booking_id ON public.booking_detail(booking_id);
CREATE INDEX IF NOT EXISTS IDX_booking_detail_seat_id ON public.booking_detail(seat_id);
CREATE INDEX IF NOT EXISTS IDX_booking_combo_booking_id ON public.booking_combo(booking_id);
CREATE INDEX IF NOT EXISTS IDX_booking_combo_combo_id ON public.booking_combo(combo_id);
CREATE INDEX IF NOT EXISTS IDX_payment_booking_id ON public.payment(booking_id);
CREATE INDEX IF NOT EXISTS IDX_payment_status ON public.payment(status);
