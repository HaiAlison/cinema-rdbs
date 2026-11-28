-- MỤC 2.2.1: TRIGGER RÀNG BUỘC NGHIỆP VỤ (TƯƠNG THÍCH LOẠI GHẾ - LOẠI PHÒNG)
-- Quy tắc nghiệp vụ (với đúng 4 loại ghế chuẩn: standard, vip, sweetbox, deluxe):
--   * Phòng standard_2d / standard_3d KHÔNG được chứa ghế deluxe.
--   * Phòng hạng sang (golden_class, lamour) CHỈ được chứa ghế deluxe.
--   * Phòng sweet_box CHỈ được chứa ghế sweetbox.

-- Trigger 1a: Kiểm tra tương thích khi thêm mới hoặc đổi phòng/loại ghế trên bảng SEAT
CREATE OR REPLACE FUNCTION public.fn_trg_check_seat_room_compat()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_room_type public.room_room_type_enum;
    v_seat_code public.seat_type_code_enum;
BEGIN
    IF NEW.deleted_at IS NOT NULL THEN
        RETURN NEW;
    END IF;

    SELECT room_type INTO v_room_type
    FROM public.room
    WHERE id = NEW.room_id;

    SELECT code INTO v_seat_code
    FROM public.seat_type
    WHERE id = NEW.seat_type_id;

    IF v_room_type IN ('standard_2d', 'standard_3d') AND v_seat_code = 'deluxe' THEN
        RAISE EXCEPTION 'Vi phạm ràng buộc nghiệp vụ: Phòng chiếu thường (%) không được phép lắp đặt ghế loại "deluxe".',
            v_room_type;
    END IF;

    IF v_room_type IN ('golden_class', 'lamour') AND v_seat_code <> 'deluxe' THEN
        RAISE EXCEPTION 'Vi phạm ràng buộc nghiệp vụ: Phòng hạng sang (%) chỉ cho phép ghế loại "deluxe" (đang nhập "%").',
            v_room_type, v_seat_code;
    END IF;

    IF v_room_type = 'sweet_box' AND v_seat_code <> 'sweetbox' THEN
        RAISE EXCEPTION 'Vi phạm ràng buộc nghiệp vụ: Phòng Sweetbox chỉ cho phép ghế loại "sweetbox" (đang nhập "%").',
            v_seat_code;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_seat_room_compat ON public.seat;
CREATE TRIGGER trg_seat_room_compat
BEFORE INSERT OR UPDATE OF room_id, seat_type_id, deleted_at ON public.seat
FOR EACH ROW
EXECUTE FUNCTION public.fn_trg_check_seat_room_compat();


-- Trigger 1b: Kiểm tra tương thích khi đổi loại phòng (room_type) trên bảng ROOM
CREATE OR REPLACE FUNCTION public.fn_trg_check_room_type_change()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_bad_count INT;
BEGIN
    IF NEW.room_type IS DISTINCT FROM OLD.room_type THEN
        IF NEW.room_type IN ('standard_2d', 'standard_3d') THEN
            SELECT COUNT(*) INTO v_bad_count
            FROM public.seat s
            JOIN public.seat_type st ON st.id = s.seat_type_id
            WHERE s.room_id = NEW.id
              AND s.deleted_at IS NULL
              AND st.code = 'deluxe';

            IF v_bad_count > 0 THEN
                RAISE EXCEPTION 'Vi phạm ràng buộc nghiệp vụ: Không thể đổi phòng sang "%" vì bên trong đang có % ghế deluxe.',
                    NEW.room_type, v_bad_count;
            END IF;

        ELSIF NEW.room_type IN ('golden_class', 'lamour') THEN
            SELECT COUNT(*) INTO v_bad_count
            FROM public.seat s
            JOIN public.seat_type st ON st.id = s.seat_type_id
            WHERE s.room_id = NEW.id
              AND s.deleted_at IS NULL
              AND st.code <> 'deluxe';

            IF v_bad_count > 0 THEN
                RAISE EXCEPTION 'Vi phạm ràng buộc nghiệp vụ: Không thể đổi phòng sang "%" vì đang có % ghế không phải deluxe.',
                    NEW.room_type, v_bad_count;
            END IF;

        ELSIF NEW.room_type = 'sweet_box' THEN
            SELECT COUNT(*) INTO v_bad_count
            FROM public.seat s
            JOIN public.seat_type st ON st.id = s.seat_type_id
            WHERE s.room_id = NEW.id
              AND s.deleted_at IS NULL
              AND st.code <> 'sweetbox';

            IF v_bad_count > 0 THEN
                RAISE EXCEPTION 'Vi phạm ràng buộc nghiệp vụ: Không thể đổi phòng sang "sweet_box" vì đang có % ghế không phải sweetbox.',
                    v_bad_count;
            END IF;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_room_type_change_compat ON public.room;
