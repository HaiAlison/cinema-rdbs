-- =============================================================================
-- BÀI TẬP LỚN 2 - HỆ CƠ SỞ DỮ LIỆU (HK261)
-- MODULE 5: BOOKING, COMBO & PAYMENT (THÀNH VIÊN 5)
-- FILE: 02_booking_module_sample_data.sql
-- YÊU CẦU: Mục 1.2 - Tạo dữ liệu mẫu có ý nghĩa (>= 5 dòng/bảng cho cả 6 bảng)
-- Các bảng: combo (5), promotion (5), booking (6), booking_detail (10), booking_combo (5), payment (5)
-- Tham chiếu các UUID thực tế từ cgv-hcmut-plain.sql:
--   Users:
--     bb656c14-68e8-4803-a80e-b2ac4e8804a9 (Nguyễn Văn A)
--     93852855-f0a3-4a81-a1b1-d3af94e8e74f (Trần Thị B)
--     6d6512bc-4edf-4e58-84de-1875da7e66fa (Lê Hoàng C)
--   Showtimes:
--     40dce532-a6b9-455f-83d3-987cefe55d9a (Suất 14:00 - Phim Mai)
--     dfc5161c-d539-418d-a4e6-0229adce3c2d (Suất 15:00 - Phim Mai)
--     dbc92dbe-d49f-4d04-8e2e-41810f620082 (Suất 17:00 - Phim Đào Phở Piano)
--     03a83c91-fc4e-4211-b989-4f363ebc884a (Suất 18:00 - Phim Đào Phở Piano)
--     90359f2d-ff72-4a20-9118-c2601fa82aad (Suất 20:00 - Phim Dune 2)
--   Seats:
--     A01: ef1a3285-bf57-406a-a188-4d86e81afe5a | A02: 9e5a1fa8-265b-4c06-99a8-cc6dbd221059
--     A03: e1e87254-2550-416a-a797-924a6e0d8b80 | A04: 646a64ca-1eec-4fe3-971b-f2e742fba3fb
--     A05: d9111a3c-8b5b-466c-a63c-2c317cdd09cd | A06: f9b993eb-7b07-43a4-bf3f-f8c4358db93f
--     A07: 76ecaf52-181a-43a9-a124-83ef1a2d4f14 | A08: ee168309-bca8-4525-b731-a7044e856bda
--     B01: b3879450-b3fa-490a-9e5b-2efdd45ef1ad | B02: (sử dụng A01 cho đơn cancelled)
-- =============================================================================

SET client_encoding = 'UTF8';

-- Dọn dữ liệu mẫu phân hệ booking theo thứ tự toàn vẹn khóa ngoại (chỉ xóa các ID mẫu)
DELETE FROM public.payment WHERE id IN (
    '0a29e492-2b63-4a0d-a149-13aa79b64454',
    '80b0db4e-139c-487c-bf75-77eaf5e1191c',
    'c9dceffc-2e02-4b1d-b9c8-7168c91fb707',
    'e1111111-1111-4111-a111-111111111111',
    'e2222222-2222-4222-a222-222222222222'
);

DELETE FROM public.booking_combo WHERE id IN (
    'b493511c-bbf5-4939-8f25-9f578c23fd3f',
    '22cebe31-6cca-4c42-a830-72ce120eab78',
    '89d719a3-f802-4089-a49c-15b6758da930',
    'c1111111-1111-4111-a111-111111111111',
    'c2222222-2222-4222-a222-222222222222'
);

DELETE FROM public.booking_detail WHERE id IN (
    'c2fba7e5-d996-4b97-ac74-bba36ea54647',
    '3719de09-5c19-4717-b476-12cf6e81fbc7',
    '7ecdccf1-dacd-464d-83fa-cd0af1db932a',
    'c3c5983d-a496-49c9-9aeb-98fb20e908c6',
    '618d4693-a8cb-486a-991c-8fac3612d00e',
    '4c646a8d-d908-437f-a210-9d6fd66d653d',
    'd1111111-1111-4111-a111-111111111111',
    'd2222222-2222-4222-a222-222222222222',
    'd3333333-3333-4333-a333-333333333333',
    'd4444444-4444-4444-a444-444444444444'
);

