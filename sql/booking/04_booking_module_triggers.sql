-- =============================================================================
-- BÀI TẬP LỚN 2 - HỆ CƠ SỞ DỮ LIỆU (HK261)
-- MODULE 5: BOOKING, COMBO & PAYMENT (THÀNH VIÊN 5)
-- FILE: 04_booking_module_triggers.sql
-- YÊU CẦU: Mục 2.2.1 (Trigger ràng buộc nghiệp vụ) & Mục 2.2.2 (Trigger thuộc tính dẫn xuất)
-- =============================================================================

SET client_encoding = 'UTF8';

-- =============================================================================
-- MỤC 2.2.1: TRIGGER KIỂM TRA RÀNG BUỘC NGHIỆP VỤ (BUSINESS CONSTRAINT TRIGGER)
-- Ràng buộc:
--   1. Chống đặt trùng ghế trong cùng một suất chiếu giữa các giao dịch khác nhau.
--   2. Ghế được đặt bắt buộc phải thuộc đúng phòng chiếu của suất chiếu đó.
--   3. Không cho phép thêm/kích hoạt vé vào đơn đã bị hủy, hết hạn hoặc hoàn tiền.
-- Giải thích: Cần JOIN liên bảng (booking_detail, booking, showtime, seat) và khóa
-- đồng thời theo suất chiếu nên CHECK constraint đơn bảng không thể kiểm tra được.
-- =============================================================================
CREATE OR REPLACE FUNCTION public.fn_trg_prevent_seat_double_booking()
RETURNS TRIGGER AS $$
DECLARE
    v_showtime_id UUID;
    v_booking_status public.booking_status_enum;
    v_current_booking_code VARCHAR(50);
    v_showtime_room_id UUID;
    v_seat_room_id UUID;
    v_conflict_booking_code VARCHAR(50);
    v_seat_label VARCHAR(50);
BEGIN
    -- Nếu dòng vé bị hủy thì bỏ qua kiểm tra trùng ghế
    IF NEW.status = 'cancelled' THEN
        RETURN NEW;
    END IF;

    -- 1. Lấy thông tin booking & suất chiếu
    SELECT b.showtime_id, b.status, b.booking_code, st.room_id
    INTO v_showtime_id, v_booking_status, v_current_booking_code, v_showtime_room_id
    FROM public.booking b
    JOIN public.showtime st ON b.showtime_id = st.id
    WHERE b.id = NEW.booking_id AND b.deleted_at IS NULL;

    IF v_showtime_id IS NULL THEN
        RAISE EXCEPTION 'Lỗi toàn vẹn: Không tìm thấy đơn đặt vé ID "%" hợp lệ!', NEW.booking_id;
    END IF;

    IF v_booking_status IN ('cancelled', 'expired', 'refunded') THEN
        RAISE EXCEPTION 'Không thể thêm/kích hoạt ghế: Đơn đặt vé "%" đang ở trạng thái "%"!',
            v_current_booking_code, v_booking_status;
    END IF;

    -- 2. Kiểm tra ghế tồn tại và nằm đúng phòng chiếu của suất chiếu
    SELECT room_id INTO v_seat_room_id
    FROM public.seat
    WHERE id = NEW.seat_id AND deleted_at IS NULL;

    IF v_seat_room_id IS NULL THEN
        RAISE EXCEPTION 'Không tìm thấy ghế với ID "%"!', NEW.seat_id;
    END IF;

    IF v_seat_room_id <> v_showtime_room_id THEN
        RAISE EXCEPTION 'SAI PHÒNG CHIẾU: Ghế "%" (ID: %) không thuộc phòng chiếu của suất chiếu đơn "%"!',
            COALESCE(NEW.seat_label, ''), NEW.seat_id, v_current_booking_code;
    END IF;

    -- 3. Khóa mức suất chiếu trong transaction để tránh race condition khi đặt đồng thời
    PERFORM 1 FROM public.showtime WHERE id = v_showtime_id FOR UPDATE;

    -- 4. Kiểm tra ghế này đã được đơn hợp lệ khác giữ/mua trong cùng suất chiếu chưa
    SELECT b.booking_code, bd.seat_label
    INTO v_conflict_booking_code, v_seat_label
    FROM public.booking_detail bd
    JOIN public.booking b ON bd.booking_id = b.id
    WHERE b.showtime_id = v_showtime_id
      AND bd.seat_id = NEW.seat_id
      AND bd.status <> 'cancelled'
      AND bd.deleted_at IS NULL
      AND b.deleted_at IS NULL
      AND b.id <> NEW.booking_id
      AND (
          b.status = 'confirmed'
          OR (b.status = 'pending' AND (b.expired_at IS NULL OR b.expired_at > now()))
      )
    LIMIT 1;

    IF v_conflict_booking_code IS NOT NULL THEN
        RAISE EXCEPTION 'XUNG ĐỘT GHẾ: Ghế "%" (ID: %) trong suất chiếu này đã được đặt hoặc đang giữ chỗ bởi đơn vé "%"!',
            COALESCE(NEW.seat_label, v_seat_label), NEW.seat_id, v_conflict_booking_code;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS TRG_prevent_seat_double_booking ON public.booking_detail;
