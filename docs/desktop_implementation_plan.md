# Kế Hoạch Dựng Layout Desktop – Billiard POS

## Tổng quan

Ứng dụng `billiard_desktop` hiện chỉ có một màn hình **DashboardScreen** đơn khối (monolithic) trong `main.dart` (~1091 dòng), gộp chung logic bàn + IoT. Mục tiêu sprint này là **tái cấu trúc + bổ sung toàn bộ layout** cho tất cả chức năng đã yêu cầu, đảm bảo codebase có thể mở rộng và kiểm thử được.

---

## User Review Required

> [!IMPORTANT]
> **Lựa chọn State Management**: Kế hoạch sử dụng **Riverpod** (`flutter_riverpod`) vì dự án đã dùng Flutter 3.x, Riverpod phù hợp với kiến trúc feature-based và dễ unit test hơn `setState`. Nếu bạn muốn dùng `Provider` truyền thống hoặc `Bloc`, hãy cho biết.

> [!IMPORTANT]
> **API Base URL**: Kế hoạch tạo lớp `ApiClient` kết nối với backend `billiard_pos_crm`. Cần xác nhận base URL của API (hiện tại lấy từ `.env` file trong root project). Biến `API_BASE_URL` đã có trong `.env` chưa?

> [!WARNING]
> **Refactor `main.dart`**: File `main.dart` hiện tại (1091 dòng) sẽ được thu gọn về ~50 dòng (chỉ giữ `main()` + `MaterialApp`). Toàn bộ logic sẽ chuyển vào các screen/widget riêng biệt. Đây là **breaking change** về cấu trúc file nhưng không thay đổi chức năng hiện có.

---

## Open Questions

> [!IMPORTANT]
> **Đăng nhập**: Hiện tại app load thẳng `DashboardScreen`. Bạn muốn flow đăng nhập là:
> - (A) Màn hình login riêng → token lưu vào `SharedPreferences` → route vào main shell
> - (B) Luôn mở app với session đã lưu, chỉ hỏi login khi hết token (auto-refresh)

> [!IMPORTANT]
> **Đồng bộ Offline/Online**: Bạn muốn dùng local database nào?
> - (A) **SQLite** (`sqflite`) – ổn định, phổ biến
> - (B) **Isar** – hiệu năng cao hơn, NoSQL style, API tiện hơn
> - (C) **Drift** (SQLite ORM) – type-safe, hỗ trợ migration tốt

> [!IMPORTANT]
> **In hóa đơn K80**: Bạn đã có thư viện in hay muốn tích hợp `esc_pos_utils` + `flutter_pos_printer_platform`?

---

## Proposed Changes

### 1. Cấu trúc thư mục mới – `billiard_desktop/lib/`

```
lib/
├── main.dart                      # [MODIFY] Chỉ còn ~50 dòng: main() + App widget
├── app.dart                       # [NEW] MaterialApp + Router config
├── core/
│   ├── constants/
│   │   ├── app_colors.dart        # [NEW] Color palette
│   │   └── app_text_styles.dart   # [NEW] Typography
│   ├── router/
│   │   └── app_router.dart        # [NEW] go_router routes
│   ├── providers/
│   │   └── providers.dart         # [NEW] Riverpod global providers
│   ├── services/
│   │   ├── api_client.dart        # [NEW] HTTP client → billiard_pos_crm API
│   │   ├── local_db_service.dart  # [NEW] SQLite/Isar local sync DB
│   │   └── sync_service.dart      # [NEW] Offline→Online sync logic
│   └── widgets/
│       ├── app_shell.dart         # [NEW] NavigationRail + content area
│       └── status_bar.dart        # [NEW] Bottom bar: user, shift, clock, sync status
│
├── features/
│   ├── auth/
│   │   ├── login_screen.dart      # [NEW] Màn hình đăng nhập
│   │   └── auth_provider.dart     # [NEW] Login state + token
│   │
│   ├── tables/
│   │   ├── tables_screen.dart     # [REFACTOR from main.dart] Grid bàn
│   │   ├── table_card.dart        # [MOVE from src/widgets/]
│   │   └── tables_provider.dart   # [NEW] State bàn + IoT actions
│   │
│   ├── billing/
│   │   ├── billing_screen.dart    # [NEW] Panel hóa đơn của bàn được chọn
│   │   ├── invoice_dialog.dart    # [REFACTOR from main.dart] Dialog thanh toán
│   │   ├── add_product_panel.dart # [NEW] Thêm sản phẩm/dịch vụ vào hóa đơn
│   │   ├── member_lookup.dart     # [NEW] Tra cứu + gắn thành viên
│   │   ├── discount_panel.dart    # [NEW] Áp dụng khuyến mãi/giảm giá tay
│   │   ├── table_merge_dialog.dart  # [NEW] Gộp bàn
│   │   ├── table_split_dialog.dart  # [NEW] Tách hóa đơn
│   │   ├── table_transfer_dialog.dart # [NEW] Chuyển bàn
│   │   └── billing_provider.dart  # [NEW] State hóa đơn hoạt động
│   │
│   ├── statistics/
│   │   ├── statistics_screen.dart # [NEW] Thống kê: hóa đơn, ca, sản phẩm
│   │   ├── shift_summary_card.dart # [NEW] Widget tóm tắt ca
│   │   └── statistics_provider.dart # [NEW]
│   │
│   ├── reports/
│   │   ├── reports_screen.dart    # [NEW] Báo cáo: hóa đơn, thành viên, SP/DV
│   │   ├── invoice_report_tab.dart
│   │   ├── member_report_tab.dart
│   │   ├── product_report_tab.dart
│   │   └── reports_provider.dart  # [NEW]
│   │
│   └── sync/
│       ├── sync_screen.dart       # [NEW] Trạng thái sync + log
│       └── sync_provider.dart     # [NEW]
```

