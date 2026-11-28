-- 1. Dữ liệu mẫu bảng SEAT_TYPE (đúng 4 loại ghế theo BTL1: standard, vip, sweetbox, deluxe)
INSERT INTO public.seat_type (name, code, surcharge, color, description, is_active)
VALUES
    ('Ghế thường',       'standard', 0.00,     '#6C757D', 'Ghế tiêu chuẩn các hàng đầu và rìa',      TRUE),
    ('Ghế VIP',          'vip',      20000.00, '#E50914', 'Ghế khu vực trung tâm tầm nhìn tốt nhất', TRUE),
    ('Ghế đôi Sweetbox', 'sweetbox', 45000.00, '#FF69B4', 'Ghế đôi hàng cuối dành cho cặp đôi',      TRUE),
    ('Ghế Deluxe',       'deluxe',   60000.00, '#D4AF37', 'Ghế hạng sang rộng rãi có tựa chân',      TRUE)
ON CONFLICT (code) DO NOTHING;

-- 2. Chuẩn hóa địa chỉ 2 cấp cho 2 rạp TP.HCM nếu đã tồn tại sẵn từ seed cũ
UPDATE public.cinema
SET ward = 'Phường Tân Sơn Nhì'
WHERE name = 'CGV Aeon Mall Tân Phú' AND ward = 'Lê Đại Hành';

UPDATE public.cinema
SET ward = 'Phường Tân Mỹ'
WHERE name = 'CGV Crescent Mall' AND ward = 'Lê Đại Hành';

-- 3. Thêm 7 cụm rạp TP.HCM (địa chỉ 2 cấp), 37 phòng và 3.636 ghế:
--    IMAX: 12x12 (144 ghế) | Gold Class: 5x8 (40 ghế) | L'Amour: 4x6 (24 ghế) | Khác: 10x10 (100 ghế)
WITH cinema_seed(name, phone, address, ward, city, description, lat, long) AS (
    VALUES
        ('CGV Sư Vạn Hạnh',      '19001530', '11 Sư Vạn Hạnh',       'Phường Hoà Hưng',     'TP.HCM', 'Cụm rạp lớn tích hợp IMAX & 4DX',           10.7769, 106.6673),
        ('CGV Landmark 81',      '19001530', '720A Điện Biên Phủ',   'Phường Thạnh Mỹ Tây', 'TP.HCM', 'Trải nghiệm IMAX, Gold Class và L''Amour',   10.7950, 106.7218),
        ('CGV SC VivoCity',      '19001530', '1058 Nguyễn Văn Linh', 'Phường Tân Hưng',     'TP.HCM', 'Cụm rạp IMAX và 4DX khu Nam Sài Gòn',        10.7289, 106.7001),
        ('CGV Pearl Plaza',      '19001530', '561A Điện Biên Phủ',   'Phường Thạnh Mỹ Tây', 'TP.HCM', 'Cụm rạp tiêu chuẩn quốc tế',                 10.7981, 106.7190),
        ('CGV Vincom Thủ Đức',   '19001530', '216 Võ Văn Ngân',      'Phường Thủ Đức',      'TP.HCM', 'CGV trung tâm khu vực Thủ Đức',              10.8517, 106.7621),
        ('CGV Giga Mall',        '19001530', '240 Phạm Văn Đồng',    'Phường Hiệp Bình',    'TP.HCM', 'Tổ hợp giải trí Phạm Văn Đồng',              10.8277, 106.7197),
        ('CGV Hùng Vương Plaza', '19001530', '126 Hồng Bàng',        'Phường Chợ Lớn',      'TP.HCM', 'Cụm rạp Gold Class & Starium khu Chợ Lớn',   10.7554, 106.6657)
),
new_cinemas AS (
    INSERT INTO public.cinema (name, phone, address, ward, city, description, lat, long, is_active)
    SELECT s.name, s.phone, s.address, s.ward, s.city, s.description, s.lat, s.long, TRUE
    FROM cinema_seed s
    WHERE NOT EXISTS (
        SELECT 1 FROM public.cinema c
        WHERE c.name = s.name AND c.deleted_at IS NULL
    )
    RETURNING id, name
),
room_templates(cinema_name, room_name, room_type) AS (
    VALUES
        -- CGV Sư Vạn Hạnh (6 phòng, 644 ghế -> Flagship)
        ('CGV Sư Vạn Hạnh', 'IMAX Theater', 'imax'),
        ('CGV Sư Vạn Hạnh', '4DX Theater',  '4dx'),
        ('CGV Sư Vạn Hạnh', 'Cinema 03',    'standard_3d'),
        ('CGV Sư Vạn Hạnh', 'Cinema 04',    'standard_2d'),
        ('CGV Sư Vạn Hạnh', 'Cinema 05',    'standard_2d'),
        ('CGV Sư Vạn Hạnh', 'Cinema 06',    'standard_2d'),

        -- CGV Landmark 81 (6 phòng, 508 ghế -> Flagship)
        ('CGV Landmark 81', 'IMAX Landmark', 'imax'),
        ('CGV Landmark 81', 'Gold Class',    'golden_class'),
        ('CGV Landmark 81', 'L''Amour',      'lamour'),
        ('CGV Landmark 81', 'Cinema 04',     'standard_3d'),
        ('CGV Landmark 81', 'Cinema 05',     'standard_2d'),
        ('CGV Landmark 81', 'Cinema 06',     'standard_2d'),

        -- CGV SC VivoCity (6 phòng, 644 ghế -> Flagship)
        ('CGV SC VivoCity', 'IMAX Vivo', 'imax'),
        ('CGV SC VivoCity', '4DX Vivo',  '4dx'),
        ('CGV SC VivoCity', 'Cinema 03', 'standard_3d'),
        ('CGV SC VivoCity', 'Cinema 04', 'standard_2d'),
        ('CGV SC VivoCity', 'Cinema 05', 'standard_2d'),
        ('CGV SC VivoCity', 'Cinema 06', 'standard_2d'),

        -- CGV Hùng Vương Plaza (6 phòng, 540 ghế -> Flagship)
        ('CGV Hùng Vương Plaza', 'Gold Class', 'golden_class'),
        ('CGV Hùng Vương Plaza', 'Starium',    'starium'),
        ('CGV Hùng Vương Plaza', 'Cinema 03',  'standard_3d'),
        ('CGV Hùng Vương Plaza', 'Cinema 04',  'standard_2d'),
        ('CGV Hùng Vương Plaza', 'Cinema 05',  'standard_2d'),
        ('CGV Hùng Vương Plaza', 'Cinema 06',  'standard_2d'),

        -- CGV Vincom Thủ Đức (5 phòng, 500 ghế -> Standard)
        ('CGV Vincom Thủ Đức', 'Cinema 01', 'standard_3d'),
        ('CGV Vincom Thủ Đức', 'Cinema 02', 'standard_2d'),
        ('CGV Vincom Thủ Đức', 'Cinema 03', 'standard_3d'),
        ('CGV Vincom Thủ Đức', 'Cinema 04', 'standard_2d'),
        ('CGV Vincom Thủ Đức', 'Cinema 05', 'standard_2d'),

        -- CGV Giga Mall (4 phòng, 400 ghế -> Premium)
        ('CGV Giga Mall', 'Starium Giga', 'starium'),
        ('CGV Giga Mall', 'Cinema 02',    'standard_2d'),
        ('CGV Giga Mall', 'Cinema 03',    'standard_3d'),
        ('CGV Giga Mall', 'Cinema 04',    'standard_2d'),

        -- CGV Pearl Plaza (4 phòng, 400 ghế -> Standard)
        ('CGV Pearl Plaza', 'Cinema 01', 'standard_3d'),
        ('CGV Pearl Plaza', 'Cinema 02', 'standard_2d'),
        ('CGV Pearl Plaza', 'Cinema 03', 'standard_3d'),
        ('CGV Pearl Plaza', 'Cinema 04', 'standard_2d')
),
new_rooms AS (
    INSERT INTO public.room (name, cinema_id, room_type, total_seats)
    SELECT rt.room_name, nc.id, rt.room_type::public.room_room_type_enum, 0
    FROM new_cinemas nc
    JOIN room_templates rt ON rt.cinema_name = nc.name
    RETURNING id, room_type
)
INSERT INTO public.seat (room_id, seat_type_id, "row", col)
SELECT
    nr.id,
    st.id,
    row_char,
    col_num::VARCHAR