CREATE TRIGGER TRG_prevent_seat_double_booking
BEFORE INSERT OR UPDATE OF seat_id, booking_id, status
ON public.booking_detail
FOR EACH ROW
EXECUTE FUNCTION public.fn_trg_prevent_seat_double_booking();


-- =============================================================================
-- MỤC 2.2.2: TRIGGER TÍNH TOÁN THUỘC TÍNH DẪN XUẤT (DERIVED ATTRIBUTE TRIGGER)
-- Thứ tự phụ thuộc:
--   - B1: ticket_total = SUM(booking_detail.price WHERE status <> 'cancelled')
--   - B2: combo_total  = SUM(booking_combo.subtotal)
--   - A : final_amount = GREATEST(0, B1 + B2 - discount_amount - points_used * 1000)
--   - C : points_earned = FLOOR(A * 0.05 / 1000)
-- Đồng thời:
--   - Tự động tính booking_combo.subtotal = quantity * unit_price trước khi ghi.
--   - Khóa cứng chi tiết vé/combo nếu đơn booking đã 'confirmed' hoặc 'refunded'.
--   - Đồng bộ lại final_amount & points_earned khi discount_amount/points_used thay đổi trên booking.
-- =============================================================================

-- Hàm dùng chung tính lại B1, B2 rồi mới tính A, C
CREATE OR REPLACE FUNCTION public.fn_recalculate_booking_totals(p_booking_id UUID)
RETURNS VOID AS $$
DECLARE
    v_ticket_total NUMERIC(12,2) := 0;
    v_combo_total NUMERIC(12,2) := 0;
    v_discount NUMERIC(12,2) := 0;
    v_points_used INT := 0;
    v_final_amount NUMERIC(12,2) := 0;
    v_points_earned INT := 0;
BEGIN
    -- Bước 1: Tính thuộc tính cơ sở B1 (ticket_total)
    SELECT COALESCE(SUM(price), 0)
    INTO v_ticket_total
    FROM public.booking_detail
    WHERE booking_id = p_booking_id
      AND status <> 'cancelled'
      AND deleted_at IS NULL;

    -- Bước 2: Tính thuộc tính cơ sở B2 (combo_total)
    SELECT COALESCE(SUM(subtotal), 0)
    INTO v_combo_total
    FROM public.booking_combo
    WHERE booking_id = p_booking_id
      AND deleted_at IS NULL;

    -- Bước 3: Lấy các thông số chiết khấu hiện tại của đơn
    SELECT COALESCE(discount_amount, 0), COALESCE(points_used, 0)
    INTO v_discount, v_points_used
    FROM public.booking
    WHERE id = p_booking_id;

    -- Bước 4: Tính thuộc tính dẫn xuất A (final_amount) từ B1 và B2 vừa tính
    v_final_amount := GREATEST(0, (v_ticket_total + v_combo_total) - v_discount - (v_points_used * 1000));

    -- Bước 5: Tính thuộc tính dẫn xuất C (points_earned) dựa trên A
    v_points_earned := FLOOR(v_final_amount * 0.05 / 1000);

    -- Bước 6: Cập nhật đồng bộ vào bảng booking
    UPDATE public.booking
    SET ticket_total = v_ticket_total,
        combo_total = v_combo_total,
        final_amount = v_final_amount,
        points_earned = v_points_earned,
        updated_at = now()
    WHERE id = p_booking_id;
END;
$$ LANGUAGE plpgsql;

-- Trigger bảo vệ không cho thêm/sửa/xóa vé/combo khi đơn đã confirmed/refunded
CREATE OR REPLACE FUNCTION public.fn_trg_guard_immutable_confirmed_items()
RETURNS TRIGGER AS $$
DECLARE
    v_target_booking_id UUID;
    v_status public.booking_status_enum;
    v_booking_code VARCHAR(50);
