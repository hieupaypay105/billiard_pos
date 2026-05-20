# Feature Bảng Hàng — Flow Documentation

## Giới thiệu

Feature **Bảng Hàng** hiển thị danh sách bất động sản (căn hộ, biệt thự...) theo từng dự án.
Người dùng có thể:

- Chuyển giữa các tab dự án (Quỹ mới Vin 2, Vin 3, Chuyển nhượng Vin 2, Vin 3)
- Lọc theo nhiều tiêu chí: phân khu, loại hình, hướng, TCBG, khoảng giá, diện tích
- Phân trang để xem nhiều trang dữ liệu
- Sắp xếp theo cột số (giá, diện tích, vay...)
- Ẩn / hiện cột tùy ý

Dữ liệu được lấy từ API **`PUT /data/list`** (server-side filtering + pagination).

> Lưu ý: API dùng method **PUT** (không phải GET), gửi filter trong body.

---

## Cấu trúc tổng quan

```
┌─────────────────────────────────────────────────┐
│               PRESENTATION LAYER                │
│                                                 │
│   Screen ←→ Provider ←→ FilterSheet             │
│     ↑          ↑          ColumnSettings         │
│     │          │                                │
│   Tabs      PaginationBar                       │
├────────────────┼────────────────────────────────┤
│               DOMAIN LAYER                      │
│                │                                │
│   Repository (abstract)    Entity (BangHangItem) │
├────────────────┼────────────────────────────────┤
│               DATA LAYER                        │
│                │                                │
│   RepositoryImpl → RemoteDataSource → Dio → API │
│                     ListResponse                │
│                     ItemModel                   │
└─────────────────────────────────────────────────┘
```

---

## Flow 1: Mở màn hình — Lấy danh sách bảng hàng

```
Người dùng mở màn hình Bảng Hàng
        │
        ▼
┌── BangHangScreen ──────┐
│   Consumer<Provider>   │
│   Provider được tạo    │
│   bởi GetIt (DI)       │
└───────┬────────────────┘
        │ Constructor chạy
        ▼
┌── BangHangProvider ────┐
│   1. Tab mặc định = 0  │   (Quỹ mới Vin 2, projectId = 2)
│   2. Set isLoading=true │
│   3. notifyListeners() │──→ Screen hiện loading spinner
│   4. Gọi repository    │
└───────┬────────────────┘
        │ getItems(filter)
        ▼
┌── RemoteDataSource ────┐
│   Dùng Dio gửi request │
│                        │
│   PUT /data/list       │
│   Body:                │
│   {                    │
│     "project_id": 2,   │
│     "area": [],        │
│     "type": [],        │
│     "direction": [],   │
│     "handover_status":[]│
│     "page": "1",       │
│     "per_page": "20"   │
│   }                    │
└───────┬────────────────┘
        │ HTTP Response
        ▼
┌── Parse Response ──────┐
│   1. Kiểm tra status=1 │
│   2. Lấy data.items    │
│      (nested array:    │
│       items=[[item1],  │
│              [item2]]) │
│   3. Flatten thành     │
│      list đơn          │
│   4. Parse pagination  │
└───────┬────────────────┘
        │ Trả về Provider
        ▼
┌── Provider nhận data ──┐
│   1. Lưu items vào state│
│   2. Lưu pagination     │
│   3. Set isLoading=false │
│   4. notifyListeners() │──→ Screen rebuild
└────────────────────────┘
        │
        ▼
   Người dùng thấy bảng 16 cột dữ liệu
   + tabs dự án ở trên
   + thanh phân trang bên dưới


Lưu ý quan trọng:
┌──────────────────────────────────────────────────┐
│ API trả items dạng NESTED ARRAY: [[item], [item]]│
│ Code phải flatten thành [item, item] trước khi   │
│ parse từng item. Xem BangHangListResponse.       │
└──────────────────────────────────────────────────┘
```

---

## Flow 2: Chuyển tab dự án

Feature có 4 tab, mỗi tab tương ứng 1 project_id khác nhau:

