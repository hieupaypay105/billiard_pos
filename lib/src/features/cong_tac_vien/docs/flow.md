# Feature Cộng Tác Viên — Flow Documentation

## Giới thiệu

Feature **Cộng Tác Viên** (CTV) quản lý danh sách cộng tác viên bán hàng. Người dùng có thể:

- Xem danh sách CTV dạng bảng
- Lọc CTV theo trạng thái (Hoạt động / Không hoạt động)
- Phân trang để xem nhiều trang dữ liệu
- Sắp xếp theo từng cột
- Ẩn / hiện cột tùy ý

Dữ liệu được lấy từ API **`GET /partner/list`** (server-side filtering + pagination).

---

## Cấu trúc tổng quan

Feature được chia thành 3 tầng theo Clean Architecture:

```
┌─────────────────────────────────────────────────┐
│               PRESENTATION LAYER                │
│                                                 │
│   Screen ←→ Provider ←→ FilterSheet             │
│                ↑          ColumnSettings         │
│                │          AddSheet               │
│                │          PaginationBar          │
├────────────────┼────────────────────────────────┤
│               DOMAIN LAYER                      │
│                │                                │
│   Repository (abstract)    Entity (CongTacVienItem)  │
├────────────────┼────────────────────────────────┤
│               DATA LAYER                        │
│                │                                │
│   RepositoryImpl → RemoteDataSource → Dio → API │
│                     ListResponse                │
│                     ItemModel                   │
└─────────────────────────────────────────────────┘
```

**Quy tắc phụ thuộc:** Tầng trên chỉ phụ thuộc tầng dưới, không bao giờ ngược lại.

- Screen chỉ biết Provider
- Provider chỉ biết Repository (abstract)
- RepositoryImpl biết DataSource
- DataSource biết Dio và API

---

## Flow 1: Mở màn hình — Lấy danh sách CTV

Đây là flow chính xảy ra khi người dùng navigate đến màn hình Cộng Tác Viên.

```
Người dùng mở màn hình CTV
        │
        ▼
┌── CongTacVienScreen ──┐
│   Được build với       │
│   Consumer<Provider>   │
│   Provider được tạo    │
│   bởi GetIt (DI)       │
└───────┬───────────────┘
        │ Constructor chạy
        ▼
┌── CongTacVienProvider ─┐
│   1. Set isLoading=true │
│   2. notifyListeners()  │──→ Screen hiện ⏳ Loading spinner
│   3. Gọi repository     │
└───────┬────────────────┘
        │ getItems(filter)
        ▼
┌── Repository ──────────┐
│   Delegate xuống       │
│   DataSource           │
└───────┬────────────────┘
        │ getItems(filter)
        ▼
┌── RemoteDataSource ────┐
│   Dùng Dio gửi request │
│                        │
│   GET /partner/list    │
│   ?page=1              │
│   &per_page=10         │
└───────┬────────────────┘
        │ HTTP Response
        ▼
┌── Parse Response ──────┐
│   1. Kiểm tra status=1 │
│   2. Lấy data.items    │
│   3. Lấy data.pagination│
│   4. Parse thành        │
│      ListResponse       │
└───────┬────────────────┘
        │ Trả về Provider
        ▼
┌── Provider nhận data ──┐
│   1. Lưu items vào state│
│   2. Lưu pagination     │
│      (total, lastPage)  │
│   3. Set isLoading=false │
│   4. notifyListeners()  │──→ Screen rebuild với data
└────────────────────────┘
        │
        ▼
   Người dùng thấy bảng dữ liệu
   + thanh phân trang bên dưới
```

---

## Flow 2: Lọc theo trạng thái (Filter)

Filtering diễn ra ở phía server — API nhận param `status` và trả về data đã lọc sẵn.

```
Người dùng nhấn icon 🔍 trên AppBar
        │
        ▼
   Mở FilterSheet (dialog)
   Dropdown "Tình trạng" có 3 lựa chọn:
   ┌─────────────────────────┐
   │  • Tất cả    (status=null) │ → Không gửi param status
   │  • Hoạt động  (status=1)   │ → Gửi status=1
   │  • Không HĐ   (status=0)  │ → Gửi status=0
   └─────────────────────────┘
        │ Chọn "Hoạt động" → nhấn "Xong"
        ▼
   FilterSheet gọi Provider.applyFilter(status: 1)
        │
        ▼
┌── Provider ────────────┐
│   1. Lưu filter mới    │
│   2. Reset page = 1    │    ← Luôn về trang 1 khi đổi filter
│   3. Gọi loadItems()   │
└───────┬────────────────┘
        │
        ▼
   API: GET /partner/list?status=1&page=1&per_page=10
        │
        ▼
   Server trả về chỉ CTV có status=1 (Hoạt động)
        │
        ▼
   Bảng cập nhật → chỉ hiện CTV "Kích hoạt"
```

