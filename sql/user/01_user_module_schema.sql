-- =============================================================================
-- BTL2 - DATABASE SYSTEMS
-- MODULE 1: USERS & MEMBERSHIP (MODULE MẪU)
-- FILE: 01_user_module_schema.sql
-- YÊU CẦU: Mục 1.1 (Constraints, CHECK, Semantic Constraints)
-- =============================================================================

-- 1. Bổ sung các ràng buộc CHECK cho bảng USERS
-- Kiểm tra định dạng email
ALTER TABLE "users" DROP CONSTRAINT IF EXISTS "chk_users_email_format";
ALTER TABLE "users" ADD CONSTRAINT "chk_users_email_format"
    CHECK ("email" ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

-- Kiểm tra độ dài số điện thoại (từ 10 đến 11 số)
ALTER TABLE "users" DROP CONSTRAINT IF EXISTS "chk_users_phone_format";
ALTER TABLE "users" ADD CONSTRAINT "chk_users_phone_format"
    CHECK ("phone" ~ '^[0-9]{10,11}$');

-- Ràng buộc ngữ nghĩa: Người dùng đăng ký phải từ 13 tuổi trở lên (phù hợp độ tuổi xem phim tối thiểu)
ALTER TABLE "users" DROP CONSTRAINT IF EXISTS "chk_users_age_limit";
ALTER TABLE "users" ADD CONSTRAINT "chk_users_age_limit"
    CHECK ("dob" IS NULL OR "dob" <= (CURRENT_DATE - INTERVAL '13 years'));

-- 2. Bổ sung các ràng buộc CHECK cho bảng MEMBERSHIP
-- Điểm CGV Points không được âm
ALTER TABLE "membership" DROP CONSTRAINT IF EXISTS "chk_membership_points_non_negative";
ALTER TABLE "membership" ADD CONSTRAINT "chk_membership_points_non_negative"
    CHECK ("cgv_points" >= 0);

-- Tổng điểm tích lũy không được âm và phải >= điểm hiện tại
ALTER TABLE "membership" DROP CONSTRAINT IF EXISTS "chk_membership_total_earned";
ALTER TABLE "membership" ADD CONSTRAINT "chk_membership_total_earned"
    CHECK ("total_points_earned" >= 0);