```
┌──────────────────────────────────────────────┐
│ Tab 0: Quỹ mới Vin 2      → projectId = 2   │
│ Tab 1: Quỹ mới Vin 3      → projectId = 3   │
│ Tab 2: Chuyển nhượng Vin 2 → projectId = 18  │
│ Tab 3: Chuyển nhượng Vin 3 → projectId = 19  │
└──────────────────────────────────────────────┘

Người dùng nhấn tab "Quỹ mới Vin 3"
        │
        ▼
┌── Provider.setTab(1) ──┐
│   1. _selectedTabIndex=1│
│   2. Reset page = 1    │
│   3. Gọi loadItems()   │
└───────┬────────────────┘
        │
        ▼
   API: PUT /data/list
   Body: { "project_id": 3, "page": "1", ... }
        │
        ▼
   Bảng hiển thị data của dự án Vin 3
   Tab "Quỹ mới Vin 3" được highlight
```

Tabs trong `BangHang` cũng là parent selector cho filter options:

- `projectId` không được chọn trong filter sheet.
- Filter sheet luôn dùng `projectId` của tab hiện tại.
- Khi tab đổi, toàn bộ filter con phụ thuộc project phải được xem là stale:
  - `area`
  - `type`
  - `direction`
  - `handover_status`
- Provider phải clear option cache trước khi tải option của project mới để UI không hiển thị nhầm dữ liệu từ project cũ.

---

## Flow 3: Lọc dữ liệu (Filter)

Filtering diễn ra ở phía **server** — toàn bộ filter params được gửi trong body của PUT request.

Flow này tuân theo pattern `project_dependent_filter_flow.md`:

- Parent source: tab hiện tại (`selectedProjectId` trong provider)
- Child filters: `area`, `type`, `direction`, `handover_status`
- Nếu mở filter sheet với `initialFilter.projectId` khác tab hiện tại:
  - giữ các field không phụ thuộc project như `code`, `price`, `tts`, `acreage`
  - reset các child filters phụ thuộc project trước khi render
- Khi option đang tải, các dropdown phụ thuộc project phải bị disable và hiển thị loading state

Filter sheet có 7 tiêu chí lọc:

```
Người dùng nhấn icon 🔍 → Mở FilterSheet
        │
        ▼
┌── FilterSheet ──────────────────────────────────┐
│                                                 │
│  1. Phân khu (multi-select chips):              │
│     [ Đảo Dừa ] [ San Hô ] [ Ánh Dương ] ...   │
│                                                 │
│  2. Loại hình (multi-select chips):             │
│     [ LIỀN KỀ ] [ SONG LẬP ] [ ĐƠN LẬP ] ...  │
│                                                 │
│  3. Hướng (multi-select chips):                 │
│     [ Đông Nam ] [ Tây Bắc ] [ Bắc ] ...       │
│                                                 │
│  4. Tiêu chuẩn bàn giao (multi-select chips):  │
│     [ THÔ ] [ HOÀN THIỆN ] [ TKT ]             │
│                                                 │
│  5. Khoảng giá Full: [ Từ _____ ] — [ Đến ___ ]│
│  6. Khoảng giá TTS:  [ Từ _____ ] — [ Đến ___ ]│
│  7. Khoảng diện tích: [ Từ ____ ] — [ Đến ___ ]│
│                                                 │
│                  [ Xong ]                       │
└────────────────────┬────────────────────────────┘
                     │ Nhấn "Xong"
                     ▼
   Provider.applyFilter(BangHangFilter(...))
        │
        ▼
┌── Provider ────────────┐
│   1. Lưu filter mới    │
│   2. Reset page = 1    │    ← Luôn về trang 1 khi đổi filter
│   3. Gọi loadItems()   │
└───────┬────────────────┘
        │
        ▼
   API: PUT /data/list
   Body: {
     "project_id": 2,
     "area": ["Đảo Dừa", "San Hô"],
     "type": ["LIỀN KỀ"],
     "direction": [],
     "handover_status": [],
     "price": { "min": 5000, "max": 10000 },
     "page": "1",
     "per_page": "20"
   }
        │
        ▼
   Bảng cập nhật với data đã lọc


Lưu ý:
┌──────────────────────────────────────────────────┐
│ - Multi-select: chọn nhiều giá trị cùng lúc      │
│ - RangeFilter: có thể nhập chỉ min, chỉ max,    │
│   hoặc cả hai                                    │
│ - Nếu RangeFilter rỗng → không gửi trong body   │
│ - projectId luôn được giữ nguyên từ tab hiện tại │
└──────────────────────────────────────────────────┘
```

---

## Flow 4: Phân trang (Pagination)

