-- PHẦN 1: KIỂM TRA DỮ LIỆU MẪU (MỤC 1.2) & RÀNG BUỘC MỨC BẢNG (MỤC 1.1)

SELECT 'seat_type' AS table_name, COUNT(*) AS row_count FROM public.seat_type WHERE deleted_at IS NULL
UNION ALL
SELECT 'cinema',    COUNT(*) FROM public.cinema    WHERE deleted_at IS NULL
UNION ALL
SELECT 'room',      COUNT(*) FROM public.room      WHERE deleted_at IS NULL
UNION ALL
SELECT 'seat',      COUNT(*) FROM public.seat      WHERE deleted_at IS NULL;

-- Danh sách cụm rạp kèm địa chỉ 2 cấp và thống kê số phòng / sức chứa
SELECT name, phone, address, ward, city, is_active, total_rooms, total_capacity
FROM public.cinema
WHERE deleted_at IS NULL
ORDER BY total_capacity DESC, name ASC;

-- 1.1.1. [LỖI KỲ VỌNG] CHECK phụ thu loại ghế không được âm
DO $$
BEGIN
    UPDATE public.seat_type SET surcharge = -10000 WHERE code = 'standard';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '[PASS - Mục 1.1 CHECK seat_type.surcharge < 0] Bắt lỗi thành công: %', SQLERRM;
END;
$$;

-- 1.1.2. [LỖI KỲ VỌNG] CHECK định dạng hàng ghế (chỉ chữ in hoa) & UNIQUE vị trí ghế
DO $$
DECLARE
    v_room_id UUID;
    v_st_id   UUID;
BEGIN
    SELECT id INTO v_room_id FROM public.room WHERE room_type = 'standard_2d' AND deleted_at IS NULL LIMIT 1;
    SELECT id INTO v_st_id   FROM public.seat_type WHERE code = 'standard' LIMIT 1;

    BEGIN
        INSERT INTO public.seat (room_id, seat_type_id, "row", col)
        VALUES (v_room_id, v_st_id, '1A', '99');
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '[PASS - Mục 1.1 CHECK seat.row sai định dạng] Bắt lỗi thành công: %', SQLERRM;
    END;

    BEGIN
        INSERT INTO public.seat (room_id, seat_type_id, "row", col)
        VALUES (v_room_id, v_st_id, 'A', '1');
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '[PASS - Mục 1.1 UNIQUE trùng vị trí ghế] Bắt lỗi thành công: %', SQLERRM;
    END;
END;
$$;


-- PHẦN 2: DEMO STORED PROCEDURES CRUD BẢNG CINEMA (MỤC 2.1)

-- 2.1.1. [LỖI KỲ VỌNG] Thêm rạp với SĐT, tọa độ và link Google Maps không hợp lệ
DO $$
BEGIN
    CALL public.sp_insert_cinema(
        'CGV Sai SĐT', '090abc1234', '123 Lê Lợi', 'Phường Bến Thành', 'TP.HCM'
    );
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '[PASS - Mục 2.1.1 INSERT sai SĐT] Bắt lỗi thành công: %', SQLERRM;
END;
$$;

DO $$
BEGIN
    CALL public.sp_insert_cinema(
        'CGV Sai Tọa Độ', '19001530', '123 Lê Lợi', 'Phường Bến Thành', 'TP.HCM',
        NULL, 120.5, 106.7
    );
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '[PASS - Mục 2.1.1 INSERT sai tọa độ] Bắt lỗi thành công: %', SQLERRM;
END;
$$;

DO $$
BEGIN
    CALL public.sp_insert_cinema(
        'CGV Sai Link', '19001530', '123 Lê Lợi', 'Phường Bến Thành', 'TP.HCM',
        NULL, 10.77, 106.69, 'maps.google.com/khong-co-http'
    );
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '[PASS - Mục 2.1.1 INSERT sai link_ggmap] Bắt lỗi thành công: %', SQLERRM;
END;
$$;

