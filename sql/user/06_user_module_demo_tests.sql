-- =============================================================================
-- BTL2 - DATABASE SYSTEMS
-- MODULE 1: USERS & MEMBERSHIP (MODULE MẪU)
-- FILE: 06_user_module_demo_tests.sql
-- YÊU CẦU: Chuẩn bị các câu lệnh mẫu để TEST & DEMO khi báo cáo
-- =============================================================================

-- =============================================================================
-- 1. TEST MỤC 2.1: STORED PROCEDURES (INSERT, UPDATE, DELETE)
-- =============================================================================

-- Case 1.1: INSERT thành công
DO $$
DECLARE
    v_id UUID;
BEGIN
    CALL sp_insert_user(
        'DEMO01', 
        'Demo Người Dùng Mới', 
        'demo_user01@gmail.com', 
        '0912999888', 
        '2000-01-01', 
        'Hồ Chí Minh', 
        'pass123', 
        'customer', 
        v_id
    );
    RAISE NOTICE 'Created User with ID: %', v_id;
END;
$$;

-- Case 1.2: INSERT thất bại do tuổi < 13 (Test thông báo lỗi cụ thể)
-- KỲ VỌNG: Lỗi "Khách hàng sinh ngày ... chưa đủ 13 tuổi"
-- CALL sp_insert_user('DEMO_FAIL', 'Bé Nhỏ', 'kid@gmail.com', '0912111222', '2020-01-01', 'Hà Nội', 'pass', 'customer', NULL);

-- Case 1.3: INSERT thất bại do Email sai định dạng
-- KỲ VỌNG: Lỗi "Địa chỉ email không đúng định dạng chuẩn"
-- CALL sp_insert_user('DEMO_FAIL2', 'User Sai Mail', 'not-an-email', '0912111222', '1995-01-01', 'Hà Nội', 'pass', 'customer', NULL);

-- Case 1.4: UPDATE thông tin người dùng
CALL sp_update_user(
    '11111111-1111-1111-1111-111111111101', 
    'Nguyễn Văn An (Đã Đổi Tên)', 
    '0912345999', 
    'Đà Nẵng', 
    true
);

-- Case 1.5: DELETE - Test trường hợp bị từ chối do có điểm hoặc đơn vé
-- KỲ VỌNG: Bị từ chối vì còn điểm CGV Points
-- CALL sp_delete_user('11111111-1111-1111-1111-111111111101');


-- =============================================================================
-- 2. TEST MỤC 2.2: TRIGGERS
-- =============================================================================

-- Case 2.1: Test Trigger 2.2.1 (Kiểm tra vi phạm số dư điểm khi đổi)
-- KỲ VỌNG: Lỗi "Hội viên [CGV-MB-001] hiện chỉ có 120 điểm, không đủ để đổi 500 điểm!"
-- INSERT INTO "point_transaction" ("membership_id", "type", "points", "balance_after")
-- VALUES ('22222222-2222-2222-2222-222222222201', 'redeem', 500, 0);

-- Case 2.2: Test Trigger 2.2.2 (Tự động cập nhật thuộc tính dẫn xuất & thăng hạng VIP)
-- Cộng 900 điểm -> Tổng tích lũy thành 120 + 900 = 1020 (Đạt mốc >= 1000 để lên hạng VIP)
INSERT INTO "point_transaction" ("id", "membership_id", "type", "points", "balance_after", "created_at")
VALUES (uuid_generate_v4(), '22222222-2222-2222-2222-222222222201', 'earn', 900, 0, now());

-- Kiểm tra lại bảng membership xem tier đã tự động chuyển sang 'vip' chưa:
SELECT member_code, cgv_points, total_points_earned, tier 
FROM "membership" 
WHERE id = '22222222-2222-2222-2222-222222222201';


-- =============================================================================
-- 3. TEST MỤC 2.3: QUERY STORED PROCEDURES
-- =============================================================================

-- Test Procedure 1 (Query có WHERE và ORDER BY)
DO $$
DECLARE
    cur REFCURSOR;
    rec RECORD;
BEGIN
    CALL sp_get_users_with_membership(NULL, NULL, cur);
    LOOP
        FETCH cur INTO rec;
        EXIT WHEN NOT FOUND;
        RAISE NOTICE 'User: % - Code: % - Tier: % - Points: %', rec.user_name, rec.user_code, rec.tier, rec.cgv_points;
    END LOOP;
    CLOSE cur;
END;
$$;

-- Test Procedure 2 (Query có Aggregate + GROUP BY + HAVING + WHERE + ORDER BY)
DO $$
DECLARE
    cur REFCURSOR;
    rec RECORD;
BEGIN
    CALL sp_report_user_spending_by_tier(NULL, 100000, cur);
    LOOP
        FETCH cur INTO rec;
        EXIT WHEN NOT FOUND;
        RAISE NOTICE 'Top Spender: % - Tier: % - Total: %', rec.user_name, rec.membership_tier, rec.total_amount_spent;
    END LOOP;
    CLOSE cur;
END;
$$;


-- =============================================================================
-- 4. TEST MỤC 2.4: FUNCTIONS
-- =============================================================================

-- Test Function 1 (Dùng CURSOR + LOOP + IF tính voucher % theo lịch sử booking)
SELECT 
    u.id, 
    u.name, 
    fn_calculate_user_loyalty_voucher(u.id) AS voucher_percent
FROM "users" u
WHERE u.deleted_at IS NULL;

-- Test Function 2 (Dùng CURSOR + LOOP + IF kiểm toán lịch sử giao dịch điểm)
SELECT 
    m.id, 
    m.member_code, 
    fn_audit_user_point_history(m.id, EXTRACT(YEAR FROM CURRENT_DATE)::INT) AS error_discrepancy_count
FROM "membership" m;