CREATE TRIGGER trg_room_type_change_compat
BEFORE UPDATE OF room_type ON public.room
FOR EACH ROW
EXECUTE FUNCTION public.fn_trg_check_room_type_change();


-- MỤC 2.2.2: TRIGGER TÍNH THUỘC TÍNH DẪN XUẤT THEO CHUỖI (B -> A)
--   * B = room.total_seats (tính từ bảng seat)
--   * A = cinema.total_rooms và cinema.total_capacity = SUM(room.total_seats)

-- Trigger 2a: Tự động cập nhật room.total_seats (B) khi bảng SEAT thay đổi
CREATE OR REPLACE FUNCTION public.fn_trg_update_room_total_seats()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'DELETE' OR (TG_OP = 'UPDATE' AND OLD.room_id IS DISTINCT FROM NEW.room_id) THEN
        UPDATE public.room
        SET total_seats = (
            SELECT COUNT(*)
            FROM public.seat
            WHERE room_id = OLD.room_id
              AND deleted_at IS NULL
        )
        WHERE id = OLD.room_id;
    END IF;

    IF TG_OP IN ('INSERT', 'UPDATE') THEN
        UPDATE public.room
        SET total_seats = (
            SELECT COUNT(*)
            FROM public.seat
            WHERE room_id = NEW.room_id
              AND deleted_at IS NULL
        )
        WHERE id = NEW.room_id;
    END IF;

    RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_seat_update_room_total_seats ON public.seat;
CREATE TRIGGER trg_seat_update_room_total_seats
AFTER INSERT OR UPDATE OF room_id, deleted_at OR DELETE ON public.seat
FOR EACH ROW
EXECUTE FUNCTION public.fn_trg_update_room_total_seats();


-- Trigger 2b: Tự động cập nhật cinema.total_rooms & cinema.total_capacity (A) khi bảng ROOM thay đổi
CREATE OR REPLACE FUNCTION public.fn_trg_update_cinema_stats()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'DELETE' OR (TG_OP = 'UPDATE' AND OLD.cinema_id IS DISTINCT FROM NEW.cinema_id) THEN
        UPDATE public.cinema
        SET total_rooms = (
                SELECT COUNT(*)
                FROM public.room
                WHERE cinema_id = OLD.cinema_id
                  AND deleted_at IS NULL
            ),
            total_capacity = COALESCE((
                SELECT SUM(total_seats)
                FROM public.room
                WHERE cinema_id = OLD.cinema_id
                  AND deleted_at IS NULL
            ), 0)
        WHERE id = OLD.cinema_id;
    END IF;

    IF TG_OP IN ('INSERT', 'UPDATE') THEN
        UPDATE public.cinema
        SET total_rooms = (
                SELECT COUNT(*)
                FROM public.room
                WHERE cinema_id = NEW.cinema_id
                  AND deleted_at IS NULL
            ),
            total_capacity = COALESCE((
                SELECT SUM(total_seats)
                FROM public.room
                WHERE cinema_id = NEW.cinema_id
                  AND deleted_at IS NULL
            ), 0)
        WHERE id = NEW.cinema_id;
    END IF;

    RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_room_update_cinema_stats ON public.room;
CREATE TRIGGER trg_room_update_cinema_stats
AFTER INSERT OR UPDATE OF cinema_id, total_seats, deleted_at OR DELETE ON public.room
FOR EACH ROW
EXECUTE FUNCTION public.fn_trg_update_cinema_stats();


-- ĐỒNG BỘ LẠI DỮ LIỆU THUỘC TÍNH DẪN XUẤT HIỆN CÓ
UPDATE public.room r
SET total_seats = (
    SELECT COUNT(*)
    FROM public.seat s
    WHERE s.room_id = r.id
      AND s.deleted_at IS NULL
);

UPDATE public.cinema c
SET total_rooms = (
        SELECT COUNT(*)
        FROM public.room r
        WHERE r.cinema_id = c.id
          AND r.deleted_at IS NULL
    ),
    total_capacity = COALESCE((
        SELECT SUM(r.total_seats)
        FROM public.room r
        WHERE r.cinema_id = c.id
          AND r.deleted_at IS NULL
    ), 0);