-- 2.1.2. [HỢP LỆ] Thêm cụm rạp tạm & kiểm tra nhánh 'Empty' của fn_classify_cinema_tier
DO $$
DECLARE
    v_cinema_id UUID;
    v_tier      VARCHAR;
BEGIN
    -- Dọn trước nếu còn sót từ lần chạy cũ
    DELETE FROM public.seat WHERE room_id IN (
        SELECT r.id FROM public.room r
        JOIN public.cinema c ON c.id = r.cinema_id
        WHERE c.name IN ('CGV Demo Test BTL2', 'CGV Demo Test BTL2 (Updated)')
    );
    DELETE FROM public.room WHERE cinema_id IN (
        SELECT id FROM public.cinema
        WHERE name IN ('CGV Demo Test BTL2', 'CGV Demo Test BTL2 (Updated)')
    );
    DELETE FROM public.cinema
    WHERE name IN ('CGV Demo Test BTL2', 'CGV Demo Test BTL2 (Updated)');

    CALL public.sp_insert_cinema(
        'CGV Demo Test BTL2',
        '19001530',
        '268 Lý Thường Kiệt',
        'Phường Diên Hồng',
        'TP.HCM',
        'Cụm rạp phục vụ demo BTL2',
        10.7721,
        106.6579,
        'https://maps.google.com/?q=10.7721,106.6579',
        TRUE
    );

    SELECT id INTO v_cinema_id FROM public.cinema WHERE name = 'CGV Demo Test BTL2' LIMIT 1;
    v_tier := public.fn_classify_cinema_tier(v_cinema_id);
    IF v_tier <> 'Empty' THEN
        RAISE EXCEPTION 'Kỳ vọng hạng Empty nhưng nhận được: %', v_tier;
    END IF;
    RAISE NOTICE '[PASS - Mục 2.4 Hạng Empty] Rạp mới chưa có phòng -> fn_classify_cinema_tier = "%".', v_tier;
END;
$$;

-- 2.1.3. [LỖI KỲ VỌNG] Thêm trùng tên cụm rạp vừa tạo
DO $$
BEGIN
    CALL public.sp_insert_cinema(
        'CGV Demo Test BTL2', '19001530', '999 Nguyễn Trãi', 'Phường Chợ Quán', 'TP.HCM'
    );
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '[PASS - Mục 2.1.1 INSERT trùng tên] Bắt lỗi thành công: %', SQLERRM;
END;
$$;

-- 2.1.4. [LỖI KỲ VỌNG] Cập nhật rạp trùng tên rạp khác & sai SĐT
DO $$
DECLARE
    v_cinema_id UUID;
BEGIN
    SELECT id INTO v_cinema_id FROM public.cinema WHERE name = 'CGV Demo Test BTL2' LIMIT 1;

    BEGIN
        CALL public.sp_update_cinema(
            v_cinema_id, 'CGV Landmark 81', '19001530', '268 Lý Thường Kiệt',
            'Phường Diên Hồng', 'TP.HCM', NULL, 10.7721, 106.6579, NULL, TRUE
        );
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '[PASS - Mục 2.1.2 UPDATE trùng tên rạp khác] Bắt lỗi thành công: %', SQLERRM;
    END;

    BEGIN
        CALL public.sp_update_cinema(
            v_cinema_id, 'CGV Demo Test BTL2', '1234', '268 Lý Thường Kiệt',
            'Phường Diên Hồng', 'TP.HCM', NULL, 10.7721, 106.6579, NULL, TRUE
        );
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '[PASS - Mục 2.1.2 UPDATE sai SĐT] Bắt lỗi thành công: %', SQLERRM;
    END;
END;
$$;

-- 2.1.5. [HỢP LỆ] Cập nhật thông tin cụm rạp tạm bằng sp_update_cinema
DO $$
DECLARE
    v_cinema_id UUID;
