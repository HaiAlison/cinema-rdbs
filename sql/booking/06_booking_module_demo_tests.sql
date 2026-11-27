-- =============================================================================
-- BÀI TẬP LỚN 2 - HỆ CƠ SỞ DỮ LIỆU (HK261)
-- MODULE 5: BOOKING, COMBO & PAYMENT (THÀNH VIÊN 5)
-- FILE: 06_booking_module_demo_tests.sql
-- YÊU CẦU: Kịch bản kiểm thử & trình diễn trực tiếp khi báo cáo
-- =============================================================================

SET client_encoding = 'UTF8';

-- =============================================================================
-- 1. DEMO MỤC 2.1: STORED PROCEDURES (INSERT, UPDATE, DELETE)
-- =============================================================================

-- Test 1.1: INSERT thành công đơn đặt vé mới (tự động tính giảm giá theo mã NEWUSER50K)
DO $$
DECLARE
    v_new_id UUID;
    v_code VARCHAR(50) := 'DEMO_' || to_char(now(), 'HH24MISS');
    v_showtime_id UUID;
    v_temp_showtime_created BOOLEAN := FALSE;
BEGIN
    RAISE NOTICE '--- TEST 1.1: Gọi sp_insert_booking tạo đơn mới ---';
    -- Tìm một suất chiếu tương lai (nếu dump chỉ có suất quá khứ thì tạo tạm 1 suất để test rồi dọn)
    SELECT id INTO v_showtime_id
    FROM public.showtime
    WHERE deleted_at IS NULL AND is_active = true AND status NOT IN ('cancelled', 'ended') AND start_time > now()
    LIMIT 1;

    IF v_showtime_id IS NULL THEN
        INSERT INTO public.showtime (movie_id, room_id, start_time, end_time, language, subtitle_type, status, base_price, is_active)
        SELECT movie_id, room_id, now() + INTERVAL '3 days', now() + INTERVAL '3 days 2 hours', language, subtitle_type, 'open', base_price, true
        FROM public.showtime
        WHERE id = '90359f2d-ff72-4a20-9118-c2601fa82aad'
        RETURNING id INTO v_showtime_id;
        v_temp_showtime_created := TRUE;
    END IF;

    CALL public.sp_insert_booking(
        p_booking_code    => v_code,
        p_user_id         => 'bb656c14-68e8-4803-a80e-b2ac4e8804a9',
        p_showtime_id     => v_showtime_id,
        p_ticket_total    => 200000.00,
        p_combo_total     => 89000.00,
        p_discount_amount => 0,
        p_promotion_id    => 'b5e7c943-91b6-4f4a-9846-a92fef15a242',
        p_points_used     => 0,
        p_new_booking_id  => v_new_id
    );
    RAISE NOTICE '>>> Tạo đơn thành công ID: %', v_new_id;

    -- Dọn dẹp đơn vừa tạo (và suất chiếu tạm nếu có) để giữ sạch data demo
    CALL public.sp_delete_booking(v_new_id);
    IF v_temp_showtime_created THEN
        DELETE FROM public.showtime WHERE id = v_showtime_id;
    END IF;
END $$;

-- Test 1.2: INSERT thất bại do tiền vé âm
DO $$
DECLARE
    v_dummy UUID;
BEGIN
    RAISE NOTICE '--- TEST 1.2: Thử sp_insert_booking với tiền vé âm (-50,000đ) ---';
    CALL public.sp_insert_booking(
        p_booking_code    => 'TEST_NEGATIVE',
        p_user_id         => 'bb656c14-68e8-4803-a80e-b2ac4e8804a9',
        p_showtime_id     => '90359f2d-ff72-4a20-9118-c2601fa82aad',
        p_ticket_total    => -50000.00,
        p_combo_total     => 0,
        p_discount_amount => 0,
        p_promotion_id    => NULL,
        p_points_used     => 0,
        p_new_booking_id  => v_dummy
    );
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '>>> THÀNH CÔNG (Bị chặn): %', SQLERRM;
END $$;

-- Test 1.3: UPDATE thất bại khi chuyển đơn đã confirmed sang cancelled
DO $$
BEGIN
    RAISE NOTICE '--- TEST 1.3: Thử sp_update_booking chuyển đơn confirmed sang cancelled ---';
    CALL public.sp_update_booking(
        p_booking_id => '8993f8f5-9255-471f-b9c5-d0daaf04fdf5',
        p_status     => 'cancelled'
    );
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '>>> THÀNH CÔNG (Bị chặn): %', SQLERRM;
END $$;

-- Test 1.4: DELETE bị cấm khi đơn vé đã thanh toán (confirmed)
DO $$
BEGIN
    RAISE NOTICE '--- TEST 1.4: Thử sp_delete_booking xóa đơn confirmed CGV2026000001 ---';
    CALL public.sp_delete_booking(
        p_booking_id => '8993f8f5-9255-471f-b9c5-d0daaf04fdf5'
    );
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '>>> THÀNH CÔNG (Bị chặn): %', SQLERRM;
END $$;


-- =============================================================================
-- 2. DEMO MỤC 2.2: TRIGGERS
-- =============================================================================

