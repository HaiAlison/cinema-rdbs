-- =============================================================================
-- BTL2 - DATABASE SYSTEMS
-- MODULE 1: USERS & MEMBERSHIP (MODULE MẪU)
-- FILE: 05_user_module_functions.sql
-- YÊU CẦU: Mục 2.4 (Viết 2 Functions thỏa mãn: IF/LOOP, dùng CURSOR, 
--                    truy vấn dữ liệu để tính toán, validate tham số đầu vào)
-- =============================================================================

-- =============================================================================
-- FUNCTION 1: TÍNH % ƯU ĐÃI KHÁCH HÀNG THÂN THIẾT DỰA TRÊN LỊCH SỬ ĐẶT VÉ
-- Input: p_user_id (UUID)
-- Logic: Dùng CURSOR duyệt qua 10 đơn đặt vé gần nhất, LOOP tính tổng chi tiêu
--        và số lượng vé xem phim, áp dụng IF để xác định % voucher tặng kèm.
-- =============================================================================
CREATE OR REPLACE FUNCTION fn_calculate_user_loyalty_voucher(
    p_user_id UUID
)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    -- 1. Khai báo Cursor truy vấn danh sách 10 đơn đặt vé thành công gần nhất
    cur_recent_bookings CURSOR FOR
        SELECT b.id, b.final_amount, b.created_at
        FROM "booking" b
        WHERE b.user_id = p_user_id
          AND b.status = 'confirmed'
        ORDER BY b.created_at DESC
        LIMIT 10;

    v_booking_rec RECORD;
    v_total_spending NUMERIC := 0;
    v_booking_count INT := 0;
    v_discount_percent NUMERIC := 0;
BEGIN
    -- 2. Validate tham số đầu vào
    IF p_user_id IS NULL THEN
        RAISE EXCEPTION 'Lỗi tham số: p_user_id không được để trống (NULL)!';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM "users" WHERE "id" = p_user_id AND "deleted_at" IS NULL) THEN
        RAISE EXCEPTION 'Lỗi dữ liệu: Khách hàng với ID "%" không tồn tại trong hệ thống!', p_user_id;
    END IF;

    -- 3. Mở cursor và duyệt dữ liệu bằng LOOP
    OPEN cur_recent_bookings;
    LOOP
        FETCH cur_recent_bookings INTO v_booking_rec;
        EXIT WHEN NOT FOUND; -- Kết thúc khi hết dữ liệu

        v_booking_count := v_booking_count + 1;
        v_total_spending := v_total_spending + COALESCE(v_booking_rec.final_amount, 0);
    END LOOP;
    CLOSE cur_recent_bookings;

    -- 4. Sử dụng khối lệnh IF/ELSE để tính toán giá trị ưu đãi
    IF v_booking_count >= 5 AND v_total_spending >= 1500000 THEN
        v_discount_percent := 20.0; -- Giảm 20%
    ELSIF v_booking_count >= 3 AND v_total_spending >= 800000 THEN
        v_discount_percent := 15.0; -- Giảm 15%
    ELSIF v_booking_count >= 1 AND v_total_spending >= 200000 THEN
        v_discount_percent := 10.0; -- Giảm 10%
    ELSE
        v_discount_percent := 5.0;  -- Khách hàng mới hoặc chi tiêu ít: 5%
    END IF;

    RETURN v_discount_percent;
END;
$$;


-- =============================================================================
-- FUNCTION 2: KIỂM TOÁN VÀ ĐỐI SOÁT LỊCH SỬ TÍCH/ĐỔI ĐIỂM CỦA THẺ HỘI VIÊN
-- Input: p_membership_id (UUID), p_target_year (INT)
-- Logic: Dùng CURSOR duyệt tuần tự từng giao dịch điểm theo thời gian trong năm,
--        dùng LOOP + IF cộng/trừ số dư giả định và so sánh với balance_after 
--        để phát hiện chênh lệch (nếu có). Trả về số lần phát hiện sai lệch.
-- =============================================================================
CREATE OR REPLACE FUNCTION fn_audit_user_point_history(
    p_membership_id UUID,
    p_target_year INT
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    -- Khai báo Cursor lấy lịch sử giao dịch điểm trong năm được chỉ định
    cur_point_tx CURSOR FOR
        SELECT pt.id, pt.type, pt.points, pt.balance_after, pt.created_at
        FROM "point_transaction" pt
        WHERE pt.membership_id = p_membership_id
          AND EXTRACT(YEAR FROM pt.created_at) = p_target_year
        ORDER BY pt.created_at ASC;

    v_tx_rec RECORD;
    v_simulated_balance INT := 0;
    v_error_count INT := 0;
BEGIN
    -- 1. Validate tham số
    IF p_membership_id IS NULL THEN
        RAISE EXCEPTION 'Lỗi tham số: p_membership_id không được để trống!';
    END IF;

    IF p_target_year IS NULL OR p_target_year < 2000 OR p_target_year > EXTRACT(YEAR FROM CURRENT_DATE) THEN
        RAISE EXCEPTION 'Lỗi tham số: Năm kiểm toán % không hợp lệ!', p_target_year;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM "membership" WHERE "id" = p_membership_id) THEN
        RAISE EXCEPTION 'Lỗi dữ liệu: Thẻ hội viên ID "%" không tồn tại!', p_membership_id;
    END IF;

    -- 2. Duyệt qua CURSOR với vòng lặp LOOP
    OPEN cur_point_tx;
    LOOP
        FETCH cur_point_tx INTO v_tx_rec;
        EXIT WHEN NOT FOUND;

        -- Sử dụng cấu trúc IF để tính toán theo từng loại giao dịch
        IF v_tx_rec.type IN ('earn', 'bonus') THEN
            v_simulated_balance := v_simulated_balance + ABS(v_tx_rec.points);
        ELSIF v_tx_rec.type = 'redeem' THEN
            v_simulated_balance := v_simulated_balance - ABS(v_tx_rec.points);
        END IF;

        -- Kiểm tra nếu số dư tính toán sai khác với số dư ghi nhận (balance_after)
        IF v_tx_rec.balance_after IS NOT NULL AND v_simulated_balance != v_tx_rec.balance_after THEN
            v_error_count := v_error_count + 1;
        END IF;
    END LOOP;
    CLOSE cur_point_tx;

    -- Trả về số lượng lỗi lệch điểm phát hiện được
    RETURN v_error_count;
END;
$$;