BEGIN
    SELECT id INTO v_cinema_id FROM public.cinema WHERE name = 'CGV Demo Test BTL2' LIMIT 1;

    CALL public.sp_update_cinema(
        v_cinema_id,
        'CGV Demo Test BTL2 (Updated)',
        '02838647256',
        '268 Lý Thường Kiệt',
        'Phường Diên Hồng',
        'TP.HCM',
        'Đã cập nhật thông tin bằng sp_update_cinema',
        10.7721,
        106.6579,
        'https://maps.google.com/?q=10.7721,106.6579',
        TRUE
    );
END;
$$;


-- PHẦN 3: DEMO TRIGGERS (MỤC 2.2.1 RÀNG BUỘC & MỤC 2.2.2 DẪN XUẤT B -> A)

DO $$
DECLARE
    v_cinema_id   UUID;
    v_room_std_id UUID;
    v_room_gc_id  UUID;
    v_st_standard UUID;
    v_st_deluxe   UUID;
    v_seats       INT;
    v_rooms       INT;
    v_capacity    INT;
BEGIN
    SELECT id INTO v_cinema_id   FROM public.cinema    WHERE name = 'CGV Demo Test BTL2 (Updated)' LIMIT 1;
    SELECT id INTO v_st_standard FROM public.seat_type WHERE code = 'standard' LIMIT 1;
    SELECT id INTO v_st_deluxe   FROM public.seat_type WHERE code = 'deluxe'   LIMIT 1;

    -- Tạo 2 phòng trong cụm rạp demo -> Trigger tự tăng cinema.total_rooms lên 2
    INSERT INTO public.room (name, cinema_id, room_type)
    VALUES ('Demo Room 2D', v_cinema_id, 'standard_2d')
    RETURNING id INTO v_room_std_id;

    INSERT INTO public.room (name, cinema_id, room_type)
    VALUES ('Demo Room Gold', v_cinema_id, 'golden_class')
    RETURNING id INTO v_room_gc_id;

    -- 3.1. INSERT 2 ghế hợp lệ -> Trigger 2a (total_seats=2) -> Trigger 2b (total_capacity=2)
    INSERT INTO public.seat (room_id, seat_type_id, "row", col)
    VALUES
        (v_room_std_id, v_st_standard, 'A', '1'),
        (v_room_std_id, v_st_standard, 'A', '2');

    SELECT total_seats INTO v_seats FROM public.room WHERE id = v_room_std_id;
    SELECT total_rooms, total_capacity INTO v_rooms, v_capacity FROM public.cinema WHERE id = v_cinema_id;
    RAISE NOTICE '[PASS - Mục 2.2.2 INSERT ghế] room.total_seats=%, cinema.total_rooms=%, cinema.total_capacity=%',
        v_seats, v_rooms, v_capacity;

    -- 3.2. [LỖI KỲ VỌNG - 2.2.1a] INSERT ghế deluxe vào phòng standard_2d
    BEGIN
        INSERT INTO public.seat (room_id, seat_type_id, "row", col)
        VALUES (v_room_std_id, v_st_deluxe, 'B', '1');
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '[PASS - Mục 2.2.1a INSERT ghế deluxe vào phòng thường] Bắt lỗi thành công: %', SQLERRM;
    END;

    -- 3.3. [LỖI KỲ VỌNG - 2.2.1b] INSERT ghế standard vào phòng golden_class
    BEGIN
        INSERT INTO public.seat (room_id, seat_type_id, "row", col)
        VALUES (v_room_gc_id, v_st_standard, 'A', '1');
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '[PASS - Mục 2.2.1b INSERT ghế thường vào Gold Class] Bắt lỗi thành công: %', SQLERRM;
    END;

    -- 3.4. [LỖI KỲ VỌNG - 2.2.1c] UPDATE đổi seat_type_id của ghế đang có sang deluxe trong phòng thường
    BEGIN
        UPDATE public.seat
        SET seat_type_id = v_st_deluxe
        WHERE room_id = v_room_std_id AND "row" = 'A' AND col = '1';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '[PASS - Mục 2.2.1c UPDATE seat_type_id không tương thích] Bắt lỗi thành công: %', SQLERRM;
    END;

    -- 3.5. [LỖI KỲ VỌNG - 2.2.1d] UPDATE đổi room_type sang golden_class khi đang chứa ghế thường
    BEGIN
        UPDATE public.room SET room_type = 'golden_class' WHERE id = v_room_std_id;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '[PASS - Mục 2.2.1d UPDATE room_type xung đột ghế] Bắt lỗi thành công: %', SQLERRM;
    END;

    -- 3.6. UPDATE xóa mềm 1 ghế (deleted_at) -> giảm về 1, rồi khôi phục lại -> tăng về 2
    UPDATE public.seat
    SET deleted_at = NOW()
    WHERE room_id = v_room_std_id AND "row" = 'A' AND col = '2';

    SELECT total_seats INTO v_seats FROM public.room WHERE id = v_room_std_id;
    SELECT total_capacity INTO v_capacity FROM public.cinema WHERE id = v_cinema_id;
    RAISE NOTICE '[PASS - Mục 2.2.2 UPDATE xóa mềm ghế] room.total_seats=%, cinema.total_capacity=%',
        v_seats, v_capacity;

    UPDATE public.seat
    SET deleted_at = NULL
    WHERE room_id = v_room_std_id AND "row" = 'A' AND col = '2';

    -- 3.7. DELETE cứng 1 ghế (A2) -> Trigger tự giảm room.total_seats=1 và cinema.total_capacity=1
    DELETE FROM public.seat WHERE room_id = v_room_std_id AND "row" = 'A' AND col = '2';

    SELECT total_seats INTO v_seats FROM public.room WHERE id = v_room_std_id;
    SELECT total_capacity INTO v_capacity FROM public.cinema WHERE id = v_cinema_id;
    RAISE NOTICE '[PASS - Mục 2.2.2 DELETE ghế] Sau khi xóa 1 ghế: room.total_seats=%, cinema.total_capacity=%',
        v_seats, v_capacity;