-- Test 2.1: Trigger 2.2.1 chặn đặt trùng ghế A01 trong cùng suất chiếu
DO $$
DECLARE
    v_tmp_booking_id UUID := public.uuid_generate_v4();
BEGIN
    RAISE NOTICE '--- TEST 2.1: Thử đặt trùng ghế A01 (đã có ở CGV2026000001) ---';
    INSERT INTO public.booking (
        id, booking_code, user_id, showtime_id,
        ticket_total, combo_total, discount_amount, final_amount,
        status, expired_at
    ) VALUES (
        v_tmp_booking_id, 'DEMO_CONFLICT_A01',
        '93852855-f0a3-4a81-a1b1-d3af94e8e74f', '40dce532-a6b9-455f-83d3-987cefe55d9a',
        0, 0, 0, 0, 'pending', now() + INTERVAL '10 minutes'
    );

    BEGIN
        INSERT INTO public.booking_detail (
            booking_id, seat_id, seat_label, seat_type, price, status
        ) VALUES (
            v_tmp_booking_id,
            'ef1a3285-bf57-406a-a188-4d86e81afe5a',
            'A01', 'Ghế thường', 90000.00, 'active'
        );
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '>>> THÀNH CÔNG (Trigger đã chặn): %', SQLERRM;
    END;

    DELETE FROM public.booking WHERE id = v_tmp_booking_id;
END $$;

-- Test 2.2: Trigger 2.2.2 tự động tính thuộc tính dẫn xuất trên đơn pending (Đơn 5)
DO $$
DECLARE
    v_test_bid UUID := 'b2222222-2222-4222-a222-222222222222';
    v_combo_before NUMERIC;
    v_final_before NUMERIC;
    v_combo_after NUMERIC;
    v_final_after NUMERIC;
BEGIN
    RAISE NOTICE '--- TEST 2.2: Thêm Combo Solo vào đơn pending CGV2026000005 kiểm tra Trigger dẫn xuất ---';
    SELECT combo_total, final_amount INTO v_combo_before, v_final_before
    FROM public.booking WHERE id = v_test_bid;

    INSERT INTO public.booking_combo (
        booking_id, combo_id, quantity, unit_price, subtotal
    ) VALUES (
        v_test_bid, 'cb4fb778-334e-4afe-bdf5-981b8a7f69da', 1, 89000.00, 0
    );

    SELECT combo_total, final_amount INTO v_combo_after, v_final_after
    FROM public.booking WHERE id = v_test_bid;

    RAISE NOTICE '>>> Trước: combo=% | final=% || Sau: combo=% | final=%',
        v_combo_before, v_final_before, v_combo_after, v_final_after;

    -- Hoàn tác dòng test vừa thêm
    DELETE FROM public.booking_combo
    WHERE booking_id = v_test_bid AND combo_id = 'cb4fb778-334e-4afe-bdf5-981b8a7f69da';
END $$;


-- =============================================================================
-- 3. DEMO MỤC 2.3: QUERY STORED PROCEDURES (REFCURSOR)
-- =============================================================================

-- Test 3.1: Danh sách đơn đặt vé kèm tìm kiếm & sắp xếp
DO $$
DECLARE
    cur REFCURSOR;
    rec RECORD;
BEGIN
    RAISE NOTICE '--- TEST 3.1: sp_get_user_booking_history (REFCURSOR) ---';
    CALL public.sp_get_user_booking_history(NULL, NULL, NULL, 'created_at', 'DESC', cur);
    LOOP
        FETCH cur INTO rec;
        EXIT WHEN NOT FOUND;
        RAISE NOTICE 'Code: % | Khách: % | Phim: % | Tổng: % | Trạng thái: %',
            rec.booking_code, rec.customer_name, rec.movie_title, rec.final_amount, rec.status;
    END LOOP;
    CLOSE cur;
END $$;

-- Test 3.2: Báo cáo doanh thu suất chiếu
DO $$
DECLARE
    cur REFCURSOR;
    rec RECORD;
BEGIN
    RAISE NOTICE '--- TEST 3.2: sp_report_showtime_revenue (REFCURSOR) ---';
    CALL public.sp_report_showtime_revenue('2024-01-01 00:00:00+07', '2027-12-31 23:59:59+07', 100000, NULL, cur);
    LOOP
        FETCH cur INTO rec;
        EXIT WHEN NOT FOUND;
        RAISE NOTICE 'Phim: % | Rạp: % | Số đơn: % | Doanh thu: % VNĐ',
            rec.movie_title, rec.cinema_name, rec.total_bookings, rec.total_revenue;
    END LOOP;
    CLOSE cur;
END $$;


-- =============================================================================
-- 4. DEMO MỤC 2.4: FUNCTIONS (CURSOR + LOOP + IF)
-- =============================================================================

-- Test 4.1: Kiểm toán hiệu quả chiết khấu của voucher SUMMER2024
SELECT * FROM public.fn_audit_promotion_discount_impact(
    p_promotion_id       => 'a3d45699-819d-43ce-945f-3b5c9a06d076',
    p_min_booking_amount => 0
);

-- Test 4.2: Đối soát thanh toán booking ngày 2026-11-02
SELECT * FROM public.fn_reconcile_daily_booking_payments(
    p_check_date => '2026-11-02'::DATE,
    p_tolerance  => 0.01
);
