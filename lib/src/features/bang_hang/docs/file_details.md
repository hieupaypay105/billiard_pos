# Feature Bảng Hàng — File Reference

## Directory Structure

```
bang_hang/
├── docs/
│   ├── flow.md              ← Flow diagrams
│   └── file_details.md      ← This file
├── domain/
│   ├── entities/
│   │   └── bang_hang_item.dart
│   └── repositories/
│       └── bang_hang_repository.dart
├── data/
│   ├── datasources/
│   │   └── bang_hang_remote_source.dart
│   ├── models/
│   │   ├── bang_hang_item_model.dart
│   │   └── bang_hang_list_response.dart
│   └── repositories/
│       └── bang_hang_repository_impl.dart
└── presentation/
    ├── provider/
    │   └── bang_hang_provider.dart
    ├── screens/
    │   └── bang_hang_screen.dart
    └── widgets/
        ├── bang_hang_column_settings.dart
        └── bang_hang_filter_sheet.dart
```

---

## Domain Layer

### `bang_hang_item.dart`
**Entity** — Pure Dart class, extends `Equatable`.

| Field | Type | API Key | Mô tả |
|-------|------|---------|-------|
| `id` | `String` | `id` | STT |
| `area` | `String` | `area` | Phân khu / Block |
| `code` | `String` | `code` | Mã căn |
| `type` | `String` | `type` | Loại hình (Liền kề, Song lập...) |
| `handoverStatus` | `String` | `handover_status` | Tiêu chuẩn bàn giao |
| `direction` | `String` | `direction` | Hướng nhà |
| `landSize` | `String?` | `land_size` | Kích thước đất |
| `acreage` | `String` | `acreage` | Diện tích đất |
| `constructionArea` | `String` | `construction_area` | Diện tích xây dựng |
| `price` | `String` | `price` | Giá full |
| `tts` | `String` | `tts` | Thanh toán sớm |
| `proceduresSign` | `String` | `procedures_sign` | Thủ tục ký |
| `investmentFund` | `String?` | `investment_fund` | Quỹ đầu tư |
| `bankBasket` | `String` | `bank_basket` | Giỏ bank F1 |
| `status` | `String` | `status` | Trạng thái |
| `agent` | `String` | `agent` | Đại lý |
| `loan` | `String` | `loan` | Vay |
| `note` | `String?` | `note` | Ghi chú |
| `contractPrice` | `String?` | `contract_price` | Giá hợp đồng |
| `fee` | `String?` | `fee` | Phí |
| `unitPrice` | `String?` | `unit_price` | Đơn giá |
| `telesale` | `String?` | `telesale` | Telesale |

### `bang_hang_repository.dart`
**Abstract repository** — Hợp đồng giữa domain và data:

```dart
abstract class BangHangRepository {
  Future<BangHangListResponse> getItems({required BangHangFilter filter});
}
```

---

## Data Layer

### `bang_hang_remote_source.dart`
**Remote Data Source** — Gọi API qua Dio.

- **Endpoint**: `PUT /data/list`
- **Body**: JSON chứa filter params (project_id, area, type, direction, handover_status, price range, tts range, acreage range, page, per_page)
- **Response parsing**: Kiểm tra `status == 0` → throw, parse `data` → `BangHangListResponse`

> Khác với CTV: dùng PUT + body thay vì GET + query params.

### `bang_hang_item_model.dart`
**Data Model** — Extends `BangHangItem`, thêm `fromJson()` / `toJson()`.

### `bang_hang_list_response.dart`
**Response wrapper** — Chứa `items` + `pagination`.

Điểm đặc biệt: API trả items dạng **nested array**:
```json
"items": [ [item1], [item2], [item3] ]
```

Code phải **flatten** trước khi parse:
```dart
for (final group in rawItems) {
  if (group is List) {
    for (final item in group) { ... }
  } else if (group is Map) { ... }
}
```

**BangHangPagination**: `total`, `perPage`, `currentPage`, `lastPage` — có `_parseInt()` helper vì API trả mixed int/String.

### `bang_hang_repository_impl.dart`
**Repository implementation** — Delegate `getItems(filter)` xuống data source.

---

## Presentation Layer

### `bang_hang_provider.dart`
**State management** — `ChangeNotifier` pattern.

**Tabs (4 dự án):**

| Index | ID | Label | projectId |
|-------|----|-------|-----------|
| 0 | `quy_moi_vin_2` | Quỹ mới Vin 2 | 2 |
| 1 | `quy_moi_vin_3` | Quỹ mới Vin 3 | 3 |
| 2 | `chuyen_nhuong_vin_2` | Chuyển nhượng Vin 2 | 18 |
| 3 | `chuyen_nhuong_vin_3` | Chuyển nhượng Vin 3 | 19 |

**State:**
- `_allItems`, `_isLoading`, `_errorMessage`
- `_selectedTabIndex` (default: 0)
- Pagination: `_currentPage`, `_lastPage`, `_total`, `_perPage` (default: 20)
- Sort: `_sortColumnKey`, `_sortAscending`
- Filter: `_filter` (type `BangHangFilter`)
- Column visibility: `_visibleColumns` (16 cột)

