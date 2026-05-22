# Tài liệu API Billiard POS CRM (Hệ thống Quản lý Bida)

Tài liệu này cung cấp danh sách đầy đủ tất cả các endpoint trong module `api` của hệ thống CRM. Tài liệu này được thiết kế tối ưu cho cả lập trình viên và các mô hình AI đọc hiểu để dễ dàng tích hợp hoặc phát triển ứng dụng khách (như Flutter Desktop Client).

---

## 1. Hướng dẫn chung & Cấu hình hệ thống

### 1.1. Địa chỉ máy chủ (Base URL)
*   **Môi trường thử nghiệm:** `https://poscrm.dev.an-holdings.vn/api`
*   **Môi trường production:** `https://crm.an-holdings.vn/api`
*   **Biến Postman:** `{{baseUrl}}`

### 1.2. Hậu tố URL (URL Suffix)
Hệ thống sử dụng Yii 1 framework với cấu hình `'urlSuffix' => '.html'`. Do đó, **tất cả các endpoint thực tế khi gọi từ client bắt buộc phải thêm đuôi `.html`** vào sau tên hành động (action).
*   *Ví dụ đúng:* `{{baseUrl}}/user/login.html`
*   *Ví dụ sai:* `{{baseUrl}}/user/login`

### 1.3. Xác thực (Authentication)
*   Hệ thống xác thực bằng **JWT (JSON Web Token)**.
*   Khi đăng nhập thành công qua `/user/login.html`, máy chủ trả về `access_token` và `refresh_token`.
*   Các request tiếp theo (trừ Đăng nhập và Refresh Token) bắt buộc phải đính kèm Header sau:
    ```http
    Authorization: Bearer <access_token>
    Content-Type: application/json
    ```
*   `access_token` có hiệu lực trong **1 giờ**.
*   `refresh_token` có hiệu lực trong **30 ngày** dùng để cấp lại access token mới khi hết hạn qua `/user/refresh.html`.

### 1.4. Định dạng phản hồi mặc định (Response Format)
*   **Thành công (HTTP Status 200):**
    ```json
    {
      "status": 1,
      "message": "Thông báo thành công",
      "data": {} // hoặc [...]
    }
    ```
*   **Thành công nhưng logic thất bại (HTTP Status 200):**
    ```json
    {
      "status": 0,
      "message": "Thông báo lý do thất bại",
      "errors": {} // chi tiết lỗi kiểm chuẩn nếu có
    }
    ```
*   **Lỗi hệ thống hoặc xác thực:**
    *   `400 Bad Request`: Thiếu tham số bắt buộc.
    *   `401 Unauthorized`: Token không hợp lệ hoặc hết hạn.
    *   `403 Forbidden`: Tài khoản không đủ quyền (ví dụ: Nhân viên gọi API của Quản lý).
    *   `404 Not Found`: Bản ghi hoặc URL không tồn tại.
    *   `500 Internal Server Error`: Lỗi máy chủ xử lý database hoặc logic.
    Định dạng phản hồi lỗi:
    ```json
    {
      "status": <HTTP_STATUS_CODE>,
      "error": "Thông điệp lỗi chi tiết"
    }
    ```

---

## 2. Chi tiết các Endpoint theo Controller

### 2.1. Quản lý Tài khoản & Xác thực (`UserController`)

#### 2.1.1. Đăng nhập (`/user/login.html`)
*   **Method:** `POST`
*   **Xác thực:** Không (No Auth)
*   **Payload:**
    ```json
    {
      "username": "admin", // Bắt buộc
      "password": "password_here" // Bắt buộc
    }
    ```
*   **Phản hồi thành công:**
    ```json
    {
      "status": 1,
      "errors": [],
      "message": "Đăng nhập thành công",
      "data": {
        "id": "36653458-54f4-11f1-a64c-3b18c5949633",
        "username": "admin",
        "display_name": "System Admin",
        "role": "admin",
        "phone_number": "0900000000",
        "is_active": 1,
        "created_at": "2026-05-21 16:05:28",
        "updated_at": "2026-05-21 17:33:13",
        "access_token": "eyJ0eXAiOiJKV1...",
        "refresh_token": "eyJ0eXAiOiJKV1..."
      }
    }
    ```

#### 2.1.2. Làm mới Token (`/user/refresh.html`)
*   **Method:** `POST`
*   **Xác thực:** Không (No Auth)
*   **Payload:**
    ```json
    {
      "refresh_token": "eyJ0eXAiOiJK..." // Bắt buộc
    }
    ```
*   **Phản hồi thành công:**
    ```json
    {
      "status": 1,
      "message": "Lấy token mới thành công",
      "data": {
        "access_token": "eyJ0eXAiOiJK..."
      }
    }
    ```

#### 2.1.3. Lấy thông tin tài khoản hiện tại (`/user/info.html`)
*   **Method:** `GET`
*   **Xác thực:** Bắt buộc (Bearer Token)
*   **Phản hồi thành công:**
    ```json
    {
      "status": 1,
      "message": "Lấy thông tin thành công",
      "data": {
        "id": "36653458-54f4-11f1-a64c-3b18c5949633",
        "username": "admin",
        "display_name": "System Admin",
        "role": "admin",
        "phone_number": "0900000000",
        "is_active": 1,
        "created_at": "2026-05-21 16:05:28",
        "updated_at": "2026-05-21 17:33:13"
      }
    }
    ```

#### 2.1.4. Đổi mật khẩu (`/user/changepass.html`)
*   **Method:** `POST`
*   **Xác thực:** Bắt buộc (Bearer Token)
*   **Payload:**
    ```json
    {
      "old_pass": "old_password", // Bắt buộc
      "new_pass": "new_password_at_least_6_chars", // Bắt buộc
      "new_repass": "new_password_at_least_6_chars" // Bắt buộc (phải trùng với new_pass)
    }
    ```