DELETE FROM public.booking WHERE id IN (
    '8993f8f5-9255-471f-b9c5-d0daaf04fdf5',
    'ecf3ddb2-70d3-4405-b138-e902f9a3353c',
    '485403d8-6b5f-4719-9455-5fb87cb92f5c',
    'b1111111-1111-4111-a111-111111111111',
    'b2222222-2222-4222-a222-222222222222',
    'b3333333-3333-4333-a333-333333333333'
);

-- =============================================================================
-- 1. NẠP DỮ LIỆU BẢNG COMBO (5 DÒNG >= 5 DÒNG)
-- =============================================================================
INSERT INTO public.combo (
    id, created_at, updated_at, name, description, category, size,
    price, image_url, is_available, is_e_combo, display_order
) VALUES
(
    'cb4fb778-334e-4afe-bdf5-981b8a7f69da',
    '2026-10-01 08:00:00+07', '2026-10-01 08:00:00+07',
    'Combo Solo', '1 Bắp Ngọt Lớn + 1 Nước Ngọt 32oz', 'combo', 'M',
    89000.00, 'https://example.com/combo-solo.jpg', true, false, 1
),
(
    'cc5ef555-dd69-4657-977f-db9b1c244a47',
    '2026-10-01 08:00:00+07', '2026-10-01 08:00:00+07',
    'Combo Couple', '1 Bắp Ngọt Lớn + 2 Nước Ngọt 32oz', 'combo', 'L',
    109000.00, 'https://example.com/combo-couple.jpg', true, false, 2
),
(
    '56698f25-90b9-43b2-b50b-c4fb132db349',
    '2026-10-01 08:00:00+07', '2026-10-01 08:00:00+07',
    'Combo Family', '2 Bắp Ngọt Lớn + 4 Nước Ngọt 32oz', 'combo', 'XL',
    199000.00, 'https://example.com/combo-family.jpg', true, false, 3
),
(
    '012943a4-7c3f-456f-b0f5-446ec2dc71b3',
    '2026-10-01 08:00:00+07', '2026-10-01 08:00:00+07',
    'CGV Deluxe Combo', '1 Bắp Mix + 2 Nước 32oz + 1 Snack', 'combo', 'L',
    159000.00, 'https://example.com/combo-deluxe.jpg', true, true, 4
),
(
    'cb555555-5555-4555-a555-555555555555',
    '2026-10-01 08:00:00+07', '2026-10-01 08:00:00+07',
    'Bắp Caramel Lớn', '1 Bắp vị Caramel size L', 'popcorn', 'L',
    65000.00, 'https://example.com/popcorn-caramel.jpg', true, true, 5
)
ON CONFLICT (id) DO NOTHING;


