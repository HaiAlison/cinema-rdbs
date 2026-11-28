-- FUNCTION 1: Tính doanh thu tối đa của 1 phòng chiếu khi lấp đầy 100% ghế
--   * Validate: p_room_id không NULL & tồn tại, p_base_price > 0.
--   * Xác định phụ phí định dạng phòng (IMAX, 4DX, Gold Class, L'Amour...) bằng IF/ELSIF.
--   * Dùng CURSOR + LOOP duyệt từng ghế (JOIN seat_type) để cộng dồn doanh thu.

CREATE OR REPLACE FUNCTION public.fn_calc_room_max_revenue(
    p_room_id    UUID,
    p_base_price NUMERIC
)
RETURNS NUMERIC(14,2)
LANGUAGE plpgsql
AS $$
DECLARE
    v_room_type        public.room_room_type_enum;
    v_format_surcharge NUMERIC(12,2) := 0;
    v_seat_surcharge   NUMERIC(12,2);
    v_total_revenue    NUMERIC(14,2) := 0;

    cur_seats CURSOR FOR
        SELECT st.surcharge
        FROM public.seat s
        JOIN public.seat_type st ON st.id = s.seat_type_id
        WHERE s.room_id = p_room_id
          AND s.deleted_at IS NULL;
BEGIN
    -- 1. Validate tham số đầu vào
    IF p_room_id IS NULL THEN
        RAISE EXCEPTION 'Lỗi tham số [p_room_id]: Mã phòng chiếu không được để trống.';
    END IF;

    IF p_base_price IS NULL OR p_base_price <= 0 THEN
        RAISE EXCEPTION 'Lỗi tham số [p_base_price]: Giá vé cơ bản phải lớn hơn 0 (đang nhập: %).', p_base_price;
    END IF;

    SELECT room_type INTO v_room_type
    FROM public.room
    WHERE id = p_room_id
      AND deleted_at IS NULL;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Lỗi không tìm thấy [p_room_id]: Phòng chiếu "%" không tồn tại.', p_room_id;
    END IF;

    -- 2. Xác định phụ phí định dạng phòng chiếu bằng IF / ELSIF
    IF v_room_type = 'imax' THEN
        v_format_surcharge := 50000;
    ELSIF v_room_type IN ('4dx', 'ultra_4dx') THEN
        v_format_surcharge := 40000;
    ELSIF v_room_type = 'golden_class' THEN
        v_format_surcharge := 100000;
    ELSIF v_room_type = 'lamour' THEN
        v_format_surcharge := 150000;
    ELSIF v_room_type IN ('starium', 'infinity') THEN
        v_format_surcharge := 30000;
    ELSIF v_room_type = 'standard_3d' THEN
        v_format_surcharge := 20000;
    ELSE
        v_format_surcharge := 0;
    END IF;

    -- 3. Duyệt từng ghế trong phòng bằng CURSOR và LOOP
    OPEN cur_seats;
    LOOP
        FETCH cur_seats INTO v_seat_surcharge;
        EXIT WHEN NOT FOUND;

        v_total_revenue := v_total_revenue
                         + p_base_price
                         + v_format_surcharge
                         + COALESCE(v_seat_surcharge, 0);
    END LOOP;
    CLOSE cur_seats;

    RETURN v_total_revenue;
END;
$$;



-- FUNCTION 2: Phân hạng cụm rạp (Flagship / Premium / Standard / Empty / Inactive)
--   * Validate: p_cinema_id không NULL & tồn tại trong bảng cinema.
--   * Dùng CURSOR + LOOP duyệt toàn bộ phòng thuộc cụm rạp để đếm tổng số phòng,
--     số phòng cao cấp (premium) và tổng sức chứa ghế.
--   * Phân loại hạng rạp bằng IF / ELSIF.

CREATE OR REPLACE FUNCTION public.fn_classify_cinema_tier(p_cinema_id UUID)
RETURNS VARCHAR
LANGUAGE plpgsql
AS $$
DECLARE
    v_is_active     BOOLEAN;
    v_room_type     TEXT;
    v_seats         INT;
    v_total_rooms   INT := 0;
    v_premium_rooms INT := 0;
    v_total_seats   INT := 0;

    cur_rooms CURSOR FOR
        SELECT room_type::TEXT, total_seats
        FROM public.room
        WHERE cinema_id = p_cinema_id
          AND deleted_at IS NULL;
BEGIN
    -- 1. Validate tham số đầu vào
    IF p_cinema_id IS NULL THEN
        RAISE EXCEPTION 'Lỗi tham số [p_cinema_id]: Mã cụm rạp không được để trống.';
    END IF;

    SELECT is_active INTO v_is_active
    FROM public.cinema
    WHERE id = p_cinema_id
      AND deleted_at IS NULL;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Lỗi không tìm thấy [p_cinema_id]: Cụm rạp "%" không tồn tại.', p_cinema_id;
    END IF;

    IF v_is_active = FALSE THEN
        RETURN 'Inactive';
    END IF;

    -- 2. Duyệt từng phòng của cụm rạp bằng CURSOR và LOOP + IF
    OPEN cur_rooms;
    LOOP
        FETCH cur_rooms INTO v_room_type, v_seats;
        EXIT WHEN NOT FOUND;

        v_total_rooms := v_total_rooms + 1;
        v_total_seats := v_total_seats + COALESCE(v_seats, 0);

        IF v_room_type IN ('imax', '4dx', 'ultra_4dx', 'golden_class', 'lamour', 'starium', 'infinity') THEN
            v_premium_rooms := v_premium_rooms + 1;
        END IF;
    END LOOP;
    CLOSE cur_rooms;

    -- 3. Phân hạng cụm rạp
    IF v_total_rooms = 0 THEN
        RETURN 'Empty';
    ELSIF v_premium_rooms >= 2 AND v_total_seats >= 500 THEN
        RETURN 'Flagship';
    ELSIF v_premium_rooms >= 1 THEN
        RETURN 'Premium';
    ELSE
        RETURN 'Standard';
    END IF;
END;
$$;