Hiển thị bên dưới bảng: **◀  Trang 1 / 5  (100 kết quả)  ▶**

```
Đang ở trang 1 / 5
        │
        ▼ Nhấn nút ▶ (Next)
┌── Provider ────────────┐
│   1. nextPage()         │
│   2. Kiểm tra hasNextPage│
│   3. goToPage(2)        │
│   4. loadItems(page: 2) │
└───────┬────────────────┘
        │
        ▼
   API: PUT /data/list
   Body: { ..., "page": "2", "per_page": "20" }
        │
        ▼
   Bảng hiện 20 records tiếp theo
   Thanh: ◀  Trang 2 / 5  (100 kết quả)  ▶


Quy tắc:
┌─────────────────────────────────────┐
│ Trang 1     → Nút ◀ bị disable     │
│ Trang cuối  → Nút ▶ bị disable     │
│ Đổi tab     → Reset về trang 1      │
│ Đổi filter  → Reset về trang 1      │
│ Per page    → Mặc định 20 records   │
└─────────────────────────────────────┘
```

---

## Flow 5: Sắp xếp (Sort)

Sort là **client-side** — chỉ sort data đang có trên trang hiện tại, không gọi API.
Chỉ các cột **số** mới hỗ trợ sort.

```
Người dùng nhấn header cột "Giá full"
        │
        ▼
   Provider.sort('price', ascending: true)
        │
        ▼
   _applySort() chạy:
   1. Lấy giá trị cột price từ mỗi item
   2. Chuẩn hóa: bỏ dấu chấm ngàn, đổi dấu phẩy thành dấu chấm
      VD: "5.200.000" → 5200000.0
   3. So sánh số và sort
        │
        ▼
   Bảng hiển thị giá từ thấp → cao
   Nhấn lại → đổi sang cao → thấp


Các cột hỗ trợ sort:
┌───────────────────────────┐
│ acreage          — DT đất │
│ constructionArea — DTXD   │
│ price            — Giá full│
│ tts              — TTS    │
│ loan             — Vay    │
└───────────────────────────┘

Cách chuẩn hóa số:
┌─────────────────────────────────────────────┐
│ "5.200.000"  → bỏ dấu .  → "5200000"       │
│ "5200000"    → parse      → 5200000.0       │
│ "1,5"        → đổi , → . → "1.5" → 1.5     │
│ ""           → fallback   → 0.0             │
└─────────────────────────────────────────────┘
```

---

## Flow 6: Xử lý lỗi

```
Gọi API PUT /data/list
        │
        ├── Response OK (status=1)
        │       → Parse data bình thường
        │       → Hiển thị bảng
        │
        ├── Response lỗi logic (status=0)
        │       → Lấy message từ response
        │       → Provider lưu vào _errorMessage
        │       → Screen hiện text đỏ
        │
        ├── Lỗi mạng (DioException)
        │       → Timeout, mất kết nối...
        │       → Lấy message từ response body nếu có
        │       → Nếu không có → dùng e.message
        │       → Screen hiện text đỏ
        │
        └── Response null
                → Throw "Invalid response from server"
                → Screen hiện text đỏ
```

---

## So sánh với Feature Cộng Tác Viên

| Đặc điểm | Bảng Hàng | Cộng Tác Viên |
|-----------|-----------|---------------|
| API method | **PUT** (body) | **GET** (query params) |
| Endpoint | `/data/list` | `/partner/list` |
| Tabs | Có (4 tabs theo dự án) | Không |
| Filter | Multi-select + Range | Dropdown đơn (status) |
| Items format | Nested array `[[item]]` | Flat array `[item]` |
| Sort cột số | Chuẩn hóa dấu chấm/phẩy | Sort string đơn giản |
| Per page | 20 | 10 |

---

## Tóm tắt data flow

```
User Action → Screen → Provider → Repository → DataSource → API (PUT)
                                                              │
API Response → DataSource (parse nested array) → Provider → Screen → User
```

Mọi thao tác (chọn tab, filter, phân trang) đều đi theo cùng 1 flow:
1. Provider set loading = true
2. Tạo BangHangFilter với projectId + filter params + page
3. Gọi API qua Repository → DataSource
4. Parse response (flatten nested items array)
5. Cập nhật state (items, pagination)
6. Set loading = false → Screen rebuild