BEGIN
    v_target_booking_id := CASE WHEN TG_OP = 'DELETE' THEN OLD.booking_id ELSE NEW.booking_id END;

    SELECT status, booking_code INTO v_status, v_booking_code
    FROM public.booking
    WHERE id = v_target_booking_id;

    IF v_status IN ('confirmed', 'refunded') THEN
        -- Riêng bảng booking_detail vẫn cho phép nhân viên soát vé chuyển status 'active' -> 'used'
        IF TG_TABLE_NAME = 'booking_detail' AND TG_OP = 'UPDATE'
           AND OLD.price = NEW.price AND OLD.seat_id = NEW.seat_id AND OLD.booking_id = NEW.booking_id
           AND OLD.status = 'active' AND NEW.status = 'used' THEN
            RETURN NEW;
        END IF;

        RAISE EXCEPTION 'KHÓA HÓA ĐƠN: Không thể thêm/sửa/xóa chi tiết khi đơn vé "%" đã ở trạng thái "%"!',
            v_booking_code, v_status;
    END IF;

    -- Tự động tính subtotal cho booking_combo trước khi CHECK constraint kiểm tra
    IF TG_TABLE_NAME = 'booking_combo' AND TG_OP IN ('INSERT', 'UPDATE') THEN
        NEW.subtotal := NEW.quantity * NEW.unit_price;
    END IF;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS TRG_guard_booking_detail_immutable ON public.booking_detail;
CREATE TRIGGER TRG_guard_booking_detail_immutable
BEFORE INSERT OR UPDATE OR DELETE
ON public.booking_detail
FOR EACH ROW
EXECUTE FUNCTION public.fn_trg_guard_immutable_confirmed_items();

DROP TRIGGER IF EXISTS TRG_guard_and_calc_booking_combo ON public.booking_combo;
CREATE TRIGGER TRG_guard_and_calc_booking_combo
BEFORE INSERT OR UPDATE OR DELETE
ON public.booking_combo
FOR EACH ROW
EXECUTE FUNCTION public.fn_trg_guard_immutable_confirmed_items();

-- Trigger Function bắt sự kiện AFTER trên booking_detail
CREATE OR REPLACE FUNCTION public.fn_trg_sync_detail_totals()
RETURNS TRIGGER AS $$
DECLARE
    v_target_booking_id UUID;
BEGIN
    v_target_booking_id := CASE WHEN TG_OP = 'DELETE' THEN OLD.booking_id ELSE NEW.booking_id END;
    PERFORM public.fn_recalculate_booking_totals(v_target_booking_id);

    IF TG_OP = 'UPDATE' AND OLD.booking_id <> NEW.booking_id THEN
        PERFORM public.fn_recalculate_booking_totals(OLD.booking_id);
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS TRG_sync_booking_ticket_total ON public.booking_detail;
CREATE TRIGGER TRG_sync_booking_ticket_total
AFTER INSERT OR UPDATE OF price, status, deleted_at, booking_id OR DELETE
ON public.booking_detail
FOR EACH ROW
EXECUTE FUNCTION public.fn_trg_sync_detail_totals();

-- Trigger Function bắt sự kiện AFTER trên booking_combo
CREATE OR REPLACE FUNCTION public.fn_trg_sync_combo_totals()
RETURNS TRIGGER AS $$
DECLARE
    v_target_booking_id UUID;
BEGIN
    v_target_booking_id := CASE WHEN TG_OP = 'DELETE' THEN OLD.booking_id ELSE NEW.booking_id END;
    PERFORM public.fn_recalculate_booking_totals(v_target_booking_id);

    IF TG_OP = 'UPDATE' AND OLD.booking_id <> NEW.booking_id THEN
        PERFORM public.fn_recalculate_booking_totals(OLD.booking_id);
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS TRG_sync_booking_combo_total ON public.booking_combo;
CREATE TRIGGER TRG_sync_booking_combo_total
AFTER INSERT OR UPDATE OF subtotal, quantity, unit_price, deleted_at, booking_id OR DELETE
ON public.booking_combo
FOR EACH ROW
EXECUTE FUNCTION public.fn_trg_sync_combo_totals();

-- Trigger đồng bộ lại final_amount & points_earned khi UPDATE trực tiếp các cột chiết khấu trên booking
CREATE OR REPLACE FUNCTION public.fn_trg_sync_booking_direct_update()
RETURNS TRIGGER AS $$
BEGIN
    IF pg_trigger_depth() <= 1 THEN
        NEW.final_amount := GREATEST(
            0,
            (COALESCE(NEW.ticket_total, 0) + COALESCE(NEW.combo_total, 0))
            - COALESCE(NEW.discount_amount, 0)
            - (COALESCE(NEW.points_used, 0) * 1000)
        );
        NEW.points_earned := FLOOR(NEW.final_amount * 0.05 / 1000);
        NEW.updated_at := now();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS TRG_sync_booking_direct_update ON public.booking;
CREATE TRIGGER TRG_sync_booking_direct_update
BEFORE UPDATE OF ticket_total, combo_total, discount_amount, points_used
ON public.booking
FOR EACH ROW
EXECUTE FUNCTION public.fn_trg_sync_booking_direct_update();
