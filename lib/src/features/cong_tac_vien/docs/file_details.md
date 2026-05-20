# Cộng Tác Viên — File Reference

## Directory Structure

```
cong_tac_vien/
├── docs/
│   ├── flow.md              ← Flow diagrams
│   └── file_details.md      ← This file
├── domain/
│   ├── entities/
│   │   └── cong_tac_vien_item.dart
│   └── repositories/
│       └── cong_tac_vien_repository.dart
├── data/
│   ├── datasources/
│   │   └── cong_tac_vien_remote_source.dart
│   ├── models/
│   │   ├── cong_tac_vien_item_model.dart
│   │   └── cong_tac_vien_list_response.dart
│   └── repositories/
│       └── cong_tac_vien_repository_impl.dart
└── presentation/
    ├── provider/
    │   └── cong_tac_vien_provider.dart
    ├── screens/
    │   └── cong_tac_vien_screen.dart
    └── widgets/
        ├── cong_tac_vien_add_sheet.dart
        ├── cong_tac_vien_column_settings.dart
        └── cong_tac_vien_filter_sheet.dart
```

---

## Domain Layer

### `cong_tac_vien_item.dart`
**Entity** — Pure Dart class, extends `Equatable`.

| Field | Type | API Key | Mô tả |
|-------|------|---------|-------|
| `id` | `String` | `id` | ID cộng tác viên |
| `parentId` | `String` | `parent_id` | ID sale quản lý |
| `code` | `String` | `code` | Mã bảo mật / mã đăng nhập |
| `fullname` | `String` | `fullname` | Họ và tên |
| `email` | `String` | `email` | Email |
| `status` | `String` | `status` | Trạng thái: `"0"` / `"1"` |
| `mobile` | `String` | `mobile` | Số điện thoại |
| `basePath` | `String?` | `base_path` | Base path ảnh |
| `imageFile` | `String?` | `image_file` | File ảnh đại diện |
| `dob` | `String?` | `dob` | Ngày sinh |
| `createdAt` | `String` | `created_at` | Ngày tạo |
| `updatedAt` | `String?` | `updated_at` | Ngày cập nhật |
| `statusLabel` | `String` | `status_label` | Label hiển thị trạng thái |

### `cong_tac_vien_repository.dart`
**Abstract repository** — Defines contract:

```dart
abstract class CongTacVienRepository {
  Future<CongTacVienListResponse> getItems({required CongTacVienFilter filter});
}
```

---

## Data Layer

### `cong_tac_vien_remote_source.dart`
**Remote Data Source** — Gọi API qua Dio.

- **Endpoint**: `GET /partner/list`
- **Query params**: `status`, `sale_id`, `page`, `per_page`
- **Response parsing**: Kiểm tra `status == 0` → throw exception, parse `data` → `CongTacVienListResponse`
- **Error handling**: Catch `DioException`, extract message từ response body

### `cong_tac_vien_item_model.dart`
**Data Model** — Extends `CongTacVienItem`, thêm `fromJson()` / `toJson()`.

- `fromJson`: Parse API JSON keys (`parent_id`, `created_at`, `status_label`...)
- Dùng `?.toString() ?? ''` để xử lý null safety

### `cong_tac_vien_list_response.dart`
**Response wrapper** — Chứa:

- `List<CongTacVienItemModel> items` — Danh sách CTV
- `CongTacVienPagination pagination` — `total`, `perPage`, `currentPage`, `lastPage`
- `_parseInt()` helper xử lý API trả int hoặc String

### `cong_tac_vien_repository_impl.dart`
**Repository implementation** — Delegate `getItems(filter)` xuống data source.

---

## Presentation Layer

### `cong_tac_vien_provider.dart`
**State management** — `ChangeNotifier` pattern.

**State:**
- `_allItems`, `_isLoading`, `_errorMessage`
- Pagination: `_currentPage`, `_lastPage`, `_total`, `_perPage`
- Sort: `_sortColumnKey`, `_sortAscending`
- Filter: `_filter` (type `CongTacVienFilter`)
- Column visibility: `_visibleColumns` map

**Methods:**
| Method | Mô tả |
|--------|-------|
| `loadItems(page)` | Gọi API với filter + pagination |
| `applyFilter(filter)` | Set filter, reset page = 1, gọi API |
| `clearFilter()` | Reset filter về default, gọi API |
| `goToPage(page)` | Navigate đến trang cụ thể |
| `nextPage()` / `previousPage()` | Chuyển trang |
| `sort(key, ascending)` | Client-side sort |
| `toggleColumn(key)` / `toggleAllColumns(bool)` | Ẩn/hiện cột |

**`CongTacVienFilter`:**
| Field | Type | Query Param | Default |
|-------|------|-------------|---------|
| `status` | `int?` | `status` | `null` (tất cả) |
| `saleId` | `String?` | `sale_id` | `null` |
| `page` | `int` | `page` | `1` |
| `perPage` | `int` | `per_page` | `10` |

### `cong_tac_vien_screen.dart`
**Main screen** — Scaffold với gradient background.

**Components:**
- `AnFeatureAppBar` — Back, filter, add, search buttons
- `AnDataTable<CongTacVienItem>` — Data table với columns
- `_PaginationBar` — Hiển thị tổng, prev/next buttons, trang hiện tại

**Columns hiển thị:**
| Key | Label | Width | Note |
|-----|-------|-------|------|
| `id` | STT | 60px | |
| `parentId` | Sale QL | 120px | Filterable |
| `email` | Email | 180px | |
| `fullname` | Họ và tên | 120px | |
| `statusLabel` | Tình trạng | 130px | Custom cell: xanh = active, đỏ = inactive |
| `mobile` | Điện thoại | 120px | |
| `createdAt` | Ngày tạo | 150px | |
| `code` | Mã bảo mật | 130px | |

### `cong_tac_vien_filter_sheet.dart`
**Filter bottom sheet** — Dropdown "Tình trạng" với 3 options:
- `null` → Tất cả
- `1` → Hoạt động
- `0` → Không hoạt động

### `cong_tac_vien_column_settings.dart`
**Column toggle dialog** — Checkbox list cho ẩn/hiện từng cột.

### `cong_tac_vien_add_sheet.dart`
**Add CTV dialog** — Form thêm CTV mới (chưa kết nối API).

---

## DI Registration

Trong `injection_container.dart`:

```dart
// Data Source
..registerLazySingleton<CongTacVienRemoteDataSource>(
  () => CongTacVienRemoteDataSourceImpl(dio: sl()),
)
// Repository
..registerLazySingleton<CongTacVienRepository>(
  () => CongTacVienRepositoryImpl(dataSource: sl()),
)
// Provider
..registerFactory(() => CongTacVienProvider(repository: sl()))
```

---

## API Reference

### GET `/partner/list`

**Query Params:**

| Param | Type | Description |
|-------|------|-------------|
| `status` | `int` | `0` = Không hoạt động, `1` = Hoạt động |
| `sale_id` | `string` | ID sale quản lý (e.g. `CDT`) |
| `page` | `int` | Trang hiện tại |
| `per_page` | `int` | Số records / trang |

**Response:**
```json
{
  "status": 1,
  "errors": [],
  "message": "OK",
  "data": {
    "items": [{ "id", "parent_id", "code", "fullname", "email", "status", "mobile", ... }],
    "pagination": { "total", "per_page", "current_page", "last_page" }
  }
}
```
