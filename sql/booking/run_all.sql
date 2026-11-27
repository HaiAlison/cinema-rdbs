-- =============================================================================
-- BÀI TẬP LỚN 2 - HỆ CƠ SỞ DỮ LIỆU (HK261)
-- MODULE 5: BOOKING, COMBO & PAYMENT (THÀNH VIÊN 5 - ALL-IN-ONE)
-- =============================================================================

SET client_encoding = 'UTF8';

-- 1. Mục 1.1: Tạo bảng và ràng buộc toàn vẹn (PK, FK, CHECK, UNIQUE, CASCADE, INDEX)
\i 01_booking_module_schema.sql

-- 2. Mục 1.2: Nạp dữ liệu mẫu có ý nghĩa (>= 5 dòng/bảng cho 6 bảng)
\i 02_booking_module_sample_data.sql

-- 3. Mục 2.1 & 2.3: Tạo các Stored Procedures (CRUD & Query REFCURSOR)
\i 03_booking_module_procedures.sql

-- 4. Mục 2.2: Tạo các Triggers (Ràng buộc nghiệp vụ & Thuộc tính dẫn xuất)
\i 04_booking_module_triggers.sql

-- 5. Mục 2.4: Tạo các Functions (CURSOR + LOOP + IF)
\i 05_booking_module_functions.sql

-- 6. Kịch bản kiểm thử và trình diễn (Demo Test Scripts)
\i 06_booking_module_demo_tests.sql
