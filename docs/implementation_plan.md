# Kế hoạch tích hợp Xóa dữ liệu local & Tự động cập nhật UI sau Đồng bộ

Kế hoạch này chi tiết việc triển khai chức năng xóa toàn bộ dữ liệu lưu trữ ngoại tuyến (local cache SQLite) và khắc phục lỗi UI không tự động cập nhật dữ liệu bàn chơi, sản phẩm, hóa đơn sau khi quá trình đồng bộ (Synchronization) từ server hoàn tất.

---

## 1. Nội dung cần Người dùng Duyệt (User Review Required)

> [!IMPORTANT]
> - **Xóa dữ liệu local**: Khi người dùng nhấn chọn "Xóa dữ liệu local", chúng ta sẽ thực hiện `DELETE` toàn bộ dữ liệu trong các bảng SQLite (`pending_orders`, `cached_tables`, `cached_products`, `cached_members`, `app_settings`). Phiên đăng nhập (SharedPreferences) vẫn được giữ nguyên để nhân viên có thể tiếp tục thực hiện đồng bộ ngay lập tức mà không phải đăng nhập lại.
> - **Cập nhật UI tự động**: Tận dụng cơ chế lắng nghe của Riverpod (`ref.listen`). Khi `syncStateProvider` chuyển đổi từ trạng thái đang đồng bộ (`isSyncing = true`) sang hoàn tất (`isSyncing = false`), các Provider của Bàn chơi (`tablesProvider`) và Panel Sản phẩm (`AddProductPanel`) sẽ tự động gọi hàm nạp lại dữ liệu để cập nhật UI ngay lập tức.

---

## 2. Các thay đổi đề xuất (Proposed Changes)

### 2.1. Local Database & Sync Service

#### [MODIFY] [local_db_service.dart](file:///Users/hieukona/Downloads/app/billiard_pos/apps/billiard_desktop/lib/core/services/local_db_service.dart)
- Thêm phương thức `clearAllData()` để xóa sạch bản ghi ở mọi bảng trong SQLite:
  ```dart
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('pending_orders');
    await db.delete('cached_tables');
    await db.delete('cached_products');
    await db.delete('cached_members');
    await db.delete('app_settings');
  }
  ```

#### [MODIFY] [sync_service.dart](file:///Users/hieukona/Downloads/app/billiard_pos/apps/billiard_desktop/lib/core/services/sync_service.dart)
- Thêm phương thức `clearAllLocalData()` gọi xuống `LocalDbService.clearAllData()` và cập nhật log tiến trình.

#### [MODIFY] [sync_provider.dart](file:///Users/hieukona/Downloads/app/billiard_pos/apps/billiard_desktop/lib/features/sync/sync_provider.dart)
- Thêm phương thức `clearAllLocalData()` trong `SyncNotifier` để UI gọi và theo dõi tiến trình.

---

### 2.2. Giao diện Đồng bộ dữ liệu (Sync Screen)

#### [MODIFY] [sync_screen.dart](file:///Users/hieukona/Downloads/app/billiard_pos/apps/billiard_desktop/lib/features/sync/sync_screen.dart)
- Cập nhật Widget `_StatusCard` để nhận thêm callback `onClearAllData`.
- Thêm nút bấm **Xóa dữ liệu local** (sử dụng icon `Icons.delete_forever` màu đỏ) kế bên nút giả lập.
- Hiển thị hộp thoại xác nhận `AlertDialog` trước khi tiến hành xóa dữ liệu để tránh thao tác nhầm của cashier.

---

### 2.3. Cập nhật Bàn chơi & Sản phẩm phản ứng với Sync

#### [MODIFY] [tables_provider.dart](file:///Users/hieukona/Downloads/app/billiard_pos/apps/billiard_desktop/lib/features/tables/tables_provider.dart)
- Trong định nghĩa `tablesProvider`, dùng `ref.listen(syncStateProvider, ...)` để tự động gọi `loadTables()` khi tiến trình sync kết thúc.
- Cập nhật `loadTables()` trong `TablesNotifier`: nếu cache SQLite trống (sau khi xóa dữ liệu local), reset các trạng thái trong memory (`tableStartTimes`, `tableOrders`, `tableDiscounts`, `tableMembers`).

#### [MODIFY] [add_product_panel.dart](file:///Users/hieukona/Downloads/app/billiard_pos/apps/billiard_desktop/lib/features/billing/add_product_panel.dart)
- Chuyển `AddProductPanel` thành nạp danh sách sản phẩm động từ SQLite cache bằng cách gọi `LocalDbService.getCachedProducts()`.
- Map dữ liệu từ schema của API (`product_name` -> `name`, `selling_price` -> `price`, `category_name` -> `category`) và bổ sung thuật toán gán Emoji tương ứng dựa trên tên/danh mục sản phẩm.
- Tự động lắng nghe `syncStateProvider` trong hàm `build` để reload lại danh sách sản phẩm khi sync thành công hoặc khi cache bị xóa.
- Tính toán động danh sách bộ lọc danh mục sản phẩm từ dữ liệu thực tế thay vì mảng cứng.

---

## 3. Kế hoạch xác minh & kiểm thử (Verification Plan)

### Kiểm thử tự động (Automated Tests)
- Chạy toàn bộ test suite `flutter test` trong thư mục `apps/billiard_desktop` để đảm bảo không phát sinh lỗi biên dịch và logic mới tương thích hoàn hảo.

### Xác minh thủ công (Manual Verification)
1. **Xác minh Xóa dữ liệu**:
   - Truy cập trang đồng bộ dữ liệu. Nhấn chọn "Xóa dữ liệu local".
   - Kiểm tra xem Dialog xác nhận có hiển thị hay không. Xác nhận xóa.
   - Kiểm tra log console trong trang Sync xem các dòng log "Bắt đầu xóa..." và "Đã xóa dữ liệu SQLite local..." hiển thị đúng không.
   - Quay lại sơ đồ bàn chơi: kiểm tra xem các bàn chơi hoạt động có được giải phóng và nạp dữ liệu sạch/mặc định hay không.
2. **Xác minh Đồng bộ cập nhật UI tự động**:
   - Sau khi xóa dữ liệu local, tiến hành nhấn nút "Sync ngay" khi có kết nối mạng.
   - Đợi quá trình sync hoàn tất.
   - Kiểm tra sơ đồ bàn chơi: UI bàn chơi cập nhật dữ liệu online ngay lập tức mà không cần F5/khởi động lại app.
   - Nhấn mở một bàn chơi bất kỳ, kiểm tra Panel thêm sản phẩm: danh sách sản phẩm được load động đầy đủ từ SQLite vừa sync về từ server kèm theo Emoji tự động và các bộ lọc phân loại chính xác.
