-- =============================================================================
-- BÀI TẬP LỚN 2 - HỆ CƠ SỞ DỮ LIỆU (HK261)
-- MODULE 5: BOOKING, COMBO & PAYMENT (THÀNH VIÊN 5)
-- FILE: 03_booking_module_procedures.sql
-- YÊU CẦU: Mục 2.1 (CRUD Procedures cho bảng booking) & Mục 2.3 (Query Procedures)
-- =============================================================================

SET client_encoding = 'UTF8';

-- =============================================================================
-- MỤC 2.1 (1.0 ĐIỂM): STORED PROCEDURES INSERT / UPDATE / DELETE CHO BẢNG BOOKING
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 2.1.1 THỦ TỤC THÊM MỚI ĐƠN ĐẶT VÉ (sp_insert_booking)
-- Kiểm tra đầy đủ: mã đơn duy nhất, user hợp lệ & active, suất chiếu hợp lệ,
-- số tiền >= 0, điểm sử dụng <= số dư cgv_points, khuyến mãi hợp lệ & tự tính/kiểm
-- tra mức giảm giá, cuối cùng tính final_amount & points_earned an toàn.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE public.sp_insert_booking(
    p_booking_code VARCHAR(50),
    p_user_id UUID,
    p_showtime_id UUID,
    p_ticket_total NUMERIC,
    p_combo_total NUMERIC DEFAULT 0,
    p_discount_amount NUMERIC DEFAULT 0,
    p_promotion_id UUID DEFAULT NULL,
    p_points_used INT DEFAULT 0,
    INOUT p_new_booking_id UUID DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_active BOOLEAN;
    v_user_name VARCHAR(100);
    v_user_points INT := 0;
    v_membership_active BOOLEAN;
    v_showtime_active BOOLEAN;
    v_showtime_status public.showtime_status_enum;
    v_showtime_start TIMESTAMPTZ;
    v_promo_active BOOLEAN;
    v_promo_start TIMESTAMPTZ;
    v_promo_end TIMESTAMPTZ;
    v_promo_min_order NUMERIC;
    v_promo_type public.promotion_type_enum;
    v_promo_val NUMERIC;
    v_promo_max_discount NUMERIC;
    v_promo_usage_limit INT;
    v_promo_used_count INT;
    v_promo_per_user_limit INT;
    v_user_promo_uses INT := 0;
    v_gross_total NUMERIC(12,2);
    v_effective_discount NUMERIC(12,2) := 0;
    v_max_allowed_discount NUMERIC(12,2);
    v_calculated_final NUMERIC(12,2);
BEGIN
    -- 1. Validate mã đặt vé
    IF p_booking_code IS NULL OR length(trim(p_booking_code)) < 3 THEN
        RAISE EXCEPTION 'Lỗi nhập liệu: Mã đặt vé không được để trống và phải có ít nhất 3 ký tự!';
    END IF;

    IF EXISTS (SELECT 1 FROM public.booking WHERE booking_code = trim(p_booking_code)) THEN
        RAISE EXCEPTION 'Lỗi trùng lặp: Mã đặt vé "%" đã tồn tại trên hệ thống, vui lòng chọn mã khác!', p_booking_code;
    END IF;

    -- 2. Validate Khách hàng (User)
    IF p_user_id IS NULL THEN
        RAISE EXCEPTION 'Lỗi nhập liệu: ID khách hàng (p_user_id) không được để trống!';
    END IF;

    SELECT is_active, name INTO v_user_active, v_user_name
    FROM public.users
    WHERE id = p_user_id AND deleted_at IS NULL;

    IF v_user_name IS NULL THEN
        RAISE EXCEPTION 'Không tìm thấy: Khách hàng với ID "%" không tồn tại hoặc đã bị xóa!', p_user_id;
    END IF;

    IF v_user_active IS FALSE THEN
        RAISE EXCEPTION 'Tài khoản bị khóa: Khách hàng "%" (ID: %) hiện đang bị vô hiệu hóa, không thể tạo đơn đặt vé!', v_user_name, p_user_id;
    END IF;

    -- 3. Validate các khoản tiền & điểm sử dụng (kiểm tra trước dữ liệu thời gian suất chiếu)
    IF p_ticket_total IS NULL OR p_ticket_total < 0 THEN
        RAISE EXCEPTION 'Lỗi số tiền: Tổng tiền vé không được nhỏ hơn 0 (Giá trị nhập: %)!', p_ticket_total;
    END IF;

    IF COALESCE(p_combo_total, 0) < 0 THEN
        RAISE EXCEPTION 'Lỗi số tiền: Tổng tiền combo bắp nước không được âm (Giá trị nhập: %)!', p_combo_total;
    END IF;

    IF COALESCE(p_discount_amount, 0) < 0 THEN
        RAISE EXCEPTION 'Lỗi số tiền: Số tiền giảm giá không được âm (Giá trị nhập: %)!', p_discount_amount;
    END IF;

    IF COALESCE(p_points_used, 0) < 0 THEN
        RAISE EXCEPTION 'Lỗi điểm thưởng: Số điểm sử dụng không được âm (Giá trị nhập: %)!', p_points_used;
    END IF;

    -- 4. Validate Suất chiếu (Showtime)
    IF p_showtime_id IS NULL THEN
        RAISE EXCEPTION 'Lỗi nhập liệu: ID suất chiếu (p_showtime_id) không được để trống!';
    END IF;

    SELECT is_active, status, start_time
    INTO v_showtime_active, v_showtime_status, v_showtime_start
    FROM public.showtime
    WHERE id = p_showtime_id AND deleted_at IS NULL;

    IF v_showtime_start IS NULL THEN
        RAISE EXCEPTION 'Không tìm thấy: Suất chiếu với ID "%" không tồn tại!', p_showtime_id;
    END IF;

    IF v_showtime_active IS FALSE OR v_showtime_status IN ('cancelled', 'ended') THEN
        RAISE EXCEPTION 'Suất chiếu không khả dụng: Suất chiếu "%" đã kết thúc hoặc bị hủy (trạng thái: %)!', p_showtime_id, v_showtime_status;
    END IF;

    IF v_showtime_start < now() THEN
        RAISE EXCEPTION 'Lỗi thời gian: Không thể đặt vé cho suất chiếu đã diễn ra trong quá khứ (Thời gian chiếu: %)!', v_showtime_start;
    END IF;

    v_gross_total := p_ticket_total + COALESCE(p_combo_total, 0);

    -- Kiểm tra số dư điểm trong thẻ hội viên nếu khách dùng điểm đổi tiền
    IF COALESCE(p_points_used, 0) > 0 THEN
        SELECT cgv_points, is_active INTO v_user_points, v_membership_active
        FROM public.membership
        WHERE user_id = p_user_id AND deleted_at IS NULL;

        IF v_membership_active IS NULL THEN
            RAISE EXCEPTION 'Lỗi hội viên: Khách hàng "%" chưa có thẻ thành viên để sử dụng CGV Points!', v_user_name;
        END IF;

        IF v_membership_active IS FALSE THEN
            RAISE EXCEPTION 'Lỗi hội viên: Thẻ thành viên của khách hàng "%" hiện đang bị khóa!', v_user_name;
        END IF;

        IF p_points_used > v_user_points THEN
            RAISE EXCEPTION 'Không đủ điểm: Khách hàng "%" chỉ có % điểm, không thể sử dụng % điểm!',
                v_user_name, v_user_points, p_points_used;
        END IF;
    END IF;

    -- 5. Validate Mã khuyến mãi & Tính giảm giá
    IF p_promotion_id IS NOT NULL THEN
        SELECT is_active, start_date, end_date, min_order_amount,
               type, discount_value, max_discount_amount,
               usage_limit, used_count, per_user_limit
        INTO v_promo_active, v_promo_start, v_promo_end, v_promo_min_order,
             v_promo_type, v_promo_val, v_promo_max_discount,
             v_promo_usage_limit, v_promo_used_count, v_promo_per_user_limit
        FROM public.promotion
        WHERE id = p_promotion_id AND deleted_at IS NULL;

        IF v_promo_active IS NULL THEN
            RAISE EXCEPTION 'Không tìm thấy: Mã khuyến mãi với ID "%" không tồn tại!', p_promotion_id;
        END IF;

        IF v_promo_active IS FALSE THEN
            RAISE EXCEPTION 'Khuyến mãi không hợp lệ: Chương trình khuyến mãi này hiện đang tạm ngưng!';
        END IF;

        IF now() < v_promo_start OR now() > v_promo_end THEN
            RAISE EXCEPTION 'Hết hiệu lực: Mã khuyến mãi chỉ áp dụng từ % đến %!', v_promo_start, v_promo_end;
        END IF;

        IF v_promo_usage_limit IS NOT NULL AND v_promo_used_count >= v_promo_usage_limit THEN
            RAISE EXCEPTION 'Hết lượt sử dụng: Chương trình khuyến mãi đã đạt giới hạn %/% lượt!', v_promo_used_count, v_promo_usage_limit;
        END IF;

        IF v_promo_per_user_limit IS NOT NULL THEN
            SELECT COUNT(*) INTO v_user_promo_uses
            FROM public.booking
            WHERE user_id = p_user_id
              AND promotion_id = p_promotion_id
              AND status IN ('pending', 'confirmed')
              AND deleted_at IS NULL;

            IF v_user_promo_uses >= v_promo_per_user_limit THEN
                RAISE EXCEPTION 'Vượt giới hạn cá nhân: Khách hàng "%" đã sử dụng mã khuyến mãi này %/% lần cho phép!',
                    v_user_name, v_user_promo_uses, v_promo_per_user_limit;
            END IF;
        END IF;

        IF v_gross_total < COALESCE(v_promo_min_order, 0) THEN
            RAISE EXCEPTION 'Chưa đạt đơn tối thiểu: Tổng đơn (% VNĐ) chưa đạt mức tối thiểu % VNĐ để áp dụng khuyến mãi!',
                v_gross_total, v_promo_min_order;
        END IF;

        -- Tính mức giảm tối đa theo loại khuyến mãi
        IF v_promo_type = 'percentage' THEN
            v_max_allowed_discount := ROUND(v_gross_total * (v_promo_val / 100.0), 2);
            IF v_promo_max_discount IS NOT NULL AND v_max_allowed_discount > v_promo_max_discount THEN
                v_max_allowed_discount := v_promo_max_discount;
            END IF;
        ELSIF v_promo_type = 'fixed_amount' THEN
            v_max_allowed_discount := LEAST(v_gross_total, v_promo_val);
        ELSE
            v_max_allowed_discount := v_gross_total;
        END IF;

        IF COALESCE(p_discount_amount, 0) = 0 THEN
            v_effective_discount := v_max_allowed_discount;
        ELSIF p_discount_amount > v_max_allowed_discount THEN
            RAISE EXCEPTION 'Giảm giá vượt trần: Số tiền giảm nhập (% VNĐ) vượt quá mức tối đa cho phép của mã khuyến mãi (% VNĐ)!',
                p_discount_amount, v_max_allowed_discount;
        ELSE
            v_effective_discount := p_discount_amount;
        END IF;
    ELSE
        IF COALESCE(p_discount_amount, 0) > 0 THEN
            RAISE EXCEPTION 'Lỗi chiết khấu: Không thể nhập số tiền giảm giá (% VNĐ) khi không áp dụng mã khuyến mãi!',
                p_discount_amount;
        END IF;
        v_effective_discount := 0;
    END IF;

    -- 6. Tính toán final_amount an toàn
    v_calculated_final := GREATEST(
        0,
        v_gross_total - v_effective_discount - (COALESCE(p_points_used, 0) * 1000)
    );

    -- 7. Thực hiện INSERT
    p_new_booking_id := COALESCE(p_new_booking_id, public.uuid_generate_v4());

    INSERT INTO public.booking (
        id, created_at, updated_at, booking_code, user_id, showtime_id,
        ticket_total, combo_total, discount_amount, final_amount,
        promotion_id, status, expired_at, points_earned, points_used
    ) VALUES (
        p_new_booking_id,
        now(),
        now(),
        trim(p_booking_code),
        p_user_id,
        p_showtime_id,
        p_ticket_total,
        COALESCE(p_combo_total, 0),
        v_effective_discount,
        v_calculated_final,
        p_promotion_id,
        'pending'::public.booking_status_enum,
        now() + INTERVAL '15 minutes',
        FLOOR(v_calculated_final * 0.05 / 1000),
        COALESCE(p_points_used, 0)
    );

    RAISE NOTICE '>>> Thêm mới đơn đặt vé "%" thành công (ID: %, Phải trả: % VNĐ)',
        trim(p_booking_code), p_new_booking_id, v_calculated_final;
END;
$$;


-- -----------------------------------------------------------------------------
-- 2.1.2 THỦ TỤC CẬP NHẬT ĐƠN ĐẶT VÉ (sp_update_booking)
-- Hỗ trợ cập nhật trạng thái, khuyến mãi, số tiền giảm giá, điểm sử dụng và hạn giữ chỗ.
-- Ràng buộc:
--   - Chỉ cho phép sửa promotion/discount/points/expired_at khi đơn ở trạng thái 'pending'.
--   - Kiểm soát chuyển đổi trạng thái hợp lệ (State Machine).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE public.sp_update_booking(
    p_booking_id UUID,
    p_status VARCHAR(20) DEFAULT NULL,
    p_promotion_id UUID DEFAULT NULL,
    p_clear_promotion BOOLEAN DEFAULT FALSE,
    p_discount_amount NUMERIC DEFAULT NULL,
    p_points_used INT DEFAULT NULL,
    p_expired_at TIMESTAMPTZ DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_booking RECORD;
    v_target_status public.booking_status_enum;
    v_target_promo_id UUID;
    v_target_discount NUMERIC(12,2);
    v_target_points_used INT;
    v_target_expired_at TIMESTAMPTZ;
    v_gross_total NUMERIC(12,2);
    v_promo_active BOOLEAN;
    v_promo_start TIMESTAMPTZ;
    v_promo_end TIMESTAMPTZ;
    v_promo_min_order NUMERIC;
    v_promo_type public.promotion_type_enum;
    v_promo_val NUMERIC;
    v_promo_max_discount NUMERIC;
    v_max_allowed_discount NUMERIC(12,2);
    v_user_points INT := 0;
    v_new_final NUMERIC(12,2);
    v_new_points_earned INT;
BEGIN
    -- 1. Kiểm tra đơn vé tồn tại
    SELECT * INTO v_booking
    FROM public.booking
    WHERE id = p_booking_id AND deleted_at IS NULL;

    IF v_booking.id IS NULL THEN
        RAISE EXCEPTION 'Không tìm thấy: Đơn đặt vé với ID "%" không tồn tại hoặc đã bị xóa!', p_booking_id;
    END IF;

    -- 2. Kiểm tra chuyển đổi trạng thái (nếu có truyền p_status)
    IF p_status IS NOT NULL AND length(trim(p_status)) > 0 THEN
        BEGIN
            v_target_status := lower(trim(p_status))::public.booking_status_enum;
        EXCEPTION WHEN OTHERS THEN
            RAISE EXCEPTION 'Trạng thái mới "%" không hợp lệ! Giá trị hợp lệ: pending, confirmed, cancelled, expired, refunded.', p_status;
        END;

        IF v_booking.status <> v_target_status THEN
            IF v_booking.status IN ('confirmed', 'cancelled', 'expired', 'refunded') AND v_target_status = 'pending' THEN
                RAISE EXCEPTION 'Chuyển trạng thái không hợp lệ: Không thể đưa đơn vé đã kết thúc ("%") quay lại "pending"!', v_booking.status;
            END IF;

            IF v_booking.status IN ('cancelled', 'expired') AND v_target_status IN ('confirmed', 'refunded') THEN
                RAISE EXCEPTION 'Chuyển trạng thái không hợp lệ: Không thể xác nhận/hoàn tiền cho đơn vé đang ở trạng thái "%"!', v_booking.status;
            END IF;

            IF v_booking.status = 'confirmed' AND v_target_status IN ('cancelled', 'expired') THEN
                RAISE EXCEPTION 'Chính sách không hoàn hủy: Đơn vé "%" đã xác nhận thanh toán ("confirmed"), chỉ có thể chuyển sang "refunded" nếu hoàn tiền!', v_booking.booking_code;
            END IF;

            IF v_booking.status = 'refunded' THEN
                RAISE EXCEPTION 'Đơn vé "%" đã hoàn tiền ("refunded"), không thể thay đổi trạng thái sang "%"!', v_booking.booking_code, v_target_status;
            END IF;
        END IF;
    ELSE
        v_target_status := v_booking.status;
    END IF;

    -- 3. Nếu chỉnh sửa khuyến mãi / giảm giá / điểm / hạn giữ chỗ thì đơn gốc phải đang 'pending'
    IF (p_promotion_id IS NOT NULL OR p_clear_promotion IS TRUE OR p_discount_amount IS NOT NULL
        OR p_points_used IS NOT NULL OR p_expired_at IS NOT NULL)
       AND v_booking.status <> 'pending' THEN
        RAISE EXCEPTION 'Không thể chỉnh sửa chi tiết tài chính: Đơn vé "%" đang ở trạng thái "%", chỉ cho phép chỉnh sửa khi đơn đang "pending"!',
            v_booking.booking_code, v_booking.status;
    END IF;

    v_gross_total := v_booking.ticket_total + v_booking.combo_total;

    -- 4. Xác định khuyến mãi và discount mới
    IF p_clear_promotion IS TRUE THEN
        v_target_promo_id := NULL;
        v_target_discount := 0;
    ELSE
        v_target_promo_id := COALESCE(p_promotion_id, v_booking.promotion_id);
        v_target_discount := COALESCE(p_discount_amount, v_booking.discount_amount);
    END IF;

    IF v_target_discount < 0 THEN
        RAISE EXCEPTION 'Lỗi số tiền: Số tiền giảm giá không được âm (Giá trị: %)!', v_target_discount;
    END IF;

    IF v_target_promo_id IS NOT NULL THEN
        SELECT is_active, start_date, end_date, min_order_amount,
               type, discount_value, max_discount_amount
        INTO v_promo_active, v_promo_start, v_promo_end, v_promo_min_order,
             v_promo_type, v_promo_val, v_promo_max_discount
        FROM public.promotion
        WHERE id = v_target_promo_id AND deleted_at IS NULL;

        IF v_promo_active IS NULL THEN
            RAISE EXCEPTION 'Không tìm thấy: Mã khuyến mãi ID "%" không tồn tại!', v_target_promo_id;
        END IF;

        IF p_promotion_id IS NOT NULL THEN
            IF v_promo_active IS FALSE THEN
                RAISE EXCEPTION 'Khuyến mãi không hợp lệ: Chương trình khuyến mãi đang tạm ngưng áp dụng!';
            END IF;
            IF now() < v_promo_start OR now() > v_promo_end THEN
                RAISE EXCEPTION 'Hết hiệu lực: Mã khuyến mãi chỉ áp dụng từ % đến %!', v_promo_start, v_promo_end;
            END IF;
            IF v_gross_total < COALESCE(v_promo_min_order, 0) THEN
                RAISE EXCEPTION 'Chưa đạt đơn tối thiểu: Tổng đơn (% VNĐ) chưa đạt % VNĐ để áp dụng mã này!',
                    v_gross_total, v_promo_min_order;
            END IF;
        END IF;

        IF v_promo_type = 'percentage' THEN
            v_max_allowed_discount := ROUND(v_gross_total * (v_promo_val / 100.0), 2);
            IF v_promo_max_discount IS NOT NULL AND v_max_allowed_discount > v_promo_max_discount THEN
                v_max_allowed_discount := v_promo_max_discount;
            END IF;
        ELSIF v_promo_type = 'fixed_amount' THEN
            v_max_allowed_discount := LEAST(v_gross_total, v_promo_val);
        ELSE
            v_max_allowed_discount := v_gross_total;
        END IF;

        -- Nếu đổi promotion mới mà không truyền discount_amount mới -> tự tính theo promotion
        IF p_promotion_id IS NOT NULL AND p_discount_amount IS NULL THEN
            v_target_discount := v_max_allowed_discount;
        ELSIF v_target_discount > v_max_allowed_discount THEN
            RAISE EXCEPTION 'Giảm giá vượt trần: Số tiền giảm (% VNĐ) vượt quá mức tối đa của khuyến mãi (% VNĐ)!',
                v_target_discount, v_max_allowed_discount;
        END IF;
    ELSIF v_target_discount > 0 THEN
        RAISE EXCEPTION 'Lỗi chiết khấu: Không thể áp dụng giảm giá (% VNĐ) khi đơn vé không có mã khuyến mãi!', v_target_discount;
    END IF;

    -- 5. Validate điểm sử dụng mới
    v_target_points_used := COALESCE(p_points_used, v_booking.points_used);
    IF v_target_points_used < 0 THEN
        RAISE EXCEPTION 'Lỗi điểm thưởng: Số điểm sử dụng không được âm (Giá trị: %)!', v_target_points_used;
    END IF;

    IF p_points_used IS NOT NULL AND p_points_used > 0 THEN
        SELECT COALESCE(cgv_points, 0) INTO v_user_points
        FROM public.membership
        WHERE user_id = v_booking.user_id AND deleted_at IS NULL;

        IF p_points_used > v_user_points THEN
            RAISE EXCEPTION 'Không đủ điểm: Khách hàng hiện chỉ có % điểm, không thể sử dụng % điểm!',
                v_user_points, p_points_used;
        END IF;
    END IF;

    v_target_expired_at := COALESCE(p_expired_at, v_booking.expired_at);

    -- 6. Tính lại final_amount & points_earned
    v_new_final := GREATEST(0, v_gross_total - v_target_discount - (v_target_points_used * 1000));
    v_new_points_earned := FLOOR(v_new_final * 0.05 / 1000);

    UPDATE public.booking
    SET status = v_target_status,
        promotion_id = v_target_promo_id,
        discount_amount = v_target_discount,
        points_used = v_target_points_used,
        final_amount = v_new_final,
        points_earned = v_new_points_earned,
        expired_at = v_target_expired_at,
        confirmed_at = CASE
            WHEN v_target_status = 'confirmed' AND confirmed_at IS NULL THEN now()
            ELSE confirmed_at
        END,
        updated_at = now()
    WHERE id = p_booking_id;

    RAISE NOTICE '>>> Cập nhật đơn vé "%" thành công (Trạng thái: %, Tổng trả: % VNĐ).',
        v_booking.booking_code, v_target_status, v_new_final;
END;
$$;

-- Giữ lại sp_update_booking_status làm wrapper gọi sang sp_update_booking để tương thích ngược
CREATE OR REPLACE PROCEDURE public.sp_update_booking_status(
    p_booking_id UUID,
    p_new_status VARCHAR(20)
)
LANGUAGE plpgsql
AS $$
BEGIN
    CALL public.sp_update_booking(p_booking_id => p_booking_id, p_status => p_new_status);
END;
$$;


-- -----------------------------------------------------------------------------
-- 2.1.3 THỦ TỤC XÓA ĐƠN ĐẶT VÉ (sp_delete_booking)
-- Quy định nghiệp vụ:
--   * ĐƯỢC PHÉP XÓA:
--     - Đơn ở trạng thái 'pending', 'cancelled', hoặc 'expired' VÀ chưa có giao dịch
--       thanh toán thành công/hoàn tiền trong bảng payment.
--     - Mục đích: Giải phóng ghế giữ chỗ tạm và dọn dẹp dữ liệu rác từ các phiên bỏ dở.
--   * BỊ CẤM XÓA:
--     - Đơn ở trạng thái 'confirmed' hoặc 'refunded', hoặc có payment 'success'/'refunded'.
--     - Lý do: Bảo toàn chứng từ kế toán - thuế, lịch sử đối soát thanh toán và vết kiểm toán.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE public.sp_delete_booking(
    p_booking_id UUID
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_status public.booking_status_enum;
    v_booking_code VARCHAR(50);
    v_has_settled_payment BOOLEAN;
BEGIN
    -- 1. Kiểm tra đơn vé tồn tại
    SELECT status, booking_code INTO v_status, v_booking_code
    FROM public.booking
    WHERE id = p_booking_id AND deleted_at IS NULL;

    IF v_booking_code IS NULL THEN
        RAISE EXCEPTION 'Không tìm thấy: Đơn đặt vé với ID "%" không tồn tại hoặc đã bị xóa!', p_booking_id;
    END IF;

    -- 2. Chặn xóa đơn đã thanh toán hoặc đã hoàn tiền
    IF v_status = 'confirmed' THEN
        RAISE EXCEPTION 'CHÍNH SÁCH BẢO MẬT TÀI CHÍNH TỪ CHỐI: Không được phép xóa đơn vé "%" đã xác nhận thanh toán (confirmed) nhằm đảm bảo số liệu kế toán và lịch sử soát vé!', v_booking_code;
    END IF;

    IF v_status = 'refunded' THEN
        RAISE EXCEPTION 'CHÍNH SÁCH KẾ TOÁN TỪ CHỐI: Không thể xóa đơn vé "%" đã hoàn tiền (refunded) vì cần lưu trữ hồ sơ đối soát!', v_booking_code;
    END IF;

    SELECT EXISTS (
        SELECT 1 FROM public.payment
        WHERE booking_id = p_booking_id AND status IN ('success', 'refunded')
    ) INTO v_has_settled_payment;

    IF v_has_settled_payment THEN
        RAISE EXCEPTION 'Từ chối xóa: Đơn vé "%" có giao dịch thanh toán thành công/hoàn tiền liên kết trong bảng PAYMENT!', v_booking_code;
    END IF;

    -- 3. Xóa tường minh các bản ghi phụ thuộc và xóa đơn vé gốc
    DELETE FROM public.payment WHERE booking_id = p_booking_id;
    DELETE FROM public.booking_combo WHERE booking_id = p_booking_id;
    DELETE FROM public.booking_detail WHERE booking_id = p_booking_id;
    DELETE FROM public.booking WHERE id = p_booking_id;

    RAISE NOTICE '>>> Đã xóa thành công đơn vé "%" (Trạng thái trước khi xóa: %).', v_booking_code, v_status;
END;
$$;


-- =============================================================================
-- MỤC 2.3 (1.0 ĐIỂM): STORED PROCEDURES TRUY VẤN DỮ LIỆU (TRẢ VỀ REFCURSOR)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 2.3.1 THỦ TỤC 1: TRA CỨU & TÌM KIẾM DANH SÁCH ĐƠN ĐẶT VÉ
-- (sp_get_user_booking_history)
-- Kết hợp >= 4 bảng: booking, users, showtime, movie (+ left join promotion)
-- Hỗ trợ lọc theo p_user_id (tùy chọn), p_status_filter, p_search, và sắp xếp ORDER BY.
-- Trả kết quả qua REFCURSOR để NestJS / Application đọc được (Mục 3.2).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE public.sp_get_user_booking_history(
    p_user_id UUID DEFAULT NULL,
    p_status_filter VARCHAR(20) DEFAULT NULL,
    p_search VARCHAR(100) DEFAULT NULL,
    p_sort_by VARCHAR(30) DEFAULT 'created_at',
    p_sort_dir VARCHAR(4) DEFAULT 'DESC',
    INOUT p_refcursor REFCURSOR = 'cur_booking_history'
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_search_pattern VARCHAR(120);
    v_sort_col VARCHAR(30);
    v_sort_order VARCHAR(4);
BEGIN
    IF p_user_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM public.users WHERE id = p_user_id AND deleted_at IS NULL
    ) THEN
        RAISE EXCEPTION 'Không tìm thấy: Khách hàng với ID "%" không tồn tại!', p_user_id;
    END IF;

    IF p_status_filter IS NOT NULL AND length(trim(p_status_filter)) > 0
       AND lower(trim(p_status_filter)) NOT IN ('pending', 'confirmed', 'cancelled', 'expired', 'refunded') THEN
        RAISE EXCEPTION 'Tham số lọc không hợp lệ: Trạng thái "%" phải thuộc (pending, confirmed, cancelled, expired, refunded)!', p_status_filter;
    END IF;

    v_search_pattern := CASE
        WHEN p_search IS NOT NULL AND length(trim(p_search)) > 0 THEN '%' || lower(trim(p_search)) || '%'
        ELSE NULL
    END;

    v_sort_col := COALESCE(lower(trim(p_sort_by)), 'created_at');
    v_sort_order := CASE WHEN upper(trim(COALESCE(p_sort_dir, 'DESC'))) = 'ASC' THEN 'ASC' ELSE 'DESC' END;

    OPEN p_refcursor FOR
        SELECT
            b.id,
            b.booking_code,
            b.user_id,
            u.name AS customer_name,
            u.email AS customer_email,
            u.phone AS customer_phone,
            b.showtime_id,
            m.name AS movie_title,
            st.start_time AS show_time,
            b.promotion_id,
            p.code AS promotion_code,
            b.ticket_total,
            b.combo_total,
            b.discount_amount,
            b.points_used,
            b.points_earned,
            b.final_amount,
            b.status,
            b.expired_at,
            b.confirmed_at,
            b.created_at,
            (
                SELECT COUNT(*)::INT
                FROM public.booking_detail bd
                WHERE bd.booking_id = b.id AND bd.status <> 'cancelled' AND bd.deleted_at IS NULL
            ) AS seat_count
        FROM public.booking b
        INNER JOIN public.users u ON b.user_id = u.id
        INNER JOIN public.showtime st ON b.showtime_id = st.id
        INNER JOIN public.movie m ON st.movie_id = m.id
        LEFT JOIN public.promotion p ON b.promotion_id = p.id
        WHERE b.deleted_at IS NULL
          AND (p_user_id IS NULL OR b.user_id = p_user_id)
          AND (p_status_filter IS NULL OR length(trim(p_status_filter)) = 0 OR b.status::TEXT = lower(trim(p_status_filter)))
          AND (
              v_search_pattern IS NULL
              OR lower(b.booking_code) LIKE v_search_pattern
              OR lower(u.name) LIKE v_search_pattern
              OR lower(u.phone) LIKE v_search_pattern
              OR lower(m.name) LIKE v_search_pattern
          )
        ORDER BY
            CASE WHEN v_sort_col = 'final_amount' AND v_sort_order = 'ASC' THEN b.final_amount END ASC,
            CASE WHEN v_sort_col = 'final_amount' AND v_sort_order = 'DESC' THEN b.final_amount END DESC,
            CASE WHEN v_sort_col = 'booking_code' AND v_sort_order = 'ASC' THEN b.booking_code END ASC,
            CASE WHEN v_sort_col = 'booking_code' AND v_sort_order = 'DESC' THEN b.booking_code END DESC,
            CASE WHEN v_sort_col = 'show_time' AND v_sort_order = 'ASC' THEN st.start_time END ASC,
            CASE WHEN v_sort_col = 'show_time' AND v_sort_order = 'DESC' THEN st.start_time END DESC,
            CASE WHEN v_sort_col = 'created_at' AND v_sort_order = 'ASC' THEN b.created_at END ASC,
            b.created_at DESC;
END;
$$;


-- -----------------------------------------------------------------------------
-- 2.3.2 THỦ TỤC 2: BÁO CÁO DOANH THU THEO SUẤT CHIẾU & PHIM
-- (sp_report_showtime_revenue)
-- Kết hợp 5 bảng: showtime, movie, room, cinema, booking
-- Đầy đủ: COUNT, SUM, AVG cùng WHERE, GROUP BY, HAVING, ORDER BY.
-- Trả kết quả qua REFCURSOR để hiển thị lên màn hình báo cáo (Mục 3.3).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE public.sp_report_showtime_revenue(
    p_from_date TIMESTAMPTZ DEFAULT NULL,
    p_to_date TIMESTAMPTZ DEFAULT NULL,
    p_min_revenue NUMERIC DEFAULT 0,
    p_movie_name VARCHAR(100) DEFAULT NULL,
    INOUT p_refcursor REFCURSOR = 'cur_showtime_revenue'
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_from TIMESTAMPTZ := COALESCE(p_from_date, '2020-01-01 00:00:00+07'::TIMESTAMPTZ);
    v_to TIMESTAMPTZ := COALESCE(p_to_date, '2099-12-31 23:59:59+07'::TIMESTAMPTZ);
BEGIN
    IF v_from > v_to THEN
        RAISE EXCEPTION 'Lỗi khoảng ngày: Thời điểm bắt đầu (%) không được lớn hơn thời điểm kết thúc (%)!', v_from, v_to;
    END IF;

    IF COALESCE(p_min_revenue, 0) < 0 THEN
        RAISE EXCEPTION 'Lỗi tham số: Ngưỡng doanh thu tối thiểu (p_min_revenue) không được âm!';
    END IF;

    OPEN p_refcursor FOR
        SELECT
            st.id AS showtime_id,
            m.name AS movie_title,
            c.name AS cinema_name,
            r.name AS room_name,
            st.start_time,
            COUNT(b.id)::INT AS total_bookings,
            COALESCE(SUM(b.ticket_total), 0)::NUMERIC(14,2) AS total_ticket_revenue,
            COALESCE(SUM(b.combo_total), 0)::NUMERIC(14,2) AS total_combo_revenue,
            COALESCE(SUM(b.discount_amount), 0)::NUMERIC(14,2) AS total_discount,
            COALESCE(SUM(b.final_amount), 0)::NUMERIC(14,2) AS total_revenue,
            ROUND(COALESCE(AVG(b.final_amount), 0), 2)::NUMERIC(14,2) AS avg_order_value
        FROM public.showtime st
        INNER JOIN public.movie m ON st.movie_id = m.id
        INNER JOIN public.room r ON st.room_id = r.id
        INNER JOIN public.cinema c ON r.cinema_id = c.id
        INNER JOIN public.booking b ON st.id = b.showtime_id
        WHERE b.status = 'confirmed'
          AND b.deleted_at IS NULL
          AND st.start_time >= v_from
          AND st.start_time <= v_to
          AND (p_movie_name IS NULL OR length(trim(p_movie_name)) = 0 OR m.name ILIKE '%' || trim(p_movie_name) || '%')
        GROUP BY st.id, m.name, c.name, r.name, st.start_time
        HAVING COALESCE(SUM(b.final_amount), 0) >= COALESCE(p_min_revenue, 0)
        ORDER BY total_revenue DESC, st.start_time ASC;
END;
$$;