*   **Phản hồi thành công:**
    ```json
    {
      "status": 1,
      "errors": [],
      "message": "Đổi mật khẩu thành công"
    }
    ```

#### 2.1.5. Danh sách nhân viên (`/user/list.html`)
*   **Method:** `POST` hoặc `GET`
*   **Xác thực:** Bắt buộc (Chỉ Admin hoặc Manager)
*   **Payload:**
    ```json
    {
      "page": 1, // Mặc định là 1
      "per_page": 20, // Mặc định là 20
      "keyword": "tuấn", // Tìm theo username, display_name hoặc phone_number
      "role": "cashier" // Lọc theo role: admin, manager, cashier, waiter (tùy chọn)
    }
    ```
*   **Phản hồi thành công:**
    ```json
    {
      "status": 1,
      "message": "Lấy danh sách nhân viên thành công",
      "data": {
        "items": [
          {
            "id": "8fcd98f2-9fe3-41b0-bad9-958ade61bbc7",
            "username": "manager",
            "display_name": "Quản lý",
            "role": "manager",
            "phone_number": "0904345514",
            "is_active": 1,
            "created_at": "2026-05-21 17:49:15",
            "updated_at": "2026-05-21 17:49:15"
          }
        ],
        "pagination": {
          "total": 1,
          "per_page": 20,
          "current_page": 1,
          "last_page": 1
        }
      }
    }
    ```

#### 2.1.6. Tạo nhân viên mới (`/user/create.html`)
*   **Method:** `POST`
*   **Xác thực:** Bắt buộc (Chỉ Admin hoặc Manager)
*   **Payload:**
    ```json
    {
      "username": "cashier1", // Bắt buộc, duy nhất
      "password": "password123", // Bắt buộc
      "display_name": "Nguyễn Thu Ngân 1", // Bắt buộc
      "role": "cashier", // Bắt buộc: admin, manager, cashier, waiter
      "phone_number": "0912345678", // Tùy chọn
      "is_active": 1 // Tùy chọn, mặc định là 1
    }
    ```
*   **Phản hồi thành công:** Trả về đối tượng nhân viên được tạo thành công (đã ẩn trường nhạy cảm).

#### 2.1.7. Cập nhật thông tin nhân viên (`/user/update.html`)
*   **Method:** `POST`
*   **Xác thực:** Bắt buộc (Chỉ Admin hoặc Manager)
*   **Payload:**
    ```json
    {
      "id": "user_uuid_here", // Bắt buộc
      "username": "cashier1_edit", 
      "password": "new_password_if_change", // Chỉ nhập khi muốn đổi mật khẩu nhân viên
      "display_name": "Nguyễn Thu Ngân 1 Sửa",
      "role": "cashier",
      "phone_number": "0912345679",
      "is_active": 1
    }
    ```
*   **Phản hồi thành công:** Trả về đối tượng nhân viên đã được cập nhật.

#### 2.1.8. Xóa nhân viên (`/user/delete.html`)
*   **Method:** `POST` hoặc `DELETE`
*   **Xác thực:** Bắt buộc (Chỉ Admin hoặc Manager, không được tự xóa tài khoản chính mình)
*   **Payload:**
    ```json
    {
      "id": "user_uuid_here" // Bắt buộc
    }
    ```
*   **Phản hồi thành công (Soft delete - đưa `is_active` về 0):**
    ```json
    {
      "status": 1,
      "message": "Xóa nhân viên (ngưng hoạt động) thành công"
    }
    ```

---

### 2.2. Quản lý Bàn chơi & Khu vực (`TableController`)

#### 2.2.1. Lấy sơ đồ khu vực & bàn chơi (`/table/areas.html`)
*   **Method:** `GET`
*   **Xác thực:** Bắt buộc (Bearer Token)
*   **Phản hồi thành công:**
    ```json
    {
      "status": 1,
      "message": "Lấy sơ đồ khu vực thành công",
      "data": [
        {
          "id": 1,
          "area_name": "Khu A",
          "description": "Khu vực bida lỗ máy lạnh",
          "created_at": "2026-05-21 16:20:21",
          "tables": [
            {
              "id": "t1111111-1111-4111-8111-111111111111",
              "table_name": "Bàn VIP 1",
              "table_type_id": 2,
              "status": "idle", // idle, active, booked, maintenance
              "current_order_id": null,
              "created_at": "2026-05-21 16:20:21",
              "updated_at": "2026-05-21 17:44:37"
            }
          ]
        }
      ]
    }
    ```

#### 2.2.2. Danh sách bàn chơi (`/table/list.html`)
*   **Method:** `POST` hoặc `GET`
*   **Xác thực:** Bắt buộc (Bearer Token)
*   **Payload:**
    ```json
    {
      "area_id": 1 // Tùy chọn, lọc theo khu vực
    }
    ```
*   **Phản hồi thành công:** Danh sách thô tất cả các thuộc tính của các bàn chơi.

#### 2.2.3. Tạo bàn chơi mới (`/table/create.html`)
*   **Method:** `POST`
*   **Xác thực:** Bắt buộc (Chỉ Admin hoặc Manager)
*   **Payload:**
    ```json
    {
      "table_name": "Bàn A6", // Bắt buộc
      "area_id": 1, // Bắt buộc
      "table_type_id": 2, // Bắt buộc (1: Bida phăng, 2: Bida lỗ)
      "hourly_rate": 80000.00, // Tùy chọn (Nếu thiết lập, sẽ lấy giá cứng này thay vì tính theo khung giờ)
      "status": "idle", // Tùy chọn: idle, active, booked, maintenance
      "sort_order": 6 // Tùy chọn, thứ tự sắp xếp hiển thị
    }
    ```
*   **Phản hồi thành công:** Trả về đối tượng bàn chơi vừa tạo.

