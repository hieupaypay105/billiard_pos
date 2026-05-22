# Tasks

- `[x]` Thêm phương thức `clearAllData()` vào `LocalDbService` in `local_db_service.dart`
- `[x]` Thêm phương thức `clearAllLocalData()` vào `SyncService` in `sync_service.dart`
- `[x]` Cập nhật `SyncNotifier` in `sync_provider.dart` để hỗ trợ `clearAllLocalData()`
- `[x]` Cập nhật `tablesProvider` và `TablesNotifier` in `tables_provider.dart` để tự động reload bàn khi sync hoàn tất hoặc cache bị xóa
- `[x]` Refactor `AddProductPanel` in `add_product_panel.dart` để nạp dữ liệu sản phẩm động từ SQLite cache, map fields và tự động lắng nghe sự kiện đồng bộ
- `[x]` Thêm nút bấm "Xóa dữ liệu local" và AlertDialog xác nhận vào `SyncScreen` in `sync_screen.dart`
- `[x]` Chạy kiểm thử tự động `flutter test` để xác minh không phát sinh lỗi biên dịch và logic mới chạy đúng
