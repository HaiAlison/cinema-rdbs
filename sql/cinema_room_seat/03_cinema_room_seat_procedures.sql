
-- MỤC 2.1: STORED PROCEDURES (INSERT / UPDATE / DELETE) CHO BẢNG CINEMA


-- 2.1.1. INSERT CINEMA
CREATE OR REPLACE PROCEDURE public.sp_insert_cinema(
    p_name        VARCHAR,
    p_phone       VARCHAR,
    p_address     VARCHAR,
    p_ward        VARCHAR,
    p_city        VARCHAR,
    p_description TEXT             DEFAULT NULL,
    p_lat         DOUBLE PRECISION DEFAULT NULL,
    p_long        DOUBLE PRECISION DEFAULT NULL,
    p_link_ggmap  VARCHAR          DEFAULT NULL,
    p_is_active   BOOLEAN          DEFAULT TRUE
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_new_id UUID;
BEGIN
    -- Kiểm tra tên rạp
    IF p_name IS NULL OR TRIM(p_name) = '' THEN
        RAISE EXCEPTION 'Lỗi dữ liệu [name]: Tên cụm rạp không được để trống.';
    END IF;

    IF EXISTS (
        SELECT 1 FROM public.cinema
        WHERE LOWER(TRIM(name)) = LOWER(TRIM(p_name)) AND deleted_at IS NULL
    ) THEN
        RAISE EXCEPTION 'Lỗi trùng lặp [name]: Cụm rạp "%" đã tồn tại trong hệ thống.', p_name;
    END IF;

    -- Kiểm tra số điện thoại / tổng đài (8 đến 15 chữ số)
    IF p_phone IS NULL OR TRIM(p_phone) !~ '^[0-9]{8,15}$' THEN
        RAISE EXCEPTION 'Lỗi định dạng [phone]: Số điện thoại "%" không hợp lệ (chỉ gồm 8-15 chữ số).', COALESCE(p_phone, 'NULL');
    END IF;

    -- Kiểm tra địa chỉ & thành phố (địa chỉ 2 cấp: Phường/Xã - Thành phố)
    IF p_address IS NULL OR TRIM(p_address) = '' THEN
        RAISE EXCEPTION 'Lỗi dữ liệu [address]: Địa chỉ cụm rạp không được để trống.';
    END IF;

    IF p_city IS NULL OR TRIM(p_city) = '' THEN
        RAISE EXCEPTION 'Lỗi dữ liệu [city]: Thành phố không được để trống.';
    END IF;

    -- Kiểm tra tọa độ địa lý
    IF p_lat IS NOT NULL AND (p_lat < -90 OR p_lat > 90) THEN
        RAISE EXCEPTION 'Lỗi tọa độ [lat]: Vĩ độ % nằm ngoài phạm vi hợp lệ [-90, 90].', p_lat;
    END IF;

    IF p_long IS NOT NULL AND (p_long < -180 OR p_long > 180) THEN
        RAISE EXCEPTION 'Lỗi tọa độ [long]: Kinh độ % nằm ngoài phạm vi hợp lệ [-180, 180].', p_long;
    END IF;

    -- Kiểm tra đường dẫn Google Maps (nếu có nhập)
    IF p_link_ggmap IS NOT NULL AND TRIM(p_link_ggmap) <> ''
       AND TRIM(p_link_ggmap) !~* '^https?://' THEN
        RAISE EXCEPTION 'Lỗi định dạng [link_ggmap]: Đường dẫn "%" phải bắt đầu bằng http:// hoặc https://.', p_link_ggmap;
    END IF;

    INSERT INTO public.cinema (
        name, phone, address, ward, city, description, lat, long, link_ggmap, is_active
    )
    VALUES (
        TRIM(p_name), TRIM(p_phone), TRIM(p_address), NULLIF(TRIM(p_ward), ''),
        TRIM(p_city), p_description, p_lat, p_long, NULLIF(TRIM(p_link_ggmap), ''),
        COALESCE(p_is_active, TRUE)
    )
    RETURNING id INTO v_new_id;

    RAISE NOTICE 'Thêm cụm rạp "%" thành công (id = %).', p_name, v_new_id;
END;
$$;


-- 2.1.2. UPDATE CINEMA
CREATE OR REPLACE PROCEDURE public.sp_update_cinema(
    p_id          UUID,
    p_name        VARCHAR,
    p_phone       VARCHAR,
    p_address     VARCHAR,
    p_ward        VARCHAR,
    p_city        VARCHAR,
    p_description TEXT,
    p_lat         DOUBLE PRECISION,
    p_long        DOUBLE PRECISION,
    p_link_ggmap  VARCHAR,
    p_is_active   BOOLEAN
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_old_active       BOOLEAN;
    v_active_showtimes INT;
BEGIN
    IF p_id IS NULL THEN
        RAISE EXCEPTION 'Lỗi tham số [id]: Mã cụm rạp không được để trống.';
    END IF;

    SELECT is_active INTO v_old_active
    FROM public.cinema
    WHERE id = p_id AND deleted_at IS NULL;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Lỗi không tìm thấy [id]: Cụm rạp có mã "%" không tồn tại.', p_id;
    END IF;

    IF p_name IS NULL OR TRIM(p_name) = '' THEN
        RAISE EXCEPTION 'Lỗi dữ liệu [name]: Tên cụm rạp không được để trống.';
    END IF;

    IF EXISTS (
        SELECT 1 FROM public.cinema
        WHERE LOWER(TRIM(name)) = LOWER(TRIM(p_name))
          AND id <> p_id
          AND deleted_at IS NULL
    ) THEN
        RAISE EXCEPTION 'Lỗi trùng lặp [name]: Tên cụm rạp "%" đã được sử dụng bởi rạp khác.', p_name;
    END IF;

    IF p_phone IS NULL OR TRIM(p_phone) !~ '^[0-9]{8,15}$' THEN
        RAISE EXCEPTION 'Lỗi định dạng [phone]: Số điện thoại "%" không hợp lệ (chỉ gồm 8-15 chữ số).', COALESCE(p_phone, 'NULL');
    END IF;

    IF p_address IS NULL OR TRIM(p_address) = '' THEN
        RAISE EXCEPTION 'Lỗi dữ liệu [address]: Địa chỉ cụm rạp không được để trống.';
    END IF;

    IF p_city IS NULL OR TRIM(p_city) = '' THEN
        RAISE EXCEPTION 'Lỗi dữ liệu [city]: Thành phố không được để trống.';
    END IF;

    IF p_lat IS NOT NULL AND (p_lat < -90 OR p_lat > 90) THEN
        RAISE EXCEPTION 'Lỗi tọa độ [lat]: Vĩ độ % nằm ngoài phạm vi hợp lệ [-90, 90].', p_lat;
    END IF;

    IF p_long IS NOT NULL AND (p_long < -180 OR p_long > 180) THEN
        RAISE EXCEPTION 'Lỗi tọa độ [long]: Kinh độ % nằm ngoài phạm vi hợp lệ [-180, 180].', p_long;
    END IF;

    IF p_link_ggmap IS NOT NULL AND TRIM(p_link_ggmap) <> ''
       AND TRIM(p_link_ggmap) !~* '^https?://' THEN
        RAISE EXCEPTION 'Lỗi định dạng [link_ggmap]: Đường dẫn "%" phải bắt đầu bằng http:// hoặc https://.', p_link_ggmap;
    END IF;

    -- Không cho ngưng hoạt động rạp khi vẫn còn suất chiếu đang mở bán / sắp chiếu
    IF v_old_active = TRUE AND p_is_active = FALSE THEN
        SELECT COUNT(*) INTO v_active_showtimes
        FROM public.showtime st
        JOIN public.room r ON r.id = st.room_id
        WHERE r.cinema_id = p_id
          AND st.deleted_at IS NULL
          AND st.status IN ('upcoming', 'open');

        IF v_active_showtimes > 0 THEN
            RAISE EXCEPTION 'Lỗi nghiệp vụ [is_active]: Không thể ngưng hoạt động rạp vì vẫn còn % suất chiếu đang mở bán hoặc sắp chiếu.', v_active_showtimes;
        END IF;
    END IF;

    UPDATE public.cinema
    SET name        = TRIM(p_name),
        phone       = TRIM(p_phone),
        address     = TRIM(p_address),
        ward        = NULLIF(TRIM(p_ward), ''),
        city        = TRIM(p_city),
        description = p_description,
        lat         = p_lat,
        long        = p_long,
        link_ggmap  = NULLIF(TRIM(p_link_ggmap), ''),
        is_active   = COALESCE(p_is_active, is_active),
        updated_at  = NOW()
    WHERE id = p_id;

    RAISE NOTICE 'Cập nhật cụm rạp "%" thành công.', p_name;
END;
$$;


-- 2.1.3. DELETE CINEMA
-- Quy định nghiệp vụ khi xóa:
--   * CẤM XÓA khi:
--       (1) Rạp đang hoạt động (is_active = TRUE) -> tránh thao tác nhầm làm gián đoạn hệ thống.
--       (2) Rạp từng phát sinh suất chiếu (showtime) -> bảo toàn lịch sử đặt vé & báo cáo doanh thu.
--   * CHO PHÉP XÓA khi:
--       Rạp đã được chuyển sang ngưng hoạt động (is_active = FALSE) và chưa có suất chiếu nào.
CREATE OR REPLACE PROCEDURE public.sp_delete_cinema(p_id UUID)
LANGUAGE plpgsql
AS $$
DECLARE
    v_name           VARCHAR;
    v_is_active      BOOLEAN;
    v_showtime_count INT;
BEGIN
    IF p_id IS NULL THEN
        RAISE EXCEPTION 'Lỗi tham số [id]: Mã cụm rạp cần xóa không được để trống.';
    END IF;

    SELECT name, is_active INTO v_name, v_is_active
    FROM public.cinema
    WHERE id = p_id AND deleted_at IS NULL;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Lỗi không tìm thấy [id]: Cụm rạp có mã "%" không tồn tại.', p_id;
    END IF;

    IF v_is_active = TRUE THEN
        RAISE EXCEPTION 'Cấm xóa [is_active]: Cụm rạp "%" đang hoạt động. Phải chuyển is_active = FALSE trước khi xóa để tránh xóa nhầm dữ liệu đang vận hành.', v_name;
    END IF;

    SELECT COUNT(*) INTO v_showtime_count
    FROM public.showtime st
    JOIN public.room r ON r.id = st.room_id
    WHERE r.cinema_id = p_id;

    IF v_showtime_count > 0 THEN
        RAISE EXCEPTION 'Cấm xóa [toàn vẹn dữ liệu]: Cụm rạp "%" đang liên kết với % suất chiếu. Không được xóa để bảo toàn lịch sử vé và doanh thu.', v_name, v_showtime_count;
    END IF;

    -- Xóa theo thứ tự phụ thuộc khóa ngoại: seat -> room -> cinema
    DELETE FROM public.seat
    WHERE room_id IN (SELECT id FROM public.room WHERE cinema_id = p_id);

    DELETE FROM public.room WHERE cinema_id = p_id;
    DELETE FROM public.cinema WHERE id = p_id;

    RAISE NOTICE 'Đã xóa thành công cụm rạp "%" (id = %).', v_name, p_id;
END;
$$;



-- MỤC 2.3: 2 STORED PROCEDURES TRUY VẤN HIỂN THỊ DỮ LIỆU
-- (PostgreSQL sử dụng FUNCTION RETURNS TABLE để trả tập kết quả cho NestJS)


-- 2.3.1. SP 1: JOIN >= 2 bảng (cinema + room) + WHERE (tham số) + ORDER BY
CREATE OR REPLACE FUNCTION public.sp_search_cinema_rooms(
    p_city      VARCHAR DEFAULT NULL,
    p_room_type VARCHAR DEFAULT NULL,
    p_is_active BOOLEAN DEFAULT NULL
)
RETURNS TABLE (
    cinema_id   UUID,
    cinema_name VARCHAR,
    ward        VARCHAR,
    city        VARCHAR,
    is_active   BOOLEAN,
    room_id     UUID,
    room_name   VARCHAR,
    room_type   VARCHAR,
    total_seats INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id,
        c.name,
        c.ward,
        c.city,
        c.is_active,
        r.id,
        r.name,
        r.room_type::VARCHAR,
        r.total_seats
    FROM public.cinema c
    JOIN public.room r ON r.cinema_id = c.id
    WHERE c.deleted_at IS NULL
      AND r.deleted_at IS NULL
      AND (p_city IS NULL OR TRIM(p_city) = '' OR c.city ILIKE '%' || TRIM(p_city) || '%')
      AND (p_room_type IS NULL OR TRIM(p_room_type) = '' OR r.room_type::TEXT = LOWER(TRIM(p_room_type)))
      AND (p_is_active IS NULL OR c.is_active = p_is_active)
    ORDER BY c.name ASC, r.name ASC;
END;
$$;


-- 2.3.2. SP 2: JOIN 4 bảng + Hàm tổng hợp + WHERE + GROUP BY + HAVING + ORDER BY
CREATE OR REPLACE FUNCTION public.sp_report_cinema_capacity(
    p_city      VARCHAR DEFAULT NULL,
    p_min_seats INT     DEFAULT 0
)
RETURNS TABLE (
    cinema_id      UUID,
    cinema_name    VARCHAR,
    ward           VARCHAR,
    city           VARCHAR,
    room_count     BIGINT,
    seat_count     BIGINT,
    avg_surcharge  NUMERIC(12,2),
    max_surcharge  NUMERIC(12,2)
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_min_seats IS NOT NULL AND p_min_seats < 0 THEN
        RAISE EXCEPTION 'Lỗi tham số [p_min_seats]: Số ghế tối thiểu không được âm (đang nhập: %).', p_min_seats;
    END IF;

    RETURN QUERY
    SELECT
        c.id,
        c.name,
        c.ward,
        c.city,
        COUNT(DISTINCT r.id)        AS room_count,
        COUNT(s.id)                 AS seat_count,
        ROUND(AVG(st.surcharge), 2) AS avg_surcharge,
        MAX(st.surcharge)           AS max_surcharge
    FROM public.cinema c
    JOIN public.room r       ON r.cinema_id = c.id AND r.deleted_at IS NULL
    JOIN public.seat s       ON s.room_id = r.id   AND s.deleted_at IS NULL
    JOIN public.seat_type st ON st.id = s.seat_type_id
    WHERE c.is_active = TRUE
      AND c.deleted_at IS NULL
      AND (p_city IS NULL OR TRIM(p_city) = '' OR c.city ILIKE '%' || TRIM(p_city) || '%')
    GROUP BY c.id, c.name, c.ward, c.city
    HAVING COUNT(s.id) >= COALESCE(p_min_seats, 0)
    ORDER BY seat_count DESC, c.name ASC;
END;
$$;