#### 2.2.4. Cập nhật bàn chơi (`/table/update.html`)
*   **Method:** `POST`
*   **Xác thực:** Bắt buộc (Chỉ Admin hoặc Manager)
*   **Payload:** Gửi kèm thuộc tính `"id"` (UUID bàn chơi) cùng các thuộc tính cần cập nhật giống API tạo mới.

#### 2.2.5. Xóa bàn chơi (`/table/delete.html`)
*   **Method:** `POST` hoặc `DELETE`
*   **Xác thực:** Bắt buộc (Chỉ Admin hoặc Manager, chỉ xóa được khi bàn ở trạng thái rảnh - `idle`)
*   **Payload:**
    ```json
    {
      "id": "table_uuid_here" // Bắt buộc
    }
    ```

#### 2.2.6. Tạo khu vực mới (`/table/createArea.html`)
*   **Method:** `POST`
*   **Xác thực:** Bắt buộc (Chỉ Admin hoặc Manager)
*   **Payload:**
    ```json
    {
      "area_name": "Khu VIP 3", // Bắt buộc
      "description": "Phòng bida đặc biệt riêng tư" // Tùy chọn
    }
    ```

#### 2.2.7. Cập nhật khu vực (`/table/updateArea.html`)
*   **Method:** `POST`
*   **Payload:** Gửi kèm `"id"` (ID số nguyên của khu vực) và các thuộc tính cần cập nhật.

#### 2.2.8. Xóa khu vực (`/table/deleteArea.html`)
*   **Method:** `POST` hoặc `DELETE`
*   **Xác thực:** Bắt buộc (Chỉ Admin hoặc Manager, chỉ được xóa khi khu vực không chứa bàn nào)
*   **Payload:**
    ```json
    {
      "id": 3 // Bắt buộc (ID khu vực)
    }
    ```

#### 2.2.9. Lấy danh sách khung giá giờ (`/table/prices.html`)
*   **Method:** `GET`
*   **Xác thực:** Bắt buộc (Bearer Token)
*   **Phản hồi thành công:** Trả về danh sách cấu hình giá giờ của các loại bàn bao gồm các thông tin về loại bàn chơi, giá, khoảng giờ bắt đầu/kết thúc, thứ trong tuần (1: Thứ Hai -> 7: Chủ Nhật, lưu kiểu mảng JSON) và độ ưu tiên tính toán.

#### 2.2.10. Lưu cấu hình khung giá giờ (`/table/savePrice.html`)
*   **Method:** `POST`
*   **Xác thực:** Bắt buộc (Chỉ Admin hoặc Manager)
*   **Payload:**
    ```json
    {
      "id": 0, // Nhập 0 nếu thêm mới, nhập ID cụ thể (>0) nếu cập nhật
      "table_type_id": 1, // Bắt buộc
      "price_per_hour": 75000.00, // Bắt buộc (Giá trị số tiền/giờ)
      "start_hour": "08:00:00", // Bắt buộc (Giờ bắt đầu)
      "end_hour": "17:00:00", // Bắt buộc (Giờ kết thúc, phải lớn hơn start_hour)
      "days_of_week": [1, 2, 3, 4, 5], // Bắt buộc (Mảng số nguyên từ 1-7 chỉ định các ngày áp dụng trong tuần)
      "is_active": 1, // Tùy chọn (1: Kích hoạt, 0: Khóa)
      "priority": 5 // Tùy chọn (Độ ưu tiên tính tiền khi các khung giờ chồng lấn nhau, ưu tiên lớn hơn sẽ được tính trước)
    }
    ```

#### 2.2.11. Xóa khung giá giờ (`/table/deletePrice.html`)
*   **Method:** `POST` hoặc `DELETE`
*   **Payload:** `{"id": 6}`

---

### 2.3. Quản lý Sản phẩm & Danh mục (`ProductController`)

#### 2.3.1. Danh sách danh mục sản phẩm (`/product/categories.html`)
*   **Method:** `GET`
*   **Xác thực:** Bắt buộc (Bearer Token)

#### 2.3.2. Tạo danh mục sản phẩm mới (`/product/createCategory.html`)
*   **Method:** `POST`
*   **Xác thực:** Bắt buộc (Chỉ Admin hoặc Manager)
*   **Payload:** `{"category_name": "Đồ uống có cồn"}`

#### 2.3.3. Cập nhật danh mục sản phẩm (`/product/updateCategory.html`)
*   **Method:** `POST`
*   **Payload:** `{"id": 1, "category_name": "Đồ uống nhẹ"}`

#### 2.3.4. Xóa danh mục sản phẩm (`/product/deleteCategory.html`)
*   **Method:** `POST` hoặc `DELETE`
*   **Xác thực:** Bắt buộc (Chỉ Admin hoặc Manager, chỉ xóa được khi không có sản phẩm nào thuộc danh mục)
*   **Payload:** `{"id": 1}`

#### 2.3.5. Danh sách sản phẩm (`/product/list.html`)
*   **Method:** `POST` hoặc `GET`
*   **Xác thực:** Bắt buộc (Bearer Token)
*   **Payload:**
    ```json
    {
      "category_id": 1, // Tùy chọn, lọc theo danh mục
      "keyword": "sting", // Tùy chọn, tìm kiếm theo tên sản phẩm hoặc barcode
      "is_active": 1 // Tùy chọn, lọc sản phẩm đang bán (1) hoặc ngưng bán (0)
    }
    ```

#### 2.3.6. Tạo sản phẩm mới (`/product/create.html`)
*   **Method:** `POST`
*   **Xác thực:** Bắt buộc (Chỉ Admin hoặc Manager)
*   **Payload:**
    ```json
    {
      "product_name": "Trà xanh C2", // Bắt buộc
      "category_id": 1, // Bắt buộc
      "unit": "Chai", // Bắt buộc (Đơn vị tính: Chai, Lon, Dĩa, Gói...)
      "selling_price": 12000.00, // Bắt buộc (Giá bán cho khách)
      "cost_price": 7000.00, // Tùy chọn (Giá vốn nhập kho)
      "stock_quantity": 50, // Tùy chọn, mặc định 0
      "barcode": "C2TEA12", // Tùy chọn, mã vạch (duy nhất nếu nhập)
      "is_active": 1 // Tùy chọn, mặc định 1
    }
    ```