---

## Flow 3: Phân trang (Pagination)

API trả về pagination info: `total=81, per_page=10, current_page=1, last_page=9`

Thanh phân trang ở dưới bảng hiển thị: **Tổng: 81  ◀  1 / 9  ▶**

```
Đang ở trang 1 / 9
        │
        ▼ Nhấn nút ▶ (Next)
┌── PaginationBar ───────┐
│   Gọi Provider.nextPage()│
└───────┬────────────────┘
        │
        ▼
┌── Provider ────────────┐
│   1. Kiểm tra hasNextPage │
│      (currentPage < lastPage) │
│   2. Nếu có → goToPage(2)│
│   3. Gọi loadItems(page: 2)│
└───────┬────────────────┘
        │
        ▼
   API: GET /partner/list?page=2&per_page=10
        │
        ▼
   Bảng hiện 10 records tiếp theo
   Thanh pagination: Tổng: 81  ◀  2 / 9  ▶


Quy tắc nút bấm:
┌─────────────────────────────────────┐
│ Trang 1     → Nút ◀ bị disable     │
│ Trang cuối  → Nút ▶ bị disable     │
│ Trang giữa  → Cả 2 nút active      │
│ Đổi filter  → Reset về trang 1      │
└─────────────────────────────────────┘
```

---

## Flow 4: Sắp xếp (Sort)

Sort diễn ra ở **client-side** — chỉ sort data đang có trên trang hiện tại, không gọi API.

```
Người dùng nhấn vào header cột "Họ và tên"
        │
        ▼
┌── AnDataTable ─────────┐
│   Gọi Provider.sort(   │
│     'fullname',         │
│     ascending: true     │
│   )                     │
└───────┬────────────────┘
        │
        ▼
┌── Provider ────────────┐
│   1. Lưu sortColumnKey  │
│      = 'fullname'       │
│   2. Lưu sortAscending  │
│      = true             │
│   3. notifyListeners()  │
└───────┬────────────────┘
        │
        ▼
   Getter `items` được gọi lại:
   1. Copy _allItems
   2. _applySort() so sánh string
   3. Trả list đã sort
        │
        ▼
   Bảng hiển thị A→Z theo "Họ và tên"
   Nhấn lại → đổi sang Z→A


Các cột hỗ trợ sort:
┌───────────────────────────┐
│ fullname   — Họ và tên    │
│ email      — Email        │
│ mobile     — Điện thoại   │
│ statusLabel— Tình trạng   │
│ createdAt  — Ngày tạo     │
│ parentId   — Sale QL      │
└───────────────────────────┘
```

---

## Flow 5: Xử lý lỗi

Khi API gặp vấn đề, flow xử lý như sau:

```
Gọi API /partner/list
        │
        ├── Response OK (status=1)
        │       → Parse data bình thường
        │       → Hiển thị bảng
        │
        ├── Response lỗi logic (status=0)
        │       → Lấy message từ response
        │       → VD: "Không có quyền truy cập"
        │       → Provider lưu vào _errorMessage
        │       → Screen hiện text đỏ
        │
        ├── Lỗi mạng (DioException)
        │       → Timeout, mất kết nối...
        │       → Lấy message từ exception
        │       → Provider lưu vào _errorMessage
        │       → Screen hiện text đỏ
        │
        └── Response null / invalid
                → Throw "Invalid response"
                → Provider lưu vào _errorMessage
                → Screen hiện text đỏ
```

---

## Tóm tắt data flow

```
User Action → Screen → Provider → Repository → DataSource → API
                                                              │
API Response → DataSource (parse) → Repository → Provider → Screen → User sees data
```

Mọi thao tác của user (filter, pagination, refresh) đều đi theo cùng 1 flow:
1. Provider set loading = true
2. Provider tạo filter params
3. Gọi API qua Repository → DataSource
4. Parse response
5. Cập nhật state
6. Set loading = false
7. Screen tự rebuild nhờ notifyListeners()