-- =============================================================================
-- 2. NẠP DỮ LIỆU BẢNG PROMOTION (5 DÒNG >= 5 DÒNG)
-- =============================================================================
INSERT INTO public.promotion (
    id, created_at, updated_at, name, description, code, type, scope,
    discount_value, max_discount_amount, min_order_amount,
    start_date, end_date, usage_limit, used_count, per_user_limit, is_active
) VALUES
(
    'a3d45699-819d-43ce-945f-3b5c9a06d076',
    '2026-06-01 00:00:00+07', '2026-06-01 00:00:00+07',
    'Khuyến mãi Hè & Thu 2026', 'Giảm 20% cho đơn đặt vé và combo từ 100.000đ', 'SUMMER2024',
    'percentage', 'all', 20.00, 100000.00, 100000.00,
    '2024-06-01 00:00:00+07', '2027-12-31 23:59:59+07', 1000, 151, 5, true
),
(
    'b5e7c943-91b6-4f4a-9846-a92fef15a242',
    '2026-01-01 00:00:00+07', '2026-01-01 00:00:00+07',
    'Ưu đãi thành viên mới 50K', 'Giảm trực tiếp 50.000đ cho đơn từ 150.000đ', 'NEWUSER50K',
    'fixed_amount', 'all', 50000.00, NULL, 150000.00,
    '2026-01-01 00:00:00+07', '2027-12-31 23:59:59+07', 500, 12, 2, true
),
(
    'a1111111-1111-4111-a111-111111111111',
    '2026-10-01 00:00:00+07', '2026-10-01 00:00:00+07',
    'Ưu đãi Cuối Tuần 15%', 'Giảm 15% tối đa 60.000đ khi đặt vé cuối tuần', 'WEEKEND15',
    'percentage', 'ticket_only', 15.00, 60000.00, 120000.00,
    '2026-10-01 00:00:00+07', '2027-06-30 23:59:59+07', 2000, 45, 3, true
),
(
    'a2222222-2222-4222-a222-222222222222',
    '2026-10-15 00:00:00+07', '2026-10-15 00:00:00+07',
    'Giảm 30K Combo Bắp Nước', 'Giảm 30.000đ cho đơn có combo từ 180.000đ', 'COMBO30K',
    'fixed_amount', 'combo_only', 30000.00, NULL, 180000.00,
    '2026-10-15 00:00:00+07', '2027-12-31 23:59:59+07', 300, 8, 2, true
),
(
    'a3333333-3333-4333-a333-333333333333',
    '2025-01-01 00:00:00+07', '2025-01-01 00:00:00+07',
    'Khuyến mãi Tết 2025 (Đã hết hạn)', 'Mã dùng để kiểm thử trường hợp hết hạn', 'TET2025EXP',
    'fixed_amount', 'all', 40000.00, NULL, 100000.00,
    '2025-01-01 00:00:00+07', '2025-02-15 23:59:59+07', 100, 100, 1, false
)
ON CONFLICT (id) DO UPDATE SET
    description = EXCLUDED.description,
    max_discount_amount = EXCLUDED.max_discount_amount,
    min_order_amount = EXCLUDED.min_order_amount,
    start_date = EXCLUDED.start_date,
    end_date = EXCLUDED.end_date,
    per_user_limit = EXCLUDED.per_user_limit,
    is_active = EXCLUDED.is_active;


-- =============================================================================
-- 3. NẠP DỮ LIỆU BẢNG BOOKING (6 ĐƠN ĐẶT VÉ >= 5 DÒNG)
-- Ghi chú tính toán nhất quán với Trigger 2.2.2:
--   final_amount  = GREATEST(0, ticket_total + combo_total - discount_amount - points_used * 1000)
--   points_earned = FLOOR(final_amount * 0.05 / 1000)
-- =============================================================================
INSERT INTO public.booking (
    id, created_at, updated_at, booking_code, user_id, showtime_id,
    ticket_total, combo_total, discount_amount, final_amount,
    promotion_id, status, expired_at, confirmed_at, points_earned, points_used
) VALUES
-- Đơn 1: 2 vé thường (180k) + 1 Combo Solo (89k) = 269k, giảm 20% SUMMER2024 (53.8k) -> 215.2k
(
    '8993f8f5-9255-471f-b9c5-d0daaf04fdf5',
    '2026-11-02 17:02:53.984+07', '2026-11-02 17:02:53.984+07',
    'CGV2026000001',
    'bb656c14-68e8-4803-a80e-b2ac4e8804a9', '40dce532-a6b9-455f-83d3-987cefe55d9a',
    180000.00, 89000.00, 53800.00, 215200.00,
    'a3d45699-819d-43ce-945f-3b5c9a06d076', 'confirmed',
    NULL, '2026-11-02 17:02:53.984+07', 10, 0
),
-- Đơn 2: 2 vé thường (180k) + 1 Combo Couple (109k) = 289k, không áp mã
(
    'ecf3ddb2-70d3-4405-b138-e902f9a3353c',
    '2026-11-02 17:02:53.984+07', '2026-11-02 17:02:53.984+07',
    'CGV2026000002',
    '93852855-f0a3-4a81-a1b1-d3af94e8e74f', 'dfc5161c-d539-418d-a4e6-0229adce3c2d',
    180000.00, 109000.00, 0.00, 289000.00,
    NULL, 'confirmed',
    NULL, '2026-11-02 17:02:53.984+07', 14, 0
),
-- Đơn 3: 2 vé thường (180k) + 1 Combo Family (199k) = 379k, không áp mã
(
    '485403d8-6b5f-4719-9455-5fb87cb92f5c',
    '2026-11-02 17:02:53.984+07', '2026-11-02 17:02:53.984+07',
    'CGV2026000003',
    '6d6512bc-4edf-4e58-84de-1875da7e66fa', 'dbc92dbe-d49f-4d04-8e2e-41810f620082',
    180000.00, 199000.00, 0.00, 379000.00,
    NULL, 'confirmed',
    NULL, '2026-11-02 17:02:53.984+07', 18, 0
),
-- Đơn 4: 2 vé VIP (200k) + 1 Deluxe Combo (159k) = 359k, áp mã NEWUSER50K giảm 50k -> 309k
(
    'b1111111-1111-4111-a111-111111111111',
    '2026-11-05 10:30:00+07', '2026-11-05 10:35:00+07',
    'CGV2026000004',
    'bb656c14-68e8-4803-a80e-b2ac4e8804a9', '03a83c91-fc4e-4211-b989-4f363ebc884a',
    200000.00, 159000.00, 50000.00, 309000.00,
    'b5e7c943-91b6-4f4a-9846-a92fef15a242', 'confirmed',
    NULL, '2026-11-05 10:35:00+07', 15, 0
),
-- Đơn 5: 1 vé VIP B01 (100k) + 1 Bắp Caramel Lớn (65k) = 165k, đang giữ chỗ (pending)
(
    'b2222222-2222-4222-a222-222222222222',
    now(), now(),
    'CGV2026000005',
    '93852855-f0a3-4a81-a1b1-d3af94e8e74f', '90359f2d-ff72-4a20-9118-c2601fa82aad',
    100000.00, 65000.00, 0.00, 165000.00,
    NULL, 'pending',
    now() + INTERVAL '15 minutes', NULL, 8, 0
),
-- Đơn 6: Đơn vé đã bị hủy (cancelled), vé con đã bị hủy (ticket_total = 0)
(
    'b3333333-3333-4333-a333-333333333333',
    '2026-11-01 08:00:00+07', '2026-11-01 08:20:00+07',
    'CGV2026000006',
    '6d6512bc-4edf-4e58-84de-1875da7e66fa', '40dce532-a6b9-455f-83d3-987cefe55d9a',
    0.00, 0.00, 0.00, 0.00,
    NULL, 'cancelled',
    '2026-11-01 08:15:00+07', NULL, 0, 0
);


-- =============================================================================
-- 4. NẠP DỮ LIỆU BẢNG BOOKING_DETAIL (10 VÉ CHI TIẾT >= 5 DÒNG)
-- =============================================================================
INSERT INTO public.booking_detail (
    id, created_at, updated_at, booking_id, seat_id,
    seat_label, seat_type, price, status, qr_code
) VALUES
-- 2 vé của Đơn 1 (A01, A02)
(
    'c2fba7e5-d996-4b97-ac74-bba36ea54647',
    '2026-11-02 17:02:53.984+07', '2026-11-02 17:02:53.984+07',
    '8993f8f5-9255-471f-b9c5-d0daaf04fdf5',
    'ef1a3285-bf57-406a-a188-4d86e81afe5a', 'A01', 'Ghế thường', 90000.00, 'active', 'QR-CGV2026000001-A01'
),
(
    '3719de09-5c19-4717-b476-12cf6e81fbc7',
    '2026-11-02 17:02:53.984+07', '2026-11-02 17:02:53.984+07',
    '8993f8f5-9255-471f-b9c5-d0daaf04fdf5',
    '9e5a1fa8-265b-4c06-99a8-cc6dbd221059', 'A02', 'Ghế thường', 90000.00, 'active', 'QR-CGV2026000001-A02'
),
-- 2 vé của Đơn 2 (A03, A04)
(
    '7ecdccf1-dacd-464d-83fa-cd0af1db932a',
    '2026-11-02 17:02:53.984+07', '2026-11-02 17:02:53.984+07',
    'ecf3ddb2-70d3-4405-b138-e902f9a3353c',
    'e1e87254-2550-416a-a797-924a6e0d8b80', 'A03', 'Ghế thường', 90000.00, 'active', 'QR-CGV2026000002-A03'
),
(
    'c3c5983d-a496-49c9-9aeb-98fb20e908c6',
    '2026-11-02 17:02:53.984+07', '2026-11-02 17:02:53.984+07',
    'ecf3ddb2-70d3-4405-b138-e902f9a3353c',
    '646a64ca-1eec-4fe3-971b-f2e742fba3fb', 'A04', 'Ghế thường', 90000.00, 'active', 'QR-CGV2026000002-A04'
),
-- 2 vé của Đơn 3 (A05, A06)
(
    '618d4693-a8cb-486a-991c-8fac3612d00e',
    '2026-11-02 17:02:53.984+07', '2026-11-02 17:02:53.984+07',
    '485403d8-6b5f-4719-9455-5fb87cb92f5c',
    'd9111a3c-8b5b-466c-a63c-2c317cdd09cd', 'A05', 'Ghế thường', 90000.00, 'active', 'QR-CGV2026000003-A05'
),
(
    '4c646a8d-d908-437f-a210-9d6fd66d653d',
    '2026-11-02 17:02:53.984+07', '2026-11-02 17:02:53.984+07',
    '485403d8-6b5f-4719-9455-5fb87cb92f5c',
    'f9b993eb-7b07-43a4-bf3f-f8c4358db93f', 'A06', 'Ghế thường', 90000.00, 'active', 'QR-CGV2026000003-A06'
),
-- 2 vé của Đơn 4 (A07, A08 - Ghế VIP)
(
    'd1111111-1111-4111-a111-111111111111',
    '2026-11-05 10:30:00+07', '2026-11-05 10:30:00+07',
    'b1111111-1111-4111-a111-111111111111',
    '76ecaf52-181a-43a9-a124-83ef1a2d4f14', 'A07', 'Ghế VIP', 100000.00, 'active', 'QR-CGV2026000004-A07'
),
(
    'd2222222-2222-4222-a222-222222222222',
    '2026-11-05 10:30:00+07', '2026-11-05 10:30:00+07',
    'b1111111-1111-4111-a111-111111111111',
    'ee168309-bca8-4525-b731-a7044e856bda', 'A08', 'Ghế VIP', 100000.00, 'active', 'QR-CGV2026000004-A08'
),
-- 1 vé của Đơn 5 (B01 - đang giữ chỗ pending)
(
    'd3333333-3333-4333-a333-333333333333',
    now(), now(),
    'b2222222-2222-4222-a222-222222222222',
    'b3879450-b3fa-490a-9e5b-2efdd45ef1ad', 'B01', 'Ghế VIP', 100000.00, 'active', 'QR-CGV2026000005-B01'
),
-- 1 vé đã hủy của Đơn 6 (cancelled)
(
    'd4444444-4444-4444-a444-444444444444',
    '2026-11-01 08:00:00+07', '2026-11-01 08:20:00+07',
    'b3333333-3333-4333-a333-333333333333',
    'ef1a3285-bf57-406a-a188-4d86e81afe5a', 'A01', 'Ghế thường', 90000.00, 'cancelled', 'QR-CGV2026000006-A01'
);