#### 2.3.7. Cập nhật sản phẩm (`/product/update.html`)
*   **Method:** `POST`
*   **Payload:** Gửi kèm `"id"` (UUID của sản phẩm) và các trường cần chỉnh sửa.

#### 2.3.8. Xóa sản phẩm (Ngưng bán) (`/product/delete.html`)
*   **Method:** `POST` hoặc `DELETE`
*   **Xác thực:** Bắt buộc (Chỉ Admin hoặc Manager)
*   **Payload:** `{"id": "product_uuid"}`
*   **Logic xử lý:** Hệ thống thực hiện **Soft Delete** (cập nhật `is_active` = 0) để bảo toàn dữ liệu doanh thu của các hóa đơn cũ liên kết đến sản phẩm này.

---

### 2.4. Quản lý Thành viên (`MemberController`)

#### 2.4.1. Danh sách hạng thành viên (`/member/tiers.html`)
*   **Method:** `GET`
*   **Xác thực:** Bắt buộc (Bearer Token)
*   **Mô tả:** Trả về các hạng (VIP Đồng, VIP Bạc, VIP Vàng...) cùng điều kiện điểm tối thiểu (`min_points`) và phần trăm giảm giá (`discount_percentage`) tương ứng.

#### 2.4.2. Tìm thành viên theo SĐT (`/member/search.html`)
*   **Method:** `POST` hoặc `GET`
*   **Payload:**
    ```json
    {
      "phone_number": "0912345678" // Bắt buộc
    }
    ```
*   **Phản hồi thành công (Khi tìm thấy):**
    ```json
    {
      "status": 1,
      "message": "Tìm thấy thành viên",
      "data": {
        "id": "m1111111-1111-4111-8111-111111111111",
        "full_name": "Nguyen Van A",
        "phone_number": "0912345678",
        "email": "vana@gmail.com",
        "membership_tier_id": 1,
        "total_points": 128,
        "accumulated_spend": "1280750.00",
        "created_at": "2026-05-21 16:20:21",
        "updated_at": "2026-05-21 16:20:22",
        "tier_name": "VIP Đồng",
        "discount_percentage": 5
      }
    }
    ```

#### 2.4.3. Đăng ký thành viên mới (`/member/create.html`)
*   **Method:** `POST`
*   **Payload:**
    ```json
    {
      "full_name": "Nguyễn Văn C", // Bắt buộc
      "phone_number": "0909999999", // Bắt buộc, duy nhất
      "email": "vanc@gmail.com", // Tùy chọn
      "membership_tier_id": 1 // Tùy chọn (Nếu bỏ trống hệ thống tự động gán hạng thấp nhất)
    }
    ```

#### 2.4.4. Danh sách tất cả thành viên (`/member/list.html`)
*   **Method:** `POST` hoặc `GET`
*   **Payload:**
    ```json
    {
      "keyword": "Nguyễn" // Tùy chọn, lọc theo tên, sđt hoặc email
    }
    ```

---

### 2.5. Quản lý Ca làm việc (`ShiftController`)

#### 2.5.1. Mở ca làm việc (`/shift/open.html`)
*   **Method:** `POST`
*   **Payload:**
    ```json
    {
      "initial_cash": 500000.00 // Bắt buộc, số tiền mặt đầu ca giao nhận bàn giao
    }
    ```
*   **Mô tả:** Nếu nhân viên đã có ca đang mở, hệ thống sẽ trả về luôn thông tin ca đó kèm thông báo tương ứng.

#### 2.5.2. Đóng ca làm việc (`/shift/close.html`)
*   **Method:** `POST`
*   **Payload:**
    ```json
    {
      "actual_cash": 1500000.00, // Bắt buộc, tổng tiền mặt thực tế kiểm đếm cuối ca
      "note": "Hóa đơn thẻ đầy đủ, tiền mặt chuẩn" // Tùy chọn ghi chú bàn giao
    }
    ```
*   **Mô tả:** Hệ thống sẽ tự động tính toán tổng số tiền của các hóa đơn đã thanh toán (`status = paid`) thuộc ca này theo từng phương thức thanh toán:
    *   `total_card_amount` (Tổng tiền thanh toán thẻ)
    *   `total_transfer_amount` (Tổng tiền chuyển khoản)
    *   `expected_cash` = `initial_cash` + Tổng doanh thu tiền mặt (`payment_method = cash`)
    *   `discrepancy_amount` = `actual_cash` - `expected_cash` (Chênh lệch thừa/thiếu tiền mặt bàn giao)

#### 2.5.3. Lấy thông tin ca đang mở (`/shift/current.html`)
*   **Method:** `GET`
*   **Mô tả:** Lấy thông tin chi tiết ca làm việc đang mở hiện tại của nhân viên đăng nhập.

#### 2.5.4. Lịch sử ca làm việc (`/shift/list.html`)
*   **Method:** `GET`
*   **Mô tả:** Trả về danh sách lịch sử ca làm việc.
    *   *Đối với Thu ngân/Phục vụ:* Chỉ xem được danh sách ca của chính mình.
    *   *Đối với Admin/Quản lý:* Xem được toàn bộ ca của tất cả nhân viên.

---

### 2.6. Đơn hàng & Tính tiền dịch vụ (`OrderController`)