END;
$$;


-- PHẦN 4: DEMO LUẬT XÓA sp_delete_cinema (MỤC 2.1.3) & NHÁNH 'Inactive' (MỤC 2.4)

-- 4.1. [LỖI KỲ VỌNG] Cấm xóa khi rạp đang hoạt động (is_active = TRUE)
DO $$
DECLARE
    v_cinema_id UUID;
BEGIN
    SELECT id INTO v_cinema_id FROM public.cinema WHERE name = 'CGV Demo Test BTL2 (Updated)' LIMIT 1;
    CALL public.sp_delete_cinema(v_cinema_id);
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '[PASS - Mục 2.1.3 DELETE rạp đang hoạt động] Bắt lỗi thành công: %', SQLERRM;
END;
$$;

-- 4.2. [HỢP LỆ] Chuyển is_active = FALSE -> kiểm tra hạng 'Inactive' -> xóa sạch cụm rạp tạm
DO $$
DECLARE
    v_cinema_id UUID;
    v_tier      VARCHAR;
BEGIN
    SELECT id INTO v_cinema_id FROM public.cinema WHERE name = 'CGV Demo Test BTL2 (Updated)' LIMIT 1;

    CALL public.sp_update_cinema(
        v_cinema_id,
        'CGV Demo Test BTL2 (Updated)',
        '02838647256',
        '268 Lý Thường Kiệt',
        'Phường Diên Hồng',
        'TP.HCM',
        'Ngưng hoạt động để tiến hành xóa',
        10.7721,
        106.6579,
        'https://maps.google.com/?q=10.7721,106.6579',
        FALSE
    );

    v_tier := public.fn_classify_cinema_tier(v_cinema_id);
    IF v_tier <> 'Inactive' THEN
        RAISE EXCEPTION 'Kỳ vọng hạng Inactive nhưng nhận được: %', v_tier;
    END IF;
    RAISE NOTICE '[PASS - Mục 2.4 Hạng Inactive] Rạp đã ngưng hoạt động -> fn_classify_cinema_tier = "%".', v_tier;

    CALL public.sp_delete_cinema(v_cinema_id);
    RAISE NOTICE '[PASS - Mục 2.1.3 DELETE hợp lệ] Đã xóa sạch cụm rạp tạm cùng phòng và ghế đi kèm.';
