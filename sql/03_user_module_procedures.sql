-- =============================================================================
-- BTL2 - DATABASE SYSTEMS
-- MODULE 1: USERS & MEMBERSHIP (MODULE MẪU)
-- FILE: 03_user_module_procedures.sql
-- YÊU CẦU: Mục 2.1 (CRUD Procedures cho 1 bảng) & Mục 2.3 (Query Procedures)
-- =============================================================================

-- =============================================================================
-- MỤC 2.1: STORED PROCEDURES INSERT / UPDATE / DELETE CHO BẢNG USERS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. PROCEDURE THÊM NGƯỜI DÙNG (sp_insert_user)
-- Kiểm tra: Tên không rỗng, Email hợp lệ & duy nhất, SĐT hợp lệ (10-11 số),
-- Tuổi >= 13, Role hợp lệ ('customer', 'staff', 'admin').
-- Đồng thời tự động khởi tạo Thẻ hội viên (Membership) ban đầu nếu là customer.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_insert_user(
    p_code VARCHAR,
    p_name VARCHAR,
    p_email VARCHAR,
    p_phone VARCHAR,
    p_dob DATE,
    p_province VARCHAR,
    p_password VARCHAR,
    p_role VARCHAR DEFAULT 'customer',
    INOUT p_new_user_id UUID DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_calculated_age INT;
BEGIN
    -- 1. Validate Tên
    IF p_name IS NULL OR length(trim(p_name)) < 2 THEN
        RAISE EXCEPTION 'Lỗi nhập liệu: Tên người dùng không được để trống và phải có ít nhất 2 ký tự!';
    END IF;

    -- 2. Validate Mã người dùng (code)
    IF p_code IS NULL OR length(trim(p_code)) = 0 THEN
        RAISE EXCEPTION 'Lỗi nhập liệu: Mã người dùng (code) không được để trống!';
    END IF;

    IF EXISTS (SELECT 1 FROM "users" WHERE "code" = trim(p_code)) THEN
        RAISE EXCEPTION 'Lỗi ràng buộc: Mã người dùng "%" đã tồn tại trong hệ thống!', p_code;
    END IF;

    -- 3. Validate Email
    IF p_email IS NULL OR p_email !~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
        RAISE EXCEPTION 'Lỗi nhập liệu: Địa chỉ email "%" không đúng định dạng chuẩn (vd: user@example.com)!', p_email;
    END IF;

    IF EXISTS (SELECT 1 FROM "users" WHERE lower("email") = lower(trim(p_email)) AND "deleted_at" IS NULL) THEN
        RAISE EXCEPTION 'Lỗi ràng buộc: Email "%" đã được đăng ký bởi người dùng khác!', p_email;
    END IF;

    -- 4. Validate Số điện thoại (10 - 11 chữ số)
    IF p_phone IS NULL OR p_phone !~ '^[0-9]{10,11}$' THEN
        RAISE EXCEPTION 'Lỗi nhập liệu: Số điện thoại "%" không hợp lệ! SĐT phải chứa 10-11 chữ số.', p_phone;
    END IF;

    -- 5. Validate Ngày sinh (Độ tuổi xem phim tối thiểu >= 13 tuổi)
    IF p_dob IS NOT NULL THEN
        v_calculated_age := date_part('year', age(CURRENT_DATE, p_dob));
        IF v_calculated_age < 13 THEN
            RAISE EXCEPTION 'Lỗi độ tuổi: Khách hàng sinh ngày % hiện % tuổi, chưa đủ 13 tuổi để tạo tài khoản cá nhân!', p_dob, v_calculated_age;
        END IF;
    END IF;

    -- 6. Validate Role
    IF p_role NOT IN ('customer', 'staff', 'admin') THEN
        RAISE EXCEPTION 'Lỗi vai trò: Vai trò "%" không hợp lệ. Chỉ chấp nhận customer, staff hoặc admin.', p_role;
    END IF;

    -- Thực hiện INSERT vào bảng users
    p_new_user_id := uuid_generate_v4();
    INSERT INTO "users" (
        "id", "code", "name", "email", "phone", "dob", "province", 
        "password", "salt", "role", "is_active", "created_at", "updated_at"
    )
    VALUES (
        p_new_user_id, trim(p_code), trim(p_name), lower(trim(p_email)), trim(p_phone), 
        p_dob, trim(p_province), p_password, 'salt_default', p_role::"public"."users_role_enum", true, now(), now()
    );

    -- Khởi tạo luôn thẻ membership nếu vai trò là khách hàng
    IF p_role = 'customer' THEN
        INSERT INTO "membership" (
            "id", "user_id", "member_code", "tier", "cgv_points", 
            "total_points_earned", "tier_expiry_date", "is_active", "created_at"
        )
        VALUES (
            uuid_generate_v4(), p_new_user_id, 'MB-' || trim(p_code), 'standard', 
            0, 0, (CURRENT_DATE + INTERVAL '1 year'), true, now()
        );
    END IF;

    RAISE NOTICE 'Thành công: Đã tạo người dùng mới id=% với mã=%', p_new_user_id, p_code;
END;
$$;


-- -----------------------------------------------------------------------------
-- 2. PROCEDURE CẬP NHẬT NGƯỜI DÙNG (sp_update_user)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_update_user(
    p_user_id UUID,
    p_name VARCHAR,
    p_phone VARCHAR,
    p_province VARCHAR,
    p_is_active BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Kiểm tra sự tồn tại của người dùng
    IF NOT EXISTS (SELECT 1 FROM "users" WHERE "id" = p_user_id AND "deleted_at" IS NULL) THEN
        RAISE EXCEPTION 'Không tìm thấy: Người dùng với ID "%" không tồn tại hoặc đã bị xóa!', p_user_id;
    END IF;

    -- Validate Tên nếu có cập nhật
    IF p_name IS NOT NULL AND length(trim(p_name)) < 2 THEN
        RAISE EXCEPTION 'Lỗi nhập liệu: Tên người dùng không được ít hơn 2 ký tự!';
    END IF;

    -- Validate SĐT nếu có cập nhật
    IF p_phone IS NOT NULL AND p_phone !~ '^[0-9]{10,11}$' THEN
        RAISE EXCEPTION 'Lỗi nhập liệu: Số điện thoại "%" không đúng định dạng (10-11 chữ số)!', p_phone;
    END IF;

    -- Thực hiện UPDATE
    UPDATE "users"
    SET 
        "name" = COALESCE(trim(p_name), "name"),
        "phone" = COALESCE(trim(p_phone), "phone"),
        "province" = COALESCE(trim(p_province), "province"),
        "is_active" = COALESCE(p_is_active, "is_active"),
        "updated_at" = now()
    WHERE "id" = p_user_id;

    RAISE NOTICE 'Thành công: Đã cập nhật thông tin người dùng id=%', p_user_id;
END;
$$;


-- -----------------------------------------------------------------------------
-- 3. PROCEDURE XÓA NGƯỜI DÙNG (sp_delete_user)
-- QUY ĐỊNH NGHIỆP VỤ (Theo yêu cầu doc-2.md):
-- - KHI NÀO KHÔNG ĐƯỢC XÓA:
--   1. Người dùng có đơn đặt vé (Booking) đang ở trạng thái 'confirmed' hoặc 'pending' -> KHÔNG ĐƯỢC XÓA
--      (để bảo vệ dữ liệu kế toán, vé đã xuất, tránh mất dấu vết lịch sử thanh toán).
--   2. Người dùng vẫn còn điểm tích lũy cgv_points > 0 trong thẻ hội viên -> KHÔNG ĐƯỢC XÓA
--      (bảo vệ quyền lợi tài sản điểm của khách hàng, phòng ngừa tranh chấp khiếu nại).
-- - KHI NÀO ĐƯỢC XÓA:
--   Người dùng không còn điểm thưởng nào và không có giao dịch đặt vé đang chờ/hoàn tất.
--   Thực hiện xóa mềm (Soft Delete bằng cách gán deleted_at = now()) để đảm bảo toàn vẹn dữ liệu quan hệ.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_delete_user(
    p_user_id UUID
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_active_bookings_count INT;
    v_user_points INT;
BEGIN
    -- 1. Kiểm tra tồn tại
    IF NOT EXISTS (SELECT 1 FROM "users" WHERE "id" = p_user_id AND "deleted_at" IS NULL) THEN
        RAISE EXCEPTION 'Lỗi thao tác: Người dùng ID "%" không tồn tại hoặc đã được xóa trước đó!', p_user_id;
    END IF;

    -- 2. Kiểm tra ràng buộc đơn đặt vé (Booking)
    SELECT COUNT(*) INTO v_active_bookings_count
    FROM "booking"
    WHERE "user_id" = p_user_id AND "status" IN ('confirmed', 'pending');

    IF v_active_bookings_count > 0 THEN
        RAISE EXCEPTION 'Từ chối xóa: Khách hàng hiện có % đơn đặt vé chưa hoàn tất hoặc đã thanh toán. Cần hủy/lưu trữ đơn vé trước khi xóa tài khoản!', v_active_bookings_count;
    END IF;

    -- 3. Kiểm tra số dư điểm tích lũy hội viên
    SELECT COALESCE("cgv_points", 0) INTO v_user_points
    FROM "membership"
    WHERE "user_id" = p_user_id;

    IF v_user_points > 0 THEN
        RAISE EXCEPTION 'Từ chối xóa: Khách hàng còn % điểm CGV Point chưa sử dụng. Không thể xóa tài khoản có tài sản điểm tích lũy!', v_user_points;
    END IF;

    -- 4. Đủ điều kiện xóa -> Thực hiện Soft Delete (Xóa mềm)
    UPDATE "users"
    SET "deleted_at" = now(), "is_active" = false
    WHERE "id" = p_user_id;

    -- Vô hiệu hóa luôn thẻ hội viên
    UPDATE "membership"
    SET "is_active" = false, "deleted_at" = now()
    WHERE "user_id" = p_user_id;

    RAISE NOTICE 'Thành công: Đã xóa mềm người dùng id=% khỏi hệ thống.', p_user_id;
END;
$$;


-- =============================================================================
-- MỤC 2.3: STORED PROCEDURES TRUY VẤN DỮ LIỆU (QUERY PROCEDURES)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- PROCEDURE 1 (Mục 2.3 - Query từ 2+ bảng có WHERE và ORDER BY)
-- Tìm kiếm danh sách người dùng kèm thông tin thẻ hội viên theo tỉnh/thành và hạng thẻ
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_get_users_with_membership(
    p_province VARCHAR,
    p_tier VARCHAR,
    INOUT p_refcursor REFCURSOR = 'cur_users_mb'
)
LANGUAGE plpgsql
AS $$
BEGIN
    OPEN p_refcursor FOR
        SELECT 
            u.id AS user_id,
            u.code AS user_code,
            u.name AS user_name,
            u.email,
            u.phone,
            u.province,
            m.member_code,
            m.tier,
            m.cgv_points,
            m.total_points_earned,
            u.created_at
        FROM "users" u
        INNER JOIN "membership" m ON u.id = m.user_id
        WHERE u.deleted_at IS NULL
          AND (p_province IS NULL OR u.province ILIKE '%' || p_province || '%')
          AND (p_tier IS NULL OR m.tier::TEXT = p_tier)
        ORDER BY m.cgv_points DESC, u.created_at DESC;
END;
$$;


-- -----------------------------------------------------------------------------
-- PROCEDURE 2 (Mục 2.3 - Aggregate, GROUP BY, HAVING, WHERE, ORDER BY, Join >= 2 bảng)
-- Thống kê tổng tiền chi tiêu và số đơn đặt vé của người dùng theo hạng thẻ,
-- chỉ lấy những khách hàng có tổng chi tiêu đạt từ mức p_min_total_spent trở lên.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_report_user_spending_by_tier(
    p_tier VARCHAR,
    p_min_total_spent NUMERIC,
    INOUT p_refcursor REFCURSOR = 'cur_spending_report'
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Validate tham số HAVING
    IF p_min_total_spent IS NOT NULL AND p_min_total_spent < 0 THEN
        RAISE EXCEPTION 'Lỗi tham số: Mức chi tiêu tối thiểu (p_min_total_spent) không thể là số âm!';
    END IF;

    OPEN p_refcursor FOR
        SELECT 
            u.id AS user_id,
            u.code AS user_code,
            u.name AS user_name,
            u.email,
            m.tier AS membership_tier,
            m.cgv_points,
            COUNT(b.id) AS total_successful_bookings,
            COALESCE(SUM(b.final_amount), 0) AS total_amount_spent,
            MAX(b.created_at) AS last_booking_time
        FROM "users" u
        INNER JOIN "membership" m ON u.id = m.user_id
        INNER JOIN "booking" b ON u.id = b.user_id
        WHERE u.deleted_at IS NULL
          AND b.status = 'confirmed'
          AND (p_tier IS NULL OR m.tier::TEXT = p_tier)
        GROUP BY u.id, u.code, u.name, u.email, m.tier, m.cgv_points
        HAVING COALESCE(SUM(b.final_amount), 0) >= COALESCE(p_min_total_spent, 0)
        ORDER BY total_amount_spent DESC, total_successful_bookings DESC;
END;
$$;