#### 2.6.1. Mở bàn chơi / Bắt đầu tính giờ (`/order/open.html`)
*   **Method:** `POST`
*   **Payload:**
    ```json
    {
      "table_id": "table_uuid_here", // Bắt buộc
      "member_id": "optional_member_uuid", // Tùy chọn
      "shift_id": "optional_shift_uuid" // Tùy chọn (Bỏ trống sẽ tự động nhận diện ca đang mở của user hiện tại)
    }
    ```
*   **Phản hồi thành công:** Trả về thông tin hóa đơn vừa tạo và thông tin kích hoạt thiết bị IoT bật đèn bàn (nếu bàn đó có cấu hình IoT):
    ```json
    {
      "status": 1,
      "message": "Mở bàn chơi thành công",
      "data": {
        "order": {
          "id": "order_uuid_here",
          "table_id": "table_uuid_here",
          "status": "active",
          "start_time": "2026-05-22 15:30:00",
          "created_by": "user_uuid_here",
          "total_play_time_minutes": 0,
          "total_play_time_amount": "0.00",
          "total_product_amount": "0.00",
          "discount_amount": "0.00",
          "tax_amount": "0.00",
          "total_amount": "0.00"
        },
        "iot_trigger": {
          "ip_address": "192.168.1.100",
          "port": "8000",
          "channel": 1,
          "command_on": "TURN_ON_CH1"
        }
      }
    }
    ```

#### 2.6.2. Lấy thông tin hóa đơn đang chơi (`/order/active.html`)
*   **Method:** `POST` hoặc `GET`
*   **Payload:**
    ```json
    {
      "table_id": "table_uuid_here" // Bắt buộc
    }
    ```
*   **Phản hồi thành công:** Trả về chi tiết hóa đơn, số phút chơi tạm tính đến thời điểm hiện tại, số tiền giờ tạm tính dựa trên chính sách giá giờ, thông tin thành viên (nếu có) và danh sách sản phẩm dịch vụ đã gọi.
    ```json
    {
      "status": 1,
      "message": "Lấy hóa đơn hoạt động thành công",
      "data": {
        "order": { ... },
        "current_play_time_minutes": 75,
        "current_play_time_amount": 87500.00,
        "member": { ... },
        "details": [
          {
            "id": "detail_uuid",
            "product_id": "product_uuid",
            "quantity": 2,
            "unit_price": "15000.00",
            "total_price": "30000.00",
            "product_name": "Sting dâu",
            "unit": "Chai"
          }
        ]
      }
    }
    ```

#### 2.6.3. Gọi món / Thêm sản phẩm vào hóa đơn (`/order/addDetail.html`)
*   **Method:** `POST`
*   **Payload:**
    ```json
    {
      "order_id": "order_uuid_here", // Bắt buộc
      "product_id": "product_uuid_here", // Bắt buộc
      "quantity": 2 // Tùy chọn, mặc định là 1
    }
    ```
*   **Logic xử lý:** Trừ tồn kho (`stock_quantity`) của sản phẩm tương ứng. Nếu sản phẩm đã có trong đơn, tự động cộng dồn số lượng và cập nhật lại trường `total_product_amount` của hóa đơn chính.

#### 2.6.4. Sửa số lượng món đã gọi (`/order/updateDetail.html`)
*   **Method:** `POST`
*   **Payload:**
    ```json
    {
      "detail_id": "order_detail_uuid_here", // Bắt buộc
      "quantity": 1 // Bắt buộc, số lượng mới (>0)
    }
    ```
*   **Logic xử lý:**
    *   Tự động tính toán chênh lệch số lượng để hoàn trả hoặc khấu trừ thêm tồn kho sản phẩm.
    *   **Bảo mật:** Nếu nhân viên giảm số lượng của sản phẩm xuống thấp hơn số lượng đã gọi trước đó, hệ thống sẽ tự động ghi nhận một bản ghi **Audit Log** ghi lại tên nhân viên thực hiện thao tác giảm món để quản lý kiểm soát gian lận.

#### 2.6.5. Xóa món khỏi hóa đơn (`/order/deleteDetail.html`)
*   **Method:** `POST` hoặc `DELETE`
*   **Payload:**
    ```json
    {
      "detail_id": "order_detail_uuid_here" // Bắt buộc
    }
    ```
*   **Logic xử lý:** Hoàn trả lại toàn bộ số lượng tồn kho cho sản phẩm đó và tự động tạo **Audit Log** ghi nhận hành động xóa món nhạy cảm của nhân viên.

#### 2.6.6. Thanh toán hóa đơn kết thúc phiên chơi (`/order/checkout.html`)
*   **Method:** `POST`
*   **Payload:**
    ```json
    {
      "order_id": "order_uuid_here", // Bắt buộc
      "payment_method": "cash", // Bắt buộc: cash, card, transfer
      "discount_amount": 10000.00, // Tùy chọn, số tiền giảm giá thủ công (chỉ áp dụng bởi nhân viên)
      "tax_percentage": 8.00 // Tùy chọn, % Thuế VAT áp dụng cho tổng hóa đơn sau chiết khấu (e.g. 8 hoặc 10)
    }
    ```
*   **Logic tính toán tiền giờ chơi của hệ thống:**
    1.  **Tính giá giờ:**
        *   Nếu bàn chơi được gán giá giờ cố định (`hourly_rate` của `Table`), hệ thống sẽ tính theo công thức: `(Tổng số giây chơi / 3600) * hourly_rate`.
        *   Nếu không có giá giờ cố định, hệ thống sẽ dò tìm bảng khung giá giờ (`TablePrice`) tương ứng với loại bàn (`table_type_id`) của ngày chơi đó (thứ trong tuần) và múi giờ chơi. Thuật toán tự động tách các khoảng thời gian chơi nằm trong các khung giờ khác nhau để tính giá tiền giờ tương ứng theo tỷ lệ giây, sau đó cộng dồn lại.
    2.  **Chiết khấu hạng thành viên:** Nếu hóa đơn có liên kết với thành viên tích điểm, hệ thống tự động dò tìm tỷ lệ phần trăm giảm giá hạng thành viên (ví dụ VIP Bạc được giảm 10% tổng tiền giờ + tiền dịch vụ).
    3.  **Chiết khấu thủ công:** Cộng dồn chiết khấu thành viên và chiết khấu thủ công gửi lên từ payload (`discount_amount`). Nếu có chiết khấu thủ công, hệ thống sẽ tự động tạo **Audit Log** lưu vết nhân viên thực hiện.
    4.  **Tích điểm thành viên:** Nếu có thành viên, hệ thống cộng điểm tích lũy mới vào tài khoản thành viên theo tỷ lệ: **Cứ mỗi 10,000 VND doanh thu hóa đơn cuối cùng sẽ được quy đổi thành 1 điểm**. Đồng thời tự động cập nhật nâng hạng thành viên nếu tổng số điểm đạt mốc nâng hạng mới.
    5.  **Thiết bị IoT:** Trả về thông tin lệnh rơ-le để thiết bị khách tự động tắt đèn bàn.
*   **Phản hồi thành công:**
    ```json
    {
      "status": 1,
      "message": "Thanh toán và kết thúc phiên thành công",
      "data": {
        "order": {
          "id": "order_uuid_here",
          "table_id": "table_uuid_here",
          "status": "paid",
          "start_time": "2026-05-22 14:00:00",
          "end_time": "2026-05-22 15:30:00",
          "total_play_time_minutes": 90,
          "total_play_time_amount": "90000.00",
          "total_product_amount": "50000.00",
          "discount_amount": "17000.00", // (Chiết khấu VIP 5% + Giảm giá tay 10,000đ)
          "tax_amount": "9840.00", // 8% VAT của (90k + 50k - 17k)
          "total_amount": "132840.00",
          "payment_method": "cash",
          ...
        },
        "iot_trigger": {
          "ip_address": "192.168.1.100",
          "port": "8000",
          "channel": 1,
          "command_off": "TURN_OFF_CH1"
        }
      }
    }
    ```

#### 2.6.7. Hủy bàn / Hủy hóa đơn (`/order/void.html`)
*   **Method:** `POST`
*   **Payload:**
    ```json
    {
      "order_id": "order_uuid_here", // Bắt buộc
      "reason": "Khách vào ngồi nhầm bàn, không chơi" // Bắt buộc lý do hủy
    }
    ```
*   **Logic xử lý:**
    *   Đổi trạng thái hóa đơn về `cancelled`, giải phóng bàn về `idle`.
    *   Hoàn trả lại toàn bộ tồn kho các sản phẩm dịch vụ đã gọi trong hóa đơn.
    *   Tạo bản ghi **Audit Log** lưu vết chi tiết người hủy bàn, bàn bị hủy và lý do hủy.
    *   Trả về tín hiệu tắt đèn IoT rơ-le.

#### 2.6.8. Lịch sử hóa đơn (`/order/history.html`)
*   **Method:** `POST` hoặc `GET`
*   **Payload:**
    ```json
    {
      "page": 1,
      "per_page": 20,
      "table_id": "optional_table_uuid", // Lọc theo bàn
      "status": "paid" // paid hoặc cancelled (mặc định lấy cả hai, không hiển thị hóa đơn active)
    }
    ```

---

### 2.7. Điều khiển Thiết bị IoT & Nhật ký can thiệp (`IotController`)

#### 2.7.1. Lấy cấu hình IoT toàn bộ các bàn (`/iot/configs.html`)
*   **Method:** `GET`
*   **Xác thực:** Bắt buộc (Bearer Token)
*   **Phản hồi thành công:**
    ```json
    {
      "status": 1,
      "message": "Lấy cấu hình IoT thành công",
      "data": [
        {
          "id": 1,
          "table_id": "table_uuid_here",
          "connection_type": "tcp_ip",
          "ip_address": "192.168.1.100",
          "port": "8000",
          "relay_channel": 1,
          "command_on": "TURN_ON_CH1",
          "command_off": "TURN_OFF_CH1",
          "created_at": "2026-05-21 16:20:21",
          "updated_at": "2026-05-21 16:20:21"
        }
      ]
    }
    ```

#### 2.7.2. Lưu cấu hình IoT cho bàn (`/iot/saveConfig.html`)
*   **Method:** `POST`
*   **Xác thực:** Bắt buộc (Chỉ Admin hoặc Manager)
*   **Payload:**
    ```json
    {
      "table_id": "table_uuid_here", // Bắt buộc, duy nhất cho mỗi bàn
      "connection_type": "tcp_ip", // Bắt buộc: tcp_ip hoặc serial
      "ip_address": "192.168.1.100", // Tùy chọn (Bắt buộc nếu connection_type là tcp_ip)
      "port": "8000", // Tùy chọn (Bắt buộc nếu connection_type là tcp_ip)
      "relay_channel": 1, // Bắt buộc (>0, kênh rơ-le trên hộp điều khiển)
      "command_on": "TURN_ON_CH1", // Bắt buộc, lệnh gửi đi để bật rơ-le
      "command_off": "TURN_OFF_CH1" // Bắt buộc, lệnh gửi đi để tắt rơ-le
    }
    ```

#### 2.7.3. Can thiệp bật/tắt đèn thủ công (Cưỡng bức) (`/iot/forceAction.html`)
*   **Method:** `POST`
*   **Payload:**
    ```json
    {
      "table_id": "table_uuid_here", // Bắt buộc
      "action": "on", // Bắt buộc: on hoặc off
      "reason": "Khách mượn đèn kiểm tra đầu cơ gậy", // Bắt buộc (Lý do can thiệp rơ-le)
      "device_info": "Admin Web Client" // Tùy chọn thiết bị gọi lệnh
    }
    ```
*   **Logic xử lý:** Hệ thống không làm thay đổi trạng thái hóa đơn hay tính tiền giờ, nhưng sẽ gửi trả về lệnh điều khiển và bắt buộc ghi nhận sự kiện can thiệp thủ công này vào **Audit Log** của hệ thống kèm theo lý do bắt buộc để ngăn chặn thất thoát giờ chơi.

#### 2.7.4. Nhật ký can thiệp hệ thống (`/iot/auditLogs.html`)
*   **Method:** `POST` hoặc `GET`
*   **Xác thực:** Bắt buộc (Chỉ Admin hoặc Manager)
*   **Payload:**
    ```json
    {
      "table_id": "optional_table_uuid", // Lọc theo bàn chơi
      "action_type": "FORCE_ON_TABLE" // Lọc theo hành động (ví dụ: FORCE_ON_TABLE, FORCE_OFF_TABLE, APPLY_MANUAL_DISCOUNT, DELETE_ORDER_ITEM, VOID_ORDER)
    }
    ```
*   **Phản hồi thành công:** Trả về tối đa 100 dòng lịch sử can thiệp hệ thống mới nhất xếp thứ tự thời gian giảm dần.

---

### 2.8. Thống kê & Báo cáo tổng hợp (`DashboardController`)

#### 2.8.1. Lấy dữ liệu thống kê tổng hợp (`/dashboard/index.html`)
*   **Method:** `POST` hoặc `GET`
*   **Xác thực:** Bắt buộc (Chỉ Admin hoặc Manager)
*   **Payload:**
    ```json
    {
      "from_date": "2026-05-22", // Tùy chọn (Mặc định hôm nay)
      "end_date": "2026-05-22" // Tùy chọn (Mặc định hôm nay)
    }
    ```
*   **Phản hồi thành công:**
    ```json
    {
      "status": 1,
      "message": "Lấy dữ liệu thống kê thành công",
      "data": {
        "revenue": 1280000.00, // Tổng doanh thu hóa đơn đã thanh toán trong khoảng thời gian lọc
        "tables": {
          "total": 6, // Tổng số bàn chơi trong câu lạc bộ
          "active": 2, // Số bàn hiện tại đang có khách chơi (active)
          "occupancy_rate": 33.33 // Tỷ lệ lấp đầy bàn hiện tại (%)
        },
        "shifts": {
          "open_count": 1, // Số ca làm việc đang mở hiện tại
          "drawer_cash": 1250000.00 // Số tiền mặt lý thuyết đang có trong két kéo tiền
        },
        "hourly_chart": [0, 0, 0, 0, 0, 0, 0, 2, 4, 1, 0, ...], // Mảng 24 phần tử (tương ứng 0h đến 23h) lưu số lượt mở bàn chơi theo khung giờ
        "recent_audit_logs": [ ... ] // Danh sách 10 bản ghi nhật ký can thiệp hệ thống mới nhất
      }
    }
    ```

#### 2.8.2. Lấy bộ lọc thời gian mẫu (`/dashboard/filterDates.html`)
*   **Method:** `GET`
*   **Xác thực:** Bắt buộc (Bearer Token)
*   **Mô tả:** Trả về các cấu hình ngày bắt đầu/kết thúc được tính toán sẵn cho các mốc: Hôm nay (`today`), Tuần này (`this_week`), Tháng này (`this_month`), Tuần trước (`last_week`), Tháng trước (`last_month`).

---

### 2.9. Đồng bộ hóa dữ liệu offline (`SyncController`)

#### 2.9.1. Đồng bộ dữ liệu máy trạm lên CRM Cloud (`/sync/desktop.html`)
*   **Method:** `POST`
*   **Xác thực:** Bắt buộc (Bearer Token)
*   **Payload:**
    Mảng dữ liệu các dòng cập nhật hoặc thêm mới tích lũy từ cơ sở dữ liệu SQLite ngoại tuyến của máy trạm khi mất mạng:
    ```json
    {
      "members": [ ... ],
      "shifts": [ ... ],
      "orders": [ ... ],
      "order_details": [ ... ],
      "audit_logs": [ ... ]
    }
    ```
*   **Logic xử lý:** Thực thi đồng bộ trong một **Database Transaction** an toàn. Lần lượt cập nhật hoặc tạo mới các bản ghi theo Khóa chính UUID được gửi lên từ Desktop Client.
*   **Phản hồi thành công:**
    ```json
    {
      "status": 1,
      "message": "Đồng bộ hóa dữ liệu thành công",
      "data": {
        "shifts": 2,
        "members": 1,
        "orders": 5,
        "order_details": 12,
        "audit_logs": 3
      }
    }
    ```

---

## 3. Cấu trúc Thực thể (Database Table Schemas Reference)

Các mô hình AI và lập trình viên cần bám sát các thuộc tính dữ liệu dưới đây khi xây dựng các đối tượng payload hoặc đọc kết quả trả về từ cơ sở dữ liệu:

### 3.1. Users (Tài khoản nhân viên)
*   `id`: `char(36)` (UUID, Khóa chính)
*   `username`: `varchar(50)` (Tên đăng nhập, duy nhất)
*   `display_name`: `varchar(100)` (Tên hiển thị)
*   `role`: `varchar(20)` (`admin` | `manager` | `cashier` | `waiter`)
*   `phone_number`: `varchar(15)` (Số điện thoại)
*   `is_active`: `tinyint(1)` (Trạng thái hoạt động)

### 3.2. Tables (Bàn chơi)
*   `id`: `char(36)` (UUID, Khóa chính)
*   `table_name`: `varchar(50)` (Tên bàn chơi)
*   `area_id`: `int` (Khóa ngoại đến `areas`)
*   `table_type_id`: `int` (Khóa ngoại đến `table_types`)
*   `hourly_rate`: `decimal(10,2)` (Giá giờ cố định nếu có)
*   `status`: `varchar(20)` (`idle` | `active` | `booked` | `maintenance`)
*   `current_order_id`: `char(36)` (ID hóa đơn đang hoạt động nếu status = active)
*   `sort_order`: `int` (Thứ tự sắp xếp)

### 3.3. Areas (Khu vực)
*   `id`: `int` (Khóa chính tự tăng)
*   `area_name`: `varchar(50)` (Tên khu vực)
*   `description`: `text` (Mô tả khu vực)

### 3.4. Shifts (Ca làm việc)
*   `id`: `char(36)` (UUID, Khóa chính)
*   `user_id`: `char(36)` (Nhân viên mở ca)
*   `start_time`: `timestamp` (Thời điểm bắt đầu)
*   `end_time`: `timestamp` (Thời điểm kết ca)
*   `initial_cash`: `decimal(12,2)` (Tiền bàn giao đầu ca)
*   `expected_cash`: `decimal(12,2)` (Tiền mặt lý thuyết cuối ca)
*   `actual_cash`: `decimal(12,2)` (Tiền mặt thực tế kiểm kê)
*   `total_card_amount`: `decimal(12,2)` (Doanh thu thẻ)
*   `total_transfer_amount`: `decimal(12,2)` (Doanh thu chuyển khoản)
*   `discrepancy_amount`: `decimal(12,2)` (Chênh lệch két tiền mặt)
*   `status`: `varchar(20)` (`open` | `closed`)

### 3.5. Orders (Hóa đơn chơi bida)
*   `id`: `char(36)` (UUID, Khóa chính)
*   `table_id`: `char(36)` (Bàn chơi tương ứng)
*   `member_id`: `char(36)` (Khách hàng thành viên nếu có)
*   `shift_id`: `char(36)` (Ca làm việc ghi nhận hóa đơn)
*   `status`: `varchar(20)` (`active` | `paid` | `cancelled`)
*   `start_time`: `timestamp` (Giờ bắt đầu)
*   `end_time`: `timestamp` (Giờ kết thúc)
*   `total_play_time_minutes`: `int` (Tổng số phút chơi)
*   `total_play_time_amount`: `decimal(12,2)` (Tiền giờ chơi bida)
*   `total_product_amount`: `decimal(12,2)` (Tổng tiền sản phẩm dịch vụ ăn uống)
*   `discount_amount`: `decimal(12,2)` (Tổng số tiền chiết khấu VIP + thủ công)
*   `tax_amount`: `decimal(12,2)` (Số tiền thuế VAT)
*   `total_amount`: `decimal(12,2)` (Tổng số tiền khách thanh toán thực tế)
*   `payment_method`: `varchar(20)` (`cash` | `card` | `transfer`)
*   `created_by`: `char(36)` (Nhân viên mở bàn)
*   `closed_by`: `char(36)` (Nhân viên chốt hóa đơn thanh toán)

### 3.6. Products (Sản phẩm ăn uống & Dịch vụ)
*   `id`: `char(36)` (UUID, Khóa chính)
*   `product_name`: `varchar(100)` (Tên sản phẩm)
*   `category_id`: `int` (Khóa ngoại đến danh mục sản phẩm)
*   `unit`: `varchar(20)` (Đơn vị tính: lon, chai, đĩa...)
*   `selling_price`: `decimal(10,2)` (Giá bán lẻ)
*   `cost_price`: `decimal(10,2)` (Giá vốn)
*   `stock_quantity`: `int` (Tồn kho hiện tại)
*   `barcode`: `varchar(50)` (Mã vạch)
*   `is_active`: `tinyint(1)` (Trạng thái bán)

### 3.7. Members (Khách hàng thành viên)
*   `id`: `char(36)` (UUID, Khóa chính)
*   `full_name`: `varchar(100)` (Tên khách hàng)
*   `phone_number`: `varchar(15)` (Số điện thoại khách hàng, duy nhất)
*   `membership_tier_id`: `int` (Hạng thành viên hiện tại)
*   `total_points`: `int` (Điểm tích lũy hiện tại)
*   `accumulated_spend`: `decimal(12,2)` (Tổng tích lũy chi tiêu)

### 3.8. IotConfigs (Cấu hình điều khiển đèn rơ-le)
*   `table_id`: `char(36)` (Bàn chơi áp dụng, khóa chính)
*   `connection_type`: `varchar(20)` (`tcp_ip` | `serial`)
*   `ip_address`: `varchar(50)` (IP rơ-le kết nối mạng)
*   `port`: `varchar(20)` (Cổng kết nối mạng rơ-le)
*   `relay_channel`: `int` (Kênh rơ-le điều khiển đèn bàn bida)
*   `command_on`: `varchar(255)` (Chuỗi câu lệnh bật rơ-le)
*   `command_off`: `varchar(255)` (Chuỗi câu lệnh tắt rơ-le)

### 3.9. AuditLogs (Nhật ký sự kiện can thiệp nhạy cảm)
*   `id`: `char(36)` (UUID, Khóa chính)
*   `user_id`: `char(36)` (Nhân viên thao tác)
*   `action_type`: `varchar(50)` (Loại sự kiện nhạy cảm)
    *   *Các loại sự kiện chính:* `FORCE_ON_TABLE` | `FORCE_OFF_TABLE` | `APPLY_MANUAL_DISCOUNT` | `DELETE_ORDER_ITEM` | `VOID_ORDER` | `SYNC_OFFLINE`
*   `table_id`: `char(36)` (Bàn chơi liên quan)
*   `order_id`: `char(36)` (Hóa đơn liên quan)
*   `description`: `text` (Mô tả chi tiết và lý do bắt buộc nhập từ nhân viên)
*   `device_info`: `varchar(255)` (Thông tin thiết bị gọi lệnh)
*   `created_at`: `timestamp` (Thời gian sự kiện xảy ra)