END;
$$;


-- PHẦN 5: DEMO STORED PROCEDURES TRUY VẤN DỮ LIỆU (MỤC 2.3)

-- 5.1. SP 1 (JOIN cinema + room + WHERE + ORDER BY): Các phòng IMAX đang hoạt động tại TP.HCM
SELECT *
FROM public.sp_search_cinema_rooms('TP.HCM', 'imax', TRUE);

-- 5.2. SP 2 (JOIN 4 bảng + GROUP BY + HAVING + ORDER BY):
--      Các cụm rạp TP.HCM có từ 500 ghế trở lên (lọc bỏ CGV Giga Mall & CGV Pearl Plaza có 400 ghế)
SELECT *
FROM public.sp_report_cinema_capacity('TP.HCM', 500);

-- 5.3. [LỖI KỲ VỌNG] Validate tham số p_min_seats < 0
DO $$
BEGIN
    PERFORM * FROM public.sp_report_cinema_capacity('TP.HCM', -10);
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '[PASS - Mục 2.3 Validate p_min_seats < 0] Bắt lỗi thành công: %', SQLERRM;
END;
$$;


-- PHẦN 6: DEMO FUNCTIONS CÓ CURSOR + IF/LOOP + VALIDATE (MỤC 2.4)

-- 6.1. Function 1: Doanh thu tối đa 1 suất chiếu (giá gốc 90.000đ) cho từng phòng tại CGV Landmark 81
SELECT
    c.name                                       AS cinema_name,
    r.name                                       AS room_name,
    r.room_type,
    r.total_seats,
    public.fn_calc_room_max_revenue(r.id, 90000) AS max_revenue_vnd
FROM public.room r
JOIN public.cinema c ON c.id = r.cinema_id
WHERE c.name = 'CGV Landmark 81'
  AND r.deleted_at IS NULL
ORDER BY max_revenue_vnd DESC;

-- 6.2. Function 2: Phân hạng toàn bộ cụm rạp (Flagship / Premium / Standard)
SELECT
    c.name                               AS cinema_name,
    c.ward,
    c.city,
    c.total_rooms,
    c.total_capacity,
    public.fn_classify_cinema_tier(c.id) AS cinema_tier
FROM public.cinema c
WHERE c.deleted_at IS NULL
ORDER BY cinema_tier ASC, c.total_capacity DESC;

-- 6.3. [LỖI KỲ VỌNG] Validate tham số Function 1 (giá vé cơ bản <= 0)
DO $$
DECLARE
    v_room_id UUID;
BEGIN
    SELECT id INTO v_room_id FROM public.room WHERE deleted_at IS NULL LIMIT 1;
    PERFORM public.fn_calc_room_max_revenue(v_room_id, -50000);
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '[PASS - Mục 2.4 Validate p_base_price <= 0] Bắt lỗi thành công: %', SQLERRM;
END;
$$;

-- 6.4. [LỖI KỲ VỌNG] Validate tham số Function 2 (UUID rạp không tồn tại)
DO $$
BEGIN
    PERFORM public.fn_classify_cinema_tier('00000000-0000-0000-0000-000000000000');
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '[PASS - Mục 2.4 Validate p_cinema_id không tồn tại] Bắt lỗi thành công: %', SQLERRM;
END;
$$;