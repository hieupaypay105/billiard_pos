# TÀI LIỆU PHÂN TÍCH VÀ CẤU TRÚC DỰ ÁN HỆ THỐNG QUẢN LÝ CLB BILLIARDS (BIDA)

## ĐỐI TƯỢNG ĐỌC: Antigravity IDE & AI Code Assistant

---

## 1. TỔNG QUAN HỆ THỐNG (SYSTEM OVERVIEW)

Hệ thống quản lý CLB Bi-a toàn diện bao gồm 3 ứng dụng cốt lõi, chia sẻ chung một hệ thống Cơ sở dữ liệu và Backend Services. Hệ thống có tính năng đặc thù là điều khiển phần cứng (IoT) để tự động hóa việc bật/tắt điện và tính giờ của bàn Bi-a.

### Thành phần hệ thống:
1. **Billiard Desktop Client (Flutter Desktop - Windows):** Ứng dụng bán hàng, vận hành trực tiếp tại quầy thu ngân. Tích hợp module điều khiển IoT qua cổng Serial (RS485/USB) hoặc LAN (TCP/IP) để đóng ngắt relay rơ-le đèn bàn, tự động tính giờ khi bật bàn, quản lý hóa đơn, thống kê nhanh.
2. **Billiard POS Mobile (Flutter Mobile - Android/iOS):** Ứng dụng cho nhân viên chạy bàn. Order đồ ăn, nước uống, thêm dịch vụ vào bàn của khách từ xa mà không cần quay lại quầy.
3. **Billiard Manager Mobile (Flutter Mobile - Android/iOS):** Ứng dụng dành riêng cho Chủ CLB. Xem báo cáo doanh thu real-time, biểu đồ tần suất sử dụng bàn, quản lý nhân sự, lịch sử dòng tiền và cấu hình hệ thống.

---

## 2. KIẾN TRÚC MÃ NGUỒN (PROJECT ARCHITECTURE)

Để tối ưu hóa thời gian phát triển và tái sử dụng code (nhất là các Object Model, API Client, Dòng logic tính tiền), dự án sẽ được cấu trúc theo dạng **Monorepo** sử dụng giải pháp **Flutter Workspaces** hoặc quản lý qua các Local Packages.

### Sơ đồ cấu trúc thư mục (Directory Tree)

Dưới đây là sơ đồ cấu trúc thư mục Monorepo đề xuất cho hệ thống:

```text
billiard_pos_monorepo/
├── apps/
│   ├── billiard_desktop/          # Billiard Desktop Client (Windows)
│   │   └── lib/
│   ├── billiard_pos_mobile/       # Billiard POS Mobile (Android/iOS)
│   │   └── lib/
│   └── billiard_manager_mobile/   # Billiard Manager Mobile (Android/iOS)
│       └── lib/
├── packages/
│   ├── core_shared/               # Models, API Clients, Core Logic dùng chung
│   │   └── lib/
│   └── iot_controller/            # Module điều khiển IoT (Serial/TCP-IP)
│       └── lib/
├── pubspec.yaml                   # Cấu hình Flutter Workspace
└── README.md
```

---

## 3. PHÂN TÍCH LUỒNG NGHIỆP VỤ & TÍCH HỢP IOT

### 3.1. Cơ chế kích hoạt bàn và đếm giờ tự động (IoT Integration trên Desktop)

* **Thiết bị ngoại vi:** Bộ mạch Relay Matrix điều khiển nguồn điện của đèn từng bàn (kết nối qua RS485 chuyển đổi sang USB gắn vào máy tính, hoặc module Relay LAN nhận lệnh qua TCP/IP).
* **Luồng xử lý (Workflow):**
  1. Thu ngân nhấn nút **"Bật bàn 01"** trên giao diện Flutter Desktop.
  2. Giao diện trigger một Event xử lý qua package `flutter_libserialport` (nếu dùng cổng COM) hoặc `dart:io` Socket (nếu dùng LAN).
  3. Gửi chuỗi Byte lệnh (Hex Command) tới bộ điều khiển (Ví dụ: `01 05 00 00 FF 00 8C 3A` để đóng Rơ-le số 1).
  4. Mạch phần cứng đóng cổng cấp điện -> Đèn bàn 01 sáng lên.
  5. Đồng thời, Local Database / Backend ghi nhận thời gian bắt đầu: `start_time = DateTime.now()`. Trạng thái bàn chuyển sang đang hoạt động.
  6. Một Timer trong Flutter chạy ngầm để cập nhật thời gian sử dụng theo thời gian thực (Real-time counter) hiển thị lên Dashboard quầy.
  7. Khi nhấn **"Thanh toán"**: Gửi lệnh tắt rơ-le -> Đèn bàn tắt. Ghi nhận `end_time`, tính tổng số phút, nhân với đơn giá của loại bàn (Bàn Pool, Carom, Snooker) có cấu hình phân theo khung giờ.

### 3.2. Luồng đồng bộ hóa Real-time (Websocket)

1. Khi ứng dụng Mobile POS của nhân viên thêm 1 chai nước vào **"Bàn 01"**.
2. Dữ liệu bắn lên Server -> Server phát tín hiệu qua Websocket/SSE tới Desktop Client.
3. Màn hình Desktop tự động cập nhật danh sách dịch vụ đi kèm của Bàn 01 mà không cần tải lại trang.

---

## 4. CHI TIẾT TÍNH NĂNG THEO TỪNG PHÂN HỆ

### 4.1. Bản Desktop (Thu ngân & Vận hành quầy)

* **Quản lý lưới bàn (Grid view):** Hiển thị trực quan sơ đồ danh sách bàn. Phân biệt màu sắc rõ ràng (Bàn trống: Xám nhạt, Bàn có khách: Xanh mint/Gỗ ấm, Bàn đặt trước: Vàng nhạt).
* **Xử lý hóa đơn (Billing):** Gộp bàn, chuyển bàn, tách hóa đơn, áp dụng mã giảm giá, tính chiết khấu cho hội viên.
* **Tích hợp IoT:** Quản lý cổng kết nối phần cứng, cấu hình mapping ID của Rơ-le tương ứng với số bàn trong phần mềm.
* **Báo cáo cuối ca:** Thống kê tiền mặt, tiền chuyển khoản, doanh thu dịch vụ, doanh thu giờ chơi trước khi bàn giao ca.
* **In ấn:** Kết nối trực tiếp với máy in hóa đơn K80 qua giao thức USB/LAN.

### 4.2. Bản Mobile POS (Nhân viên Order)

* **Xem sơ đồ bàn nhanh:** Biết bàn nào đang trống, bàn nào đang chơi để dẫn khách.
* **Thêm dịch vụ:** Giao diện tìm kiếm nhanh món ăn, nước uống, thuốc lá, tính năng quét barcode (nếu cần) để thêm trực tiếp vào bàn.
* **Gửi yêu cầu:** Chuyển order xuống khu vực bếp/quầy pha chế.

### 4.3. Bản Mobile Manager (Chủ CLB)

* **Real-time Dashboard:** Biểu đồ doanh thu hôm nay, tuần này, tháng này. Số lượng bàn đang hoạt động hiện tại.
* **Báo cáo chuyên sâu:** Biểu đồ đường (Line chart) thể hiện tần suất lấp đầy bàn theo các khung giờ trong ngày (để đưa ra chương trình khuyến mãi giờ thấp điểm).
* **Quản lý danh mục:** Quản lý bảng giá giờ chơi, danh mục hàng hóa, quản lý phân quyền tài khoản nhân viên.
* **Lịch sử hệ thống:** Xem log bật/tắt bàn, sửa xóa hóa đơn để chống gian lận từ nhân viên.

---

## 5. PHÁC THẢO GIAO DIỆN (UI/UX CONCEPT)

Tuân thủ phong cách thiết kế tối giản Bắc Âu (Scandinavian Minimalism):

### Bảng màu (Palette):
* **Chủ đạo (Background):** Trắng ngà nhạt (`#F8F9FA`) hoặc Xám đá nhạt (`#ECEFF1`).
* **Điểm nhấn (Accent Color):** Xanh xám lá thông (`#2E4F4F`) hoặc Xanh Teal dịu mắt, tránh dùng các màu neon lòe loẹt.
* **Văn bản (Text):** Màu than củi (`#212121`) giúp tương phản tốt nhưng không bị mỏi mắt.

### Bố cục (Layout):
* Tận dụng khoảng trắng (Whitespace) lớn để thu ngân không bị rối mắt khi thao tác liên tục.
* Nút bấm lớn, bo góc (`borderRadius: BorderRadius.circular(12)`), dễ tương tác trên màn hình cảm ứng POS.

---

## 6. KẾ HOẠCH TRIỂN KHAI DỰ ÁN (PROJECT IMPLEMENTATION PLAN)

Kế hoạch được chia làm 4 giai đoạn chính (Sprint):

### GIAI ĐOẠN 1: THIẾT KẾ DB, HỆ THỐNG CHUNG VÀ MÔ PHỎNG IOT (Tuần 1 - Tuần 2)
* [ ] Thiết kế cơ sở dữ liệu (Tables: `tables`, `orders`, `order_details`, `products`, `members`, `iot_config`).
* [ ] Khởi tạo cấu trúc Monorepo Flutter và thiết lập package `core_shared`.
* [ ] Viết Module kết nối và giả lập tín hiệu IoT (Serial/TCP-IP) trên Desktop để test đóng ngắt rơ-le không cần phần cứng thật.

### GIAI ĐOẠN 2: PHÁT TRIỂN LÕI DESKTOP POS & IOT (Tuần 3 - Tuần 5)
* [ ] Xây dựng giao diện Sơ đồ bàn (Grid View) phong cách tối giản.
* [ ] Triển khai Logic tính giờ chạy ngầm sử dụng Isolate để đảm bảo UI đạt hiệu năng 60fps+.
* [ ] Tích hợp bộ thư viện `flutter_libserialport` để kết nối mạch cứng thật.
* [ ] Hoàn thiện module lên hóa đơn, in hóa đơn K80 và đóng ca.

### GIAI ĐOẠN 3: PHÁT TRIỂN HAI BẢN MOBILE (Tuần 6 - Tuần 8)
* [ ] Phát triển app Mobile POS: Kết nối Websocket đồng bộ trạng thái bàn, tính năng chọn món nhanh cho nhân viên.
* [ ] Phát triển app Mobile Manager: Tích hợp các thư viện biểu đồ chuyên sâu (`fl_chart`), màn hình giám sát doanh thu thời gian thực và quản trị phân quyền.

### GIAI ĐOẠN 4: KIỂM THỬ TỔNG THỂ, TỐI ƯU HIỆU NĂNG VÀ ĐÓNG GÓI (Tuần 9)
* [ ] Kiểm thử khả năng chịu tải khi nhận dữ liệu dồn dập từ các thiết bị IoT và Mobile Client cùng lúc.
* [ ] Tối ưu hóa bộ nhớ RAM của bản Desktop, đảm bảo duy trì ổn định dưới mức 80MB khi chạy liên tục 24/7.
* [ ] Đóng gói cài đặt: `.exe` cho Windows Desktop, `.apk` / `.ipa` cho Mobile.