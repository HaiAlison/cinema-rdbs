-- =============================================================================
-- BTL2 - DATABASE SYSTEMS
-- MODULE 1: USERS & MEMBERSHIP (MODULE MẪU)
-- FILE: 04_user_module_triggers.sql
-- YÊU CẦU: Mục 2.2.1 (Trigger kiểm tra ràng buộc ngữ nghĩa) 
--        & Mục 2.2.2 (Trigger tính toán thuộc tính dẫn xuất)
-- =============================================================================

-- =============================================================================
-- MỤC 2.2.1: TRIGGER KIỂM TRA RÀNG BUỘC NGHIỆP VỤ (BUSINESS CONSTRAINT TRIGGER)
-- -----------------------------------------------------------------------------
-- 1. Mô tả ràng buộc nghiệp vụ:
--    Khi hội viên thực hiện giao dịch đổi điểm (redeem) hoặc bị trừ điểm, số điểm bị trừ
--    tuyệt đối không được vượt quá số dư điểm khả dụng hiện tại (cgv_points) trong thẻ.
--    Vì đây là ràng buộc phụ thuộc vào số dư hiện tại của bảng "membership" (liên bảng),
--    câu lệnh CHECK thông thường trong CREATE TABLE không thể kiểm tra được,
--    bắt buộc phải sử dụng TRIGGER.
--
-- 2. Các thao tác DML có thể vi phạm:
--    - INSERT trên bảng "point_transaction" (khi thêm giao dịch type = 'redeem')
--    - UPDATE trên bảng "point_transaction" (khi sửa điểm của giao dịch)
-- =============================================================================

CREATE OR REPLACE FUNCTION trg_fn_check_redeem_point_balance()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_points INT;
    v_member_code VARCHAR;
BEGIN
    -- Chỉ kiểm tra khi giao dịch là loại trừ điểm (redeem)
    IF NEW.type = 'redeem' THEN
        -- Đảm bảo điểm trừ phải là giá trị âm hoặc giá trị trừ hợp lệ
        -- Lấy số dư điểm hiện tại của hội viên từ bảng membership
        SELECT "cgv_points", "member_code" 
        INTO v_current_points, v_member_code
        FROM "membership"
        WHERE "id" = NEW.membership_id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Lỗi toàn vẹn: Không tìm thấy thẻ hội viên ID "%" tương ứng!', NEW.membership_id;
        END IF;

        -- Giả sử points của redeem được lưu là số dương (số điểm đem đổi) hoặc số âm
        -- Ở đây chuẩn hóa: nếu points > 0 là số điểm cần đổi
        IF ABS(NEW.points) > v_current_points THEN
            RAISE EXCEPTION 'Vi phạm nghiệp vụ đổi điểm: Hội viên [%] hiện chỉ có % điểm, không đủ để đổi % điểm!', 
                v_member_code, v_current_points, ABS(NEW.points);
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_check_redeem_point_balance ON "point_transaction";
CREATE TRIGGER trg_check_redeem_point_balance
BEFORE INSERT OR UPDATE ON "point_transaction"
FOR EACH ROW
EXECUTE FUNCTION trg_fn_check_redeem_point_balance();


-- =============================================================================
-- MỤC 2.2.2: TRIGGER TÍNH TOÁN THUỘC TÍNH DẪN XUẤT (DERIVED ATTRIBUTE TRIGGER)
-- -----------------------------------------------------------------------------
-- 1. Mô tả thuộc tính dẫn xuất:
--    - Thuộc tính 1: "cgv_points" (Số điểm khả dụng) trong bảng "membership"
--      phải tự động tăng/giảm dựa vào các giao dịch trong "point_transaction".
--    - Thuộc tính 2: "total_points_earned" (Tổng điểm tích lũy trọn đời) trong bảng "membership"
--      được cộng dồn mỗi khi có giao dịch type = 'earn' hoặc 'bonus'.
--    - Thuộc tính 3: "tier" (Hạng thẻ hội viên: standard -> vip -> vvip) được tự động
--      nâng cấp dựa trên giá trị của "total_points_earned" đã tính toán ở trên:
--         + total_points_earned >= 3000 -> VVIP
--         + total_points_earned >= 1000 -> VIP
--         + Còn lại -> STANDARD
--
-- 2. Các thao tác DML tác động làm thay đổi thuộc tính:
--    - INSERT một giao dịch mới vào bảng "point_transaction".
-- =============================================================================

CREATE OR REPLACE FUNCTION trg_fn_update_membership_derived_attributes()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_point_change INT;
    v_new_total_earned INT;
    v_new_cgv_points INT;
    v_new_tier "public"."membership_tier_enum";
BEGIN
    -- Xác định số điểm tăng (+) hoặc giảm (-)
    IF NEW.type = 'redeem' THEN
        v_point_change := -ABS(NEW.points);
    ELSE
        v_point_change := ABS(NEW.points);
    END IF;

    -- Tính toán giá trị dẫn xuất cgv_points mới và total_points_earned mới
    -- Lưu ý nguyên tắc: Thuộc tính cơ sở (total_points_earned) được tính trước,
    -- sau đó mới xét hạng tier từ giá trị này.
    UPDATE "membership"
    SET 
        -- Cập nhật số dư điểm khả dụng
        "cgv_points" = "cgv_points" + v_point_change,
        -- Nếu là tích lũy điểm mới thì cộng dồn vào tổng điểm tích lũy trọn đời
        "total_points_earned" = CASE 
            WHEN NEW.type IN ('earn', 'bonus') THEN "total_points_earned" + ABS(NEW.points)
            ELSE "total_points_earned"
        END,
        "updated_at" = now()
    WHERE "id" = NEW.membership_id
    RETURNING "cgv_points", "total_points_earned" INTO v_new_cgv_points, v_new_total_earned;

    -- Cập nhật số dư sau giao dịch (balance_after) vào chính bản ghi point_transaction
    NEW.balance_after := v_new_cgv_points;

    -- Tự động đánh giá và nâng hạng thẻ (tier) dựa trên tổng điểm tích lũy (total_points_earned)
    IF v_new_total_earned >= 3000 THEN
        v_new_tier := 'vvip';
    ELSIF v_new_total_earned >= 1000 THEN
        v_new_tier := 'vip';
    ELSE
        v_new_tier := 'standard';
    END IF;

    UPDATE "membership"
    SET "tier" = v_new_tier
    WHERE "id" = NEW.membership_id;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_update_membership_derived_attributes ON "point_transaction";
CREATE TRIGGER trg_update_membership_derived_attributes
BEFORE INSERT ON "point_transaction"
FOR EACH ROW
EXECUTE FUNCTION trg_fn_update_membership_derived_attributes();
