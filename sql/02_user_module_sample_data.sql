-- =============================================================================
-- BTL2 - DATABASE SYSTEMS
-- MODULE 1: USERS & MEMBERSHIP (MODULE MẪU)
-- FILE: 02_user_module_sample_data.sql
-- YÊU CẦU: Mục 1.2 (Tạo ít nhất 5 dòng dữ liệu mẫu có ý nghĩa cho mỗi bảng)
-- =============================================================================

-- 1. Insert dữ liệu mẫu cho USERS (5 khách hàng + nhân viên với thông tin thực tế)
INSERT INTO "users" ("id", "code", "name", "email", "phone", "dob", "province", "password", "salt", "role", "is_active")
VALUES 
    ('11111111-1111-1111-1111-111111111101', 'USR001', 'Nguyễn Văn An', 'nguyenvanan@gmail.com', '0912345678', '1995-05-15', 'Hồ Chí Minh', 'hash_pw_1', 'salt1', 'customer', true),
    ('11111111-1111-1111-1111-111111111102', 'USR002', 'Trần Thị Bình', 'tranbinh98@yahoo.com', '0987654321', '1998-10-20', 'Hà Nội', 'hash_pw_2', 'salt2', 'customer', true),
    ('11111111-1111-1111-1111-111111111103', 'USR003', 'Lê Hoàng Cường', 'cuong.le@outlook.com', '0903112233', '2001-02-08', 'Đà Nẵng', 'hash_pw_3', 'salt3', 'customer', true),
    ('11111111-1111-1111-1111-111111111104', 'USR004', 'Phạm Minh Đức', 'ducpham_cgv@gmail.com', '0934556677', '1992-12-30', 'Hồ Chí Minh', 'hash_pw_4', 'salt4', 'staff', true),
    ('11111111-1111-1111-1111-111111111105', 'USR005', 'Võ Thảo Hạnh', 'thaohanh_vo@gmail.com', '0945998877', '2004-07-25', 'Cần Thơ', 'hash_pw_5', 'salt5', 'customer', true)
ON CONFLICT ("id") DO NOTHING;

-- 2. Insert dữ liệu mẫu cho MEMBERSHIP (5 thẻ hội viên tương ứng)
INSERT INTO "membership" (  "user_id", "member_code", "tier", "cgv_points", "total_points_earned", "tier_expiry_date", "is_active")
VALUES 
    (   '11111111-1111-1111-1111-111111111101', 'CGV-MB-001', 'standard', 120, 120, '2027-12-31', true),
    ('22222222-2222-2222-2222-222222222202', '11111111-1111-1111-1111-111111111102', 'CGV-MB-002', 'vip', 850, 1450, '2027-12-31', true),
    ('22222222-2222-2222-2222-222222222203', '11111111-1111-1111-1111-111111111103', 'CGV-MB-003', 'vvip', 2400, 3600, '2027-12-31', true),
    ('22222222-2222-2222-2222-222222222204', '11111111-1111-1111-1111-111111111104', 'CGV-MB-004', 'standard', 0, 0, '2027-12-31', true),
    ('22222222-2222-2222-2222-222222222205', '11111111-1111-1111-1111-111111111105', 'CGV-MB-005', 'standard', 50, 50, '2027-12-31', true)
ON CONFLICT ("id") DO NOTHING;