FROM new_rooms nr
CROSS JOIN LATERAL unnest(
    CASE
        WHEN nr.room_type = 'imax'         THEN ARRAY['A','B','C','D','E','F','G','H','I','J','K','L']
        WHEN nr.room_type = 'golden_class' THEN ARRAY['A','B','C','D','E']
        WHEN nr.room_type = 'lamour'       THEN ARRAY['A','B','C','D']
        ELSE                                    ARRAY['A','B','C','D','E','F','G','H','I','J']
    END
) AS row_char
CROSS JOIN LATERAL generate_series(
    1,
    CASE
        WHEN nr.room_type = 'imax'         THEN 12
        WHEN nr.room_type = 'golden_class' THEN 8
        WHEN nr.room_type = 'lamour'       THEN 6
        ELSE                                    10
    END
) AS col_num
JOIN public.seat_type st ON st.code = (
    CASE
        WHEN nr.room_type IN ('golden_class', 'lamour') THEN 'deluxe'
        WHEN nr.room_type = 'imax' THEN
            CASE
                WHEN row_char IN ('A','B','C') THEN 'standard'
                WHEN row_char IN ('D','E','F','G','H','I') THEN 'vip'
                WHEN row_char IN ('J','K') THEN 'deluxe'
                ELSE 'sweetbox'
            END
        WHEN nr.room_type IN ('4dx', 'starium') THEN
            CASE
                WHEN row_char IN ('A','B') THEN 'standard'
                WHEN row_char IN ('C','D','E','F','G') THEN 'vip'
                WHEN row_char IN ('H','I') THEN 'deluxe'
                ELSE 'sweetbox'
            END
        ELSE
            CASE
                WHEN row_char IN ('A','B','C','D') THEN 'standard'
                WHEN row_char IN ('E','F','G','H','I') THEN 'vip'
                ELSE 'sweetbox'
            END
    END
)::public.seat_type_code_enum
ON CONFLICT DO NOTHING;

-- 4. Đồng bộ lại thuộc tính dẫn xuất
UPDATE public.room r
SET total_seats = (
    SELECT COUNT(*)
    FROM public.seat s
    WHERE s.room_id = r.id
      AND s.deleted_at IS NULL
);

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'cinema' AND column_name = 'total_rooms'
    ) AND EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'cinema' AND column_name = 'total_capacity'
    ) THEN
        UPDATE public.cinema c
        SET total_rooms = (
                SELECT COUNT(*)
                FROM public.room r
                WHERE r.cinema_id = c.id AND r.deleted_at IS NULL
            ),
            total_capacity = COALESCE((
                SELECT SUM(r.total_seats)
                FROM public.room r
                WHERE r.cinema_id = c.id AND r.deleted_at IS NULL
            ), 0);
    END IF;
END;
$$;