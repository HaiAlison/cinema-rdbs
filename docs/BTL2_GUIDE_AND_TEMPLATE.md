# TÀI LIỆU HƯỚNG DẪN BTL2 HỆ CƠ SỞ DỮ LIỆU & MODULE MẪU (USERS)

> **Căn cứ yêu cầu**: File [`doc-2.md`](../doc-2.md)  
> **Hệ quản trị CSDL sử dụng trong repo**: PostgreSQL (`PL/pgSQL`)  
> **Khung ứng dụng Backend**: NestJS + TypeORM

---

## PHẦN 1: QUY CHUẨN PHÂN CHIA VÀ NHIỆM VỤ CỦA 5 THÀNH VIÊN

Theo quy định của BTL2, **mỗi sinh viên trong nhóm BẮT BUỘC phải viết ít nhất 1 câu lệnh ở Phần 2** (Trigger, Function hoặc Stored Procedure). Không đóng góp sẽ nhận 0 điểm BTL2.

Dưới đây là sơ đồ phân chia gợi ý 5 module tương ứng 5 người trong đồ án đặt vé rạp chiếu phim CGV:

| Thành viên | Tên Module | Các bảng chính phụ trách | Trọng tâm nghiệp vụ |
| :--- | :--- | :--- | :--- |
| **Thành viên 1** (Mẫu) | **User & Membership** | `users`, `membership`, `point_transaction` | Quản lý người dùng, thẻ hội viên, tích/đổi điểm thưởng, phân hạng (VIP/VVIP). |
| **Thành viên 2** | **Movie & Format** | `movie`, `format`, `movie_format` | Quản lý phim, định dạng chiếu (2D/3D/IMAX), độ tuổi quy định, phân loại phim. |
| **Thành viên 3** | **Cinema, Room & Seat** | `cinema`, `room`, `seat`, `seat_type` | Cụm rạp, phòng chiếu, ma trận ghế ngồi (VIP/Standard/Sweetbox), phụ thu loại ghế. |
| **Thành viên 4** | **Showtime & Scheduling** | `showtime`, `room`, `movie` | Lịch chiếu phim, tránh xung đột khung giờ trong cùng phòng, trạng thái suất chiếu. |
| **Thành viên 5** | **Booking, Combo & Payment** | `booking`, `booking_detail`, `combo`, `payment`, `promotion` | Đặt vé, chọn ghế, mua bắp nước, áp mã giảm giá, thanh toán đơn hàng. |

---

## PHẦN 2: CHECKLIST BẮT BUỘC MỖI MODULE PHẢI HOÀN THÀNH

Mỗi thành viên khi làm module của mình cần nộp đủ các file SQL trong thư mục `sql/` theo mẫu:

```text
sql/
├── 01_<module_name>_schema.sql       # Mục 1.1: CHECK constraint, semantic constraints
├── 02_<module_name>_sample_data.sql  # Mục 1.2: Ít nhất 5 records mẫu/bảng có ý nghĩa
├── 03_<module_name>_procedures.sql   # Mục 2.1 & 2.3: Stored Procedures
├── 04_<module_name>_triggers.sql     # Mục 2.2: Triggers (Ràng buộc + Thuộc tính dẫn xuất)
├── 05_<module_name>_functions.sql    # Mục 2.4: Functions (IF/LOOP, Cursor, tham số)
└── 06_<module_name>_demo_tests.sql   # Script câu lệnh CALL/SELECT chuẩn bị sẵn để demo
```

### Chi tiết các yêu cầu theo thang điểm:

1. **Mục 1.1 & 1.2 (3 điểm) - Bảng, Ràng buộc & Dữ liệu mẫu**:
   - Khóa chính, khóa ngoại, unique.
   - Thêm các ràng buộc `CHECK` ngữ nghĩa (ví dụ: tuổi >= 13, điểm >= 0, giờ kết thúc > giờ bắt đầu, giá vé > 0...).
   - **Tối thiểu 5 dòng dữ liệu mẫu** cho mỗi bảng thuộc module, dữ liệu thực tế và có liên kết logic.

2. **Mục 2.1 (1 điểm) - Stored Procedures CRUD cho 1 bảng**:
   - Viết 3 procedures: **INSERT**, **UPDATE**, **DELETE** cho bảng chính của module.
   - **Bắt buộc validate dữ liệu**: Phải `RAISE EXCEPTION` với **thông báo lỗi chi tiết, rõ ràng** (ví dụ: *"Email đã tồn tại"*, *"Chưa đủ 18 tuổi"*, thay vì báo lỗi chung chung *"Lỗi nhập liệu"*).
   - **Với DELETE procedure**: Phải nêu rõ trong báo cáo và code: **Khi nào cho xóa, khi nào KHÔNG cho xóa và vì sao** (ví dụ: không cho xóa rạp nếu đang có suất chiếu tương lai; không cho xóa user nếu còn điểm thưởng hoặc đơn đặt vé chưa hoàn tất).

3. **Mục 2.2 (1 điểm) - TRIGGERS**:
   - **Mục 2.2.1 (Trigger ràng buộc nghiệp vụ)**: Xác định 1 ràng buộc liên bảng hoặc trạng thái động mà `CHECK` thông thường không kiểm tra được. Xác định các DML tác động (INSERT, UPDATE, DELETE). Viết trigger bắt lỗi.
   - **Mục 2.2.2 (Trigger tính thuộc tính dẫn xuất)**: Chọn 1 thuộc tính dẫn xuất (ví dụ: `total_points_earned`, `final_amount`, `tier`, `total_seats`). Tính các thuộc tính cơ sở trước, sau đó tính thuộc tính dẫn xuất.

4. **Mục 2.3 (1 điểm) - Stored Procedures truy vấn dữ liệu**:
   - **SP 1**: Query join từ 2 bảng trở lên, có tham số lọc `WHERE` và sắp xếp `ORDER BY`.
   - **SP 2**: Query có hàm tổng hợp (`COUNT`, `SUM`, `AVG`), `GROUP BY`, `HAVING` (lấy tham số truyền vào), `WHERE`, `ORDER BY`, join từ 2 bảng trở lên.

5. **Mục 2.4 (1 điểm) - Functions**:
   - Viết 2 functions thỏa mãn: Có cấu trúc `IF`/`LOOP`, sử dụng **CURSOR**, có query lấy dữ liệu để tính toán, validate tham số đầu vào.

6. **Mục 3 (3 điểm) - Tích hợp Ứng dụng (NestJS Backend + API)**:
   - Các API thêm/sửa/xóa và xem danh sách phải **thực sự gọi Stored Procedure / Function** trong database (không dùng ORM query thông thường).

---

## PHẦN 3: GIẢI THÍCH CHI TIẾT MODULE MẪU (USERS & MEMBERSHIP)

Các file SQL mẫu hoàn chỉnh đã được đặt sẵn trong thư mục [`sql/`](../sql/):

### 1. File `01_user_module_schema.sql` (Mục 1.1)
- `chk_users_email_format`: Ràng buộc Regex định dạng email.
- `chk_users_phone_format`: Ràng buộc số điện thoại 10-11 số.
- `chk_users_age_limit`: Ràng buộc khách hàng phải đủ từ 13 tuổi trở lên.
- `chk_membership_points_non_negative`: Điểm không được âm.

### 2. File `02_user_module_sample_data.sql` (Mục 1.2)
- Cung cấp sẵn 5 khách hàng và nhân viên kèm 5 thẻ hội viên tương ứng với các hạng `standard`, `vip`, `vvip`.

### 3. File `03_user_module_procedures.sql` (Mục 2.1 & 2.3)
- `sp_insert_user(...)`: Validate tên >= 2 ký tự, mã code duy nhất, email regex, sđt regex, ngày sinh tuổi >= 13, role hợp lệ. Tự động cấp thẻ hội viên ban đầu.
- `sp_update_user(...)`: Kiểm tra tồn tại, validate dữ liệu cập nhật.
- `sp_delete_user(...)`: **Quy tắc nghiệp vụ**: 
  - *Không cho xóa*: Nếu khách hàng còn đơn đặt vé `pending`/`confirmed` hoặc còn điểm `cgv_points > 0`.
  - *Cho xóa*: Khi không vướng giao dịch và điểm = 0. Thực hiện Soft Delete để bảo toàn quan hệ khóa ngoại.
- `sp_get_users_with_membership(...)`: (Mục 2.3 SP 1) Join `users` + `membership`, lọc theo `p_province`, `p_tier`, sắp xếp theo điểm số và ngày tạo.
- `sp_report_user_spending_by_tier(...)`: (Mục 2.3 SP 2) Join `users` + `membership` + `booking`, tính `COUNT(b.id)`, `SUM(b.final_amount)`, nhóm theo User & Tier, lọc điều kiện nhóm `HAVING SUM >= p_min_total_spent`, sắp xếp theo doanh thu giảm dần.

### 4. File `04_user_module_triggers.sql` (Mục 2.2)
- **Trigger ràng buộc (2.2.1)**: `trg_check_redeem_point_balance` trên bảng `point_transaction`. Khi hội viên đổi điểm (`type = 'redeem'`), nếu số điểm trừ lớn hơn số dư `cgv_points` hiện tại thì chặn lại và `RAISE EXCEPTION`.
- **Trigger dẫn xuất (2.2.2)**: `trg_update_membership_derived_attributes` trên bảng `point_transaction`. Tự động:
  1. Cập nhật số dư điểm `cgv_points`.
  2. Cộng dồn `total_points_earned` nếu là điểm tích lũy mới.
  3. Tự động xét thăng hạng `tier` (`>= 1000` điểm lên VIP, `>= 3000` điểm lên VVIP).
  4. Ghi nhận số dư sau giao dịch vào `balance_after`.

### 5. File `05_user_module_functions.sql` (Mục 2.4)
- `fn_calculate_user_loyalty_voucher(p_user_id)`: Dùng **CURSOR** duyệt 10 đơn vé gần nhất, **LOOP** tính tổng chi tiêu, **IF** đánh giá tặng voucher (5% đến 20%).
- `fn_audit_user_point_history(p_membership_id, p_target_year)`: Dùng **CURSOR** quét các giao dịch điểm trong năm, **LOOP** cộng/trừ số dư giả định và đối soát với `balance_after`, phát hiện sai lệch.

### 6. File `06_user_module_demo_tests.sql`
- Tổng hợp đầy đủ các câu lệnh test case hợp lệ và vi phạm lỗi để nhóm mở lên chạy demo trực tiếp trong buổi báo cáo.

---

## PHẦN 4: HƯỚNG DẪN CODE TRONG NESTJS (SERVICE & CONTROLLER)

Để đáp ứng Phần 3 của BTL2, trong Service của NestJS bạn dùng `Repository.query` hoặc `DataSource.query` để gọi Procedure/Function:

```typescript
// Gọi Stored Procedure INSERT
await this.userRepository.query(
  `CALL sp_insert_user($1, $2, $3, $4, $5, $6, $7, $8, NULL)`,
  [code, name, email, phone, dob, province, password, role]
);

// Gọi Stored Procedure DELETE
await this.userRepository.query(
  `CALL sp_delete_user($1)`,
  [userId]
);

// Gọi Function tính toán
const result = await this.userRepository.query(
  `SELECT fn_calculate_user_loyalty_voucher($1) AS voucher_percent`,
  [userId]
);
```

Xem triển khai trực tiếp trong [`src/users/users.service.ts`](../src/users/users.service.ts) và [`src/users/users.controller.ts`](../src/users/users.controller.ts).