**Methods:**

| Method | Mô tả |
|--------|-------|
| `loadItems(page)` | Gọi API với filter + pagination |
| `setTab(index)` | Chuyển tab, reset page, gọi API |
| `applyFilter(filter)` | Set filter, reset page = 1, gọi API |
| `clearFilter()` | Reset filter về default, gọi API |
| `goToPage(page)` | Navigate page cụ thể |
| `nextPage()` / `previousPage()` | Chuyển trang |
| `sort(key, ascending)` | Client-side sort (chuẩn hóa số) |
| `toggleColumn(key)` | Ẩn/hiện 1 cột |
| `toggleAllColumns(bool)` | Ẩn/hiện tất cả |

**`BangHangFilter`:**

| Field | Type | Body Key | Default |
|-------|------|----------|---------|
| `projectId` | `int` | `project_id` | `2` |
| `area` | `List<String>` | `area` | `[]` |
| `type` | `List<String>` | `type` | `[]` |
| `telesale` | `List<String>` | `telesale` | `[]` |
| `direction` | `List<String>` | `direction` | `[]` |
| `handoverStatus` | `List<String>` | `handover_status` | `[]` |
| `price` | `RangeFilter` | `price` | empty |
| `tts` | `RangeFilter` | `tts` | empty |
| `acreage` | `RangeFilter` | `acreage` | empty |
| `page` | `int` | `page` | `1` |
| `perPage` | `int` | `per_page` | `20` |

**`RangeFilter`:**
- `min` / `max` (nullable double)
- `isEmpty` → không gửi key trong body nếu rỗng
- `toJson()` → `{ "min": int, "max": int }`

### `bang_hang_screen.dart`
**Main screen** — Scaffold với gradient background.

**Components:**
- `AnFeatureAppBar` — Back, filter, add, search buttons
- Tab bar — 4 tab dự án dạng horizontal scroll
- `AnDataTable<BangHangItem>` — Data table 16 cột
- `_PaginationBar` — Prev/next, trang hiện tại / tổng trang, tổng kết quả

**16 cột hiển thị:**

| Key | Label | Width | Type |
|-----|-------|-------|------|
| `id` | STT | 70px | text |
| `area` | Phân khu | 150px | filterable, custom cell (blue badge) |
| `code` | Mã căn | 100px | text |
| `type` | Loại hình | 125px | filterable |
| `handoverStatus` | TCBG | 90px | filterable |
| `direction` | Hướng | 100px | filterable |
| `landSize` | KT đất | 100px | sortable |
| `acreage` | DT đất | 100px | sortable |
| `constructionArea` | DTXD | 100px | sortable |
| `price` | Giá full | 140px | sortable |
| `tts` | TTS | 80px | text |
| `proceduresSign` | Thủ tục ký | 120px | text |
| `investmentFund` | Quỹ ĐT | 130px | text |
| `bankBasket` | Giỏ bank F1 | 130px | text |
| `agent` | Đại lý | 130px | text |
| `loan` | Vay | 100px | sortable |

### `bang_hang_filter_sheet.dart`
**Filter dialog** — 7 tiêu chí lọc:

| Tiêu chí | Widget | Options |
|-----------|--------|---------|
| Phân khu | Multi-select chips | Đảo Dừa, San Hô, Ánh Dương, Hoa Sữa |
| Loại hình | Multi-select chips | Liền kề, Song lập, Đơn lập, Shophouse |
| Hướng | Multi-select chips | 8 hướng (ĐN, ĐB, TN, TB, B, N, Đ, T) |
| TCBG | Multi-select chips | Thô, Hoàn thiện, TKT |
| Giá Full | Range input (min-max) | Số tự do |
| Giá TTS | Range input (min-max) | Số tự do |
| Diện tích | Range input (min-max) | Số tự do |

### `bang_hang_column_settings.dart`
**Column toggle dialog** — Checkbox list cho ẩn/hiện từng cột trong 16 cột.

---

## DI Registration

Trong `injection_container.dart`:

```dart
// Data Source
..registerLazySingleton<BangHangRemoteDataSource>(
  () => BangHangRemoteDataSourceImpl(dio: sl()),
)
// Repository
..registerLazySingleton<BangHangRepository>(
  () => BangHangRepositoryImpl(dataSource: sl()),
)
// Provider
..registerFactory(() => BangHangProvider(repository: sl()))
```

---

## API Reference

### PUT `/data/list`

**Request Body:**
```json
{
  "project_id": 2,
  "area": ["Đảo Dừa"],
  "type": ["LIỀN KỀ"],
  "telesale": [],
  "direction": [],
  "handover_status": [],
  "price": { "min": 5000, "max": 10000 },
  "tts": { "min": 100 },
  "acreage": {},
  "page": "1",
  "per_page": "20"
}
```

**Response:**
```json
{
  "status": 1,
  "errors": [],
  "message": "OK",
  "data": {
    "items": [ [{ "id", "area", "code", ... }], [{ ... }] ],
    "pagination": { "total", "per_page", "current_page", "last_page" }
  }
}
```

> Lưu ý: `items` là **nested array** — mỗi phần tử trong items là 1 array chứa 1 item.