-- =============================================================================
-- 5. NẠP DỮ LIỆU BẢNG BOOKING_COMBO (5 DÒNG >= 5 DÒNG)
-- =============================================================================
INSERT INTO public.booking_combo (
    id, created_at, updated_at, booking_id, combo_id,
    quantity, unit_price, subtotal
) VALUES
-- Đơn 1: 1 Combo Solo (89,000đ)
(
    'b493511c-bbf5-4939-8f25-9f578c23fd3f',
    '2026-11-02 17:02:53.984+07', '2026-11-02 17:02:53.984+07',
    '8993f8f5-9255-471f-b9c5-d0daaf04fdf5',
    'cb4fb778-334e-4afe-bdf5-981b8a7f69da', 1, 89000.00, 89000.00
),
-- Đơn 2: 1 Combo Couple (109,000đ)
(
    '22cebe31-6cca-4c42-a830-72ce120eab78',
    '2026-11-02 17:02:53.984+07', '2026-11-02 17:02:53.984+07',
    'ecf3ddb2-70d3-4405-b138-e902f9a3353c',
    'cc5ef555-dd69-4657-977f-db9b1c244a47', 1, 109000.00, 109000.00
),
-- Đơn 3: 1 Combo Family (199,000đ)
(
    '89d719a3-f802-4089-a49c-15b6758da930',
    '2026-11-02 17:02:53.984+07', '2026-11-02 17:02:53.984+07',
    '485403d8-6b5f-4719-9455-5fb87cb92f5c',
    '56698f25-90b9-43b2-b50b-c4fb132db349', 1, 199000.00, 199000.00
),
-- Đơn 4: 1 Deluxe Combo (159,000đ)
(
    'c1111111-1111-4111-a111-111111111111',
    '2026-11-05 10:30:00+07', '2026-11-05 10:30:00+07',
    'b1111111-1111-4111-a111-111111111111',
    '012943a4-7c3f-456f-b0f5-446ec2dc71b3', 1, 159000.00, 159000.00
),
-- Đơn 5: 1 Bắp Caramel Lớn (65,000đ)
(
    'c2222222-2222-4222-a222-222222222222',
    now(), now(),
    'b2222222-2222-4222-a222-222222222222',
    'cb555555-5555-4555-a555-555555555555', 1, 65000.00, 65000.00
);


-- =============================================================================
-- 6. NẠP DỮ LIỆU BẢNG PAYMENT (5 DÒNG GIAO DỊCH >= 5 DÒNG)
-- =============================================================================
INSERT INTO public.payment (
    id, created_at, updated_at, booking_id, method,
    amount, status, transaction_id, gateway_response, paid_at
) VALUES
-- Giao dịch 1: Đơn 1 thanh toán qua MoMo thành công (215,200đ)
(
    '0a29e492-2b63-4a0d-a149-13aa79b64454',
    '2026-11-02 17:02:53.984+07', '2026-11-02 17:02:53.984+07',
    '8993f8f5-9255-471f-b9c5-d0daaf04fdf5',
    'momo', 215200.00, 'success',
    'MOMO_TXN_1793613773984', '{"partnerCode":"MOMO","resultCode":0,"message":"Successful"}', '2026-11-02 17:02:53.984+07'
),
-- Giao dịch 2: Đơn 2 thanh toán qua MoMo thành công (289,000đ)
(
    '80b0db4e-139c-487c-bf75-77eaf5e1191c',
    '2026-11-02 17:02:53.984+07', '2026-11-02 17:02:53.984+07',
    'ecf3ddb2-70d3-4405-b138-e902f9a3353c',
    'momo', 289000.00, 'success',
    'MOMO_TXN_1793613773985', '{"partnerCode":"MOMO","resultCode":0,"message":"Successful"}', '2026-11-02 17:02:53.984+07'
),
-- Giao dịch 3: Đơn 3 thanh toán qua ZaloPay thành công (379,000đ)
(
    'c9dceffc-2e02-4b1d-b9c8-7168c91fb707',
    '2026-11-02 17:02:53.984+07', '2026-11-02 17:02:53.984+07',
    '485403d8-6b5f-4719-9455-5fb87cb92f5c',
    'zalopay', 379000.00, 'success',
    'ZP_TXN_1793613773986', '{"returncode":1,"returnmessage":"Giao dich thanh cong"}', '2026-11-02 17:02:53.984+07'
),
-- Giao dịch 4: Đơn 4 thanh toán qua Thẻ tín dụng/Ghi nợ thành công (309,000đ)
(
    'e1111111-1111-4111-a111-111111111111',
    '2026-11-05 10:35:00+07', '2026-11-05 10:35:00+07',
    'b1111111-1111-4111-a111-111111111111',
    'credit_card', 309000.00, 'success',
    'VISA_4111222233334444', '{"vnp_ResponseCode":"00","vnp_Message":"Confirm Success"}', '2026-11-05 10:35:00+07'
),
-- Giao dịch 5: Đơn 5 giao dịch Banking đang chờ xử lý (165,000đ)
(
    'e2222222-2222-4222-a222-222222222222',
    now(), now(),
    'b2222222-2222-4222-a222-222222222222',
    'banking', 165000.00, 'pending',
    'VNPAY_PENDING_001', '{"status":"Awaiting_Customer_OTP"}', NULL
);