---

### 2. Dependencies mới cần thêm vào `pubspec.yaml`

#### [MODIFY] [pubspec.yaml](file:///Users/hieukona/Downloads/app/billiard_pos/apps/billiard_desktop/pubspec.yaml)

| Package | Mục đích |
|---|---|
| `flutter_riverpod` | State management |
| `go_router` | Navigation / routing |
| `dio` | HTTP client → API |
| `shared_preferences` | Lưu token login |
| `sqflite` / `isar` | Local DB (offline) |
| `path_provider` | Đường dẫn DB trên desktop |
| `intl` | Format số tiền, ngày giờ |
| `fl_chart` | Biểu đồ thống kê |
| `data_table_2` | Bảng dữ liệu nâng cao |

---

### 3. Core Shell – Navigation

#### [NEW] `core/widgets/app_shell.dart`

Layout chính sau khi đăng nhập dùng **NavigationRail** (rail dọc bên trái, phù hợp desktop):

```
┌─────────────────────────────────────────────────────────┐
│  AppBar: Logo | Tên CLB | Giờ thực | Trạng thái sync   │
├──────┬──────────────────────────────────────────────────┤
│      │                                                  │
│  Nav │             Content Area                         │
│ Rail │          (Màn hình hiện tại)                     │
│      │                                                  │
│  🏠  │                                                  │
│ Bàn  │                                                  │
│  📋  │                                                  │
│ HĐơn │                                                  │
│  📊  │                                                  │
│ TKê  │                                                  │
│  📑  │                                                  │
│ Báo  │                                                  │
│  ☁️  │                                                  │
│ Sync │                                                  │
├──────┴──────────────────────────────────────────────────┤
│  StatusBar: Nhân viên | Ca | Số bàn đang chơi | Clock  │
└─────────────────────────────────────────────────────────┘
```

---

### 4. Màn hình chi tiết

#### [NEW] `features/auth/login_screen.dart`
- Form: username + password, nút Đăng nhập
- Gọi API `POST /api/auth/login` → nhận JWT token
- Lưu token vào `SharedPreferences`
- Chuyển hướng → `AppShell`

#### [REFACTOR] `features/tables/tables_screen.dart`
- Grid bàn (giữ nguyên logic hiện tại từ `main.dart`)
- Thêm filter: Tất cả / Đang chơi / Trống / Bảo trì
- Nút bật/tắt bàn → gọi IoT + cập nhật hóa đơn
- Hiển thị realtime timer (giữ nguyên Ticker logic)

#### [NEW] `features/billing/billing_screen.dart`
- Panel 2 cột: **Trái** = Danh sách sản phẩm/DV (grid có tìm kiếm), **Phải** = Hóa đơn hiện tại
- Thêm sản phẩm → gọi API `POST /api/order-details`
- Các action: Gộp bàn | Tách hóa đơn | Chuyển bàn | Áp mã KM | Thành viên | Thanh toán | In

#### [NEW] `features/statistics/statistics_screen.dart`
- Tab 1: **Hóa đơn hôm nay** – bảng danh sách + tổng doanh thu
- Tab 2: **Ca thu ngân** – mở ca, đóng ca, đối soát tiền
- Tab 3: **Sản phẩm/DV bán chạy** – top products + biểu đồ `fl_chart`

#### [NEW] `features/reports/reports_screen.dart`
- Tab 1: **Báo cáo hóa đơn** – filter theo ngày, xuất CSV
- Tab 2: **Thành viên** – danh sách, điểm tích lũy, hạng
- Tab 3: **Sản phẩm/DV** – tồn kho, doanh thu

#### [NEW] `features/sync/sync_screen.dart`
- Hiển thị trạng thái: Online ✅ / Offline ⚠️
- Số bản ghi chờ sync, nút "Sync ngay"
- Log đồng bộ chi tiết

---

### 5. API Client Layer

#### [NEW] `core/services/api_client.dart`
- Dùng `dio` với `BaseOptions(baseUrl: Env.apiBaseUrl)`
- Interceptor: tự động đính kèm JWT Bearer token
- Interceptor: retry khi 401 (refresh token)
- Interceptor: queue request khi offline → sync khi online

---

### 6. Unit Tests

#### [MODIFY] `test/` directory – thêm các test:

| File test | Nội dung |
|---|---|
| `test/models/order_model_test.dart` | Serialize/deserialize JSON |
| `test/services/api_client_test.dart` | Mock HTTP, kiểm tra endpoint |
| `test/features/billing/billing_provider_test.dart` | Tính tiền giờ, thêm SP |
| `test/features/tables/tables_provider_test.dart` | Toggle bàn, IoT sim |
| `test/features/auth/auth_provider_test.dart` | Login flow, token lưu trữ |

---

## Verification Plan

### Automated Tests
```bash
# Chạy từ thư mục apps/billiard_desktop
flutter test

# Chạy riêng 1 test file
flutter test test/models/order_model_test.dart
```

### Manual Verification
1. Build và chạy app trên macOS desktop: `flutter run -d macos`
2. Kiểm tra flow: Login → Shell hiện ra → chuyển tab Navigation
3. Kiểm tra bàn: Bật bàn → timer chạy → tắt bàn → dialog hóa đơn
4. Kiểm tra thống kê: Tab hiển thị dữ liệu mock
5. Kiểm tra offline: tắt mạng → vẫn bật/tắt bàn → bật lại mạng → sync

### Build Check
```bash
flutter build macos --debug
```
