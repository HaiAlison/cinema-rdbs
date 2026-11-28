-- =============================================================================
-- BÀI TẬP LỚN 2 - HỆ CƠ SỞ DỮ LIỆU (HK261)
-- MODULE 5: BOOKING, COMBO & PAYMENT (THÀNH VIÊN 5)
-- FILE: 05_booking_module_functions.sql
-- YÊU CẦU: Mục 2.4 - Viết 2 Functions có IF/LOOP, CURSOR tường minh, truy vấn
--          dữ liệu tính toán và validate tham số đầu vào.
-- =============================================================================

SET client_encoding = 'UTF8';

-- -----------------------------------------------------------------------------
-- 2.4.1 HÀM 1: KIỂM TOÁN HIỆU QUẢ CHIẾT KHẤU & DOANH THU RÒNG MÃ KHUYẾN MÃI
-- (fn_audit_promotion_discount_impact)
-- Sử dụng CURSOR duyệt từng đơn áp dụng khuyến mãi, LOOP + IF tách biệt đơn đã
-- thanh toán ('confirmed') với đơn đang giữ chỗ ('pending') để tính doanh thu thực.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_audit_promotion_discount_impact(
    p_promotion_id UUID,
    p_min_booking_amount NUMERIC DEFAULT 0
)
RETURNS TABLE (
    promotion_code VARCHAR(100),
    confirmed_bookings_count INT,
    pending_bookings_count INT,
    total_gross_amount NUMERIC(14,2),
    total_discount_given NUMERIC(14,2),
    total_net_collected NUMERIC(14,2),
    audit_summary TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    cur_promo_bookings CURSOR FOR
        SELECT b.id, b.booking_code, b.ticket_total, b.combo_total,
               b.discount_amount, b.final_amount, b.status
        FROM public.booking b
        WHERE b.promotion_id = p_promotion_id
          AND b.deleted_at IS NULL
          AND (b.ticket_total + b.combo_total) >= COALESCE(p_min_booking_amount, 0);

    v_rec RECORD;
    v_promo_code VARCHAR(100);
    v_confirmed_cnt INT := 0;
    v_pending_cnt INT := 0;
    v_gross NUMERIC(14,2) := 0;
    v_discount NUMERIC(14,2) := 0;
    v_net NUMERIC(14,2) := 0;
BEGIN
    -- 1. Validate tham số đầu vào
    IF p_promotion_id IS NULL THEN
        RAISE EXCEPTION 'Lỗi tham số: Mã chương trình khuyến mãi (p_promotion_id) không được để NULL!';
    END IF;

    IF COALESCE(p_min_booking_amount, 0) < 0 THEN
        RAISE EXCEPTION 'Lỗi tham số: Ngưỡng giá trị đơn hàng tối thiểu không được âm (Giá trị: %)!', p_min_booking_amount;
    END IF;

    SELECT code INTO v_promo_code
    FROM public.promotion
    WHERE id = p_promotion_id AND deleted_at IS NULL;

    IF v_promo_code IS NULL THEN
        RAISE EXCEPTION 'Không tìm thấy: Chương trình khuyến mãi ID "%" không tồn tại trong hệ thống!', p_promotion_id;
    END IF;

    -- 2. Mở CURSOR và duyệt qua từng đơn bằng LOOP + IF
    OPEN cur_promo_bookings;
    LOOP
        FETCH cur_promo_bookings INTO v_rec;
        EXIT WHEN NOT FOUND;

        IF v_rec.status = 'confirmed' THEN
            v_confirmed_cnt := v_confirmed_cnt + 1;
            v_gross := v_gross + (v_rec.ticket_total + v_rec.combo_total);
            v_discount := v_discount + v_rec.discount_amount;
            v_net := v_net + v_rec.final_amount;
        ELSIF v_rec.status = 'pending' THEN
            v_pending_cnt := v_pending_cnt + 1;
        END IF;
    END LOOP;
    CLOSE cur_promo_bookings;

    -- 3. Trả về bảng kết quả
    promotion_code := v_promo_code;
    confirmed_bookings_count := v_confirmed_cnt;
    pending_bookings_count := v_pending_cnt;
    total_gross_amount := v_gross;
    total_discount_given := v_discount;
    total_net_collected := v_net;
    audit_summary := format(
        'Khuyến mãi %s: %s đơn đã thanh toán (%s đơn đang chờ), Tổng giảm: %s VNĐ, Doanh thu thực thu: %s VNĐ',
        v_promo_code, v_confirmed_cnt, v_pending_cnt, v_discount, v_net
    );

    RETURN NEXT;
END;
$$;


-- -----------------------------------------------------------------------------
-- 2.4.2 HÀM 2: ĐỐI SOÁT TÀI CHÍNH TỔNG TIỀN ĐẶT VÉ VÀ THANH TOÁN THEO NGÀY
-- (fn_reconcile_daily_booking_payments)
-- Sử dụng CURSOR duyệt các đơn đặt vé theo ngày (múi giờ Asia/Ho_Chi_Minh),
-- đối chiếu số tiền phải thu trên BOOKING với tổng tiền giao dịch ở PAYMENT.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_reconcile_daily_booking_payments(
    p_check_date DATE,
    p_tolerance NUMERIC DEFAULT 0.01
)
RETURNS TABLE (
    reconcile_date DATE,
    total_orders INT,
    balanced_orders INT,
    unbalanced_orders INT,
    total_expected_revenue NUMERIC(14,2),
    total_actual_paid NUMERIC(14,2),
    reconcile_notes TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    cur_daily_bookings CURSOR FOR
        SELECT b.id, b.booking_code, b.final_amount, b.status
        FROM public.booking b
        WHERE b.deleted_at IS NULL
          AND DATE(b.created_at AT TIME ZONE 'Asia/Ho_Chi_Minh') = p_check_date;

    v_rec RECORD;
    v_paid_sum NUMERIC(14,2);
    v_refunded_sum NUMERIC(14,2);
    v_diff NUMERIC(14,2);

    v_total_cnt INT := 0;
    v_balanced_cnt INT := 0;
    v_unbalanced_cnt INT := 0;
    v_exp_rev NUMERIC(14,2) := 0;
    v_act_rev NUMERIC(14,2) := 0;
BEGIN
    -- 1. Validate tham số
    IF p_check_date IS NULL THEN
        RAISE EXCEPTION 'Lỗi tham số: Ngày đối soát kiểm toán (p_check_date) không được để trống!';
    END IF;

    IF COALESCE(p_tolerance, 0) < 0 THEN
        RAISE EXCEPTION 'Lỗi tham số: Sai số cho phép (p_tolerance) không được âm (Giá trị: %)!', p_tolerance;
    END IF;

    -- 2. Mở CURSOR và xử lý LOOP / IF
    OPEN cur_daily_bookings;
    LOOP
        FETCH cur_daily_bookings INTO v_rec;
        EXIT WHEN NOT FOUND;

        v_total_cnt := v_total_cnt + 1;

        SELECT
            COALESCE(SUM(CASE WHEN status = 'success' THEN amount ELSE 0 END), 0),
            COALESCE(SUM(CASE WHEN status = 'refunded' THEN amount ELSE 0 END), 0)
        INTO v_paid_sum, v_refunded_sum
        FROM public.payment
        WHERE booking_id = v_rec.id AND deleted_at IS NULL;

        IF v_rec.status = 'confirmed' THEN
            v_exp_rev := v_exp_rev + v_rec.final_amount;
            v_act_rev := v_act_rev + v_paid_sum;
            v_diff := ABS(v_rec.final_amount - v_paid_sum);

            IF v_diff <= COALESCE(p_tolerance, 0.01) THEN
                v_balanced_cnt := v_balanced_cnt + 1;
            ELSE
                v_unbalanced_cnt := v_unbalanced_cnt + 1;
            END IF;
        ELSIF v_rec.status IN ('pending', 'cancelled', 'expired') THEN
            IF v_paid_sum = 0 THEN
                v_balanced_cnt := v_balanced_cnt + 1;
            ELSE
                v_unbalanced_cnt := v_unbalanced_cnt + 1;
            END IF;
        ELSIF v_rec.status = 'refunded' THEN
            IF v_paid_sum = 0 AND v_refunded_sum > 0 THEN
                v_balanced_cnt := v_balanced_cnt + 1;
            ELSE
                v_unbalanced_cnt := v_unbalanced_cnt + 1;
            END IF;
        END IF;
    END LOOP;
    CLOSE cur_daily_bookings;

    -- 3. Trả về kết quả đối soát
    reconcile_date := p_check_date;
    total_orders := v_total_cnt;
    balanced_orders := v_balanced_cnt;
    unbalanced_orders := v_unbalanced_cnt;
    total_expected_revenue := v_exp_rev;
    total_actual_paid := v_act_rev;

    IF v_total_cnt = 0 THEN
        reconcile_notes := format('Ngày %s không ghi nhận đơn đặt vé nào.', p_check_date);
    ELSIF v_unbalanced_cnt = 0 THEN
        reconcile_notes := format('Đối soát hoàn hảo: 100%% (%s/%s) đơn vé khớp số liệu tài chính.', v_balanced_cnt, v_total_cnt);
    ELSE
        reconcile_notes := format('Cảnh báo: Có %s/%s đơn vé bị lệch dòng tiền giữa booking và payment!', v_unbalanced_cnt, v_total_cnt);
    END IF;

    RETURN NEXT;
END;
$$;
