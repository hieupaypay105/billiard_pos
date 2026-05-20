# Feature: Trợ lý AI (AI Assistant)

## 1. Tổng quan (Overview)
Tính năng **Trợ lý AI** là một Module độc lập tuân thủ chuẩn Clean Architecture của dự án. Cung cấp chức năng giao tiếp với AI Chatbot để tra cứu thông tin (dự án, bảng hàng) bằng ngôn ngữ tự nhiên và theo dõi thông tin quota sử dụng API AI.

Giao diện (UI) chia làm 2 tab chính:
1. **Tìm kiếm Bảng hàng (`AiTableTab`)**: Hiển thị danh sách các bất động sản dựa trên kết quả trả về từ ngữ cảnh (context) giao tiếp với AI. Render UI tái sử dụng `BangHangCard`.
2. **Chatbot Hỗ trợ (`AiChatTab`)**: Cửa sổ chat tương tác với AI theo cơ chế Blocking (Single Request) bảo mật an toàn với `flutter_widget_from_html`, đồng thời hiển thị thẻ Hạn mức (Quota) của ngày/tháng.

---

## 2. Luồng hoạt động (Data Flow & Architecture)

### 2.1. Domain Layer (`domain/`)
- Mọi logic xoay quanh các Data tĩnh (Entities): `AiMessage`, `AiChatResponse`, `AiQuotaInfo`, `AiQuotaRequestInfo`. Độc lập không phụ thuộc JSON hay framework.
- Định nghĩa abstract class `AiAssistantRepository`: Chứa contract giao tiếp (như `sendMessage`).

### 2.2. Data Layer (`data/`)
- **Remote Data Source (`AiAssistantRemoteDataSource`)**: Kết nối đến Backend API qua `Dio`. Endpoint hiện tại: `POST /ai/chat`. Phân tích format kết quả (`status: 1`), xử lý ném `ApiException` chuẩn hóa lỗi của Backend truyền xuống thẳng giao diện.
- **Models (`ai_..._model.dart`)**: Kế thừa trực tiếp từ Domain Entities. Implement hàm `fromJson` / `toJson` **thủ công**, bỏ qua `@JsonSerializable` theo đó không cần phụ thuộc vào bước `build_runner`.
- **Repository Implementation`: Bọc luồng gọi hàm từ DataSource, trả thẳng object Model lên hoặc quăng Exception (tuân thủ rule xử lý exception tự custom của dự án).

### 2.3. Presentation Layer (`presentation/`)
- **State Management (`AiAssistantProvider`)**: Quản lý biến trạng thái (Danh sách chat `messages`, thẻ thông tin Quota, Trạng thái loading, Lỗi exception). Flow cơ bản: UI ném event → Provider call method → chờ API (Loading=true) → Nhận response → Update các Entities variables → Báo thay đổi `notifyListeners()` xuống UI.
- **UI Element**: `AiAssistantScreen` là màn hình chính với `go_router` chạy route riêng không bọc vào Shell, tránh lỗi UI thanh Menu ngang với BottomBar của CMS.

---

## 3. Hạng mục đang khuyết (Pending & TODOs)
Những hạng mục dưới đây đang trống, sẽ được hoàn thiện sau khi có đặc tả chi tiết từ User/Backend:

### [TODO 1] Tích hợp Lịch sử Chat (Chat History)
* **Status**: Thiết kế Front-end đã sẵn sàng hiển thị danh sách cũ, nhưng chưa có luồng gọi API khởi tạo. Lịch sử hiện tại đang được Backend tự lưu ngầm.
* **Cần làm**:
    1. Lấy thông tin từ User về Method, Route URI (vd: `GET /ai/chat/history`), JSON Response format của list history.
    2. Cập nhật Repository Interfaces & Remote DataSource bổ sung hàm gọi danh sách Lịch sử.
    3. Update tại Provider (`fetchHistory()`), nạp data cũ vào mảng biến `_messages` khi khởi chạy màn hình.

### [TODO 2] Kiểu dữ liệu "Khách Hàng" cho Tab Danh sách
* **Status**: Hiện tại, `_latestItems` trong `AiAssistantProvider` đang tự động parse dữ liệu trả về theo Model `BangHangItemModel` (do Tab Tìm kiếm Bảng hàng).
* **Cần làm**: Ở tương lai gần, trợ lý AI cũng có thể tra cứu cho màn `Khách hàng`. Nếu API cùng chung 1 endpoint `POST /ai/chat`, lúc parse danh sách biến `items:` trong `AiChatResponseModel.fromJson` sẽ cần cấu trúc logic để Detect đâu là Item Khách hàng, đâu là Item Bảng Hàng để Render Card Component List tương ứng. Có thể yêu cầu Backend flag thêm parameter `item_type: 'bảng_hàng' | 'khách_hàng'` trong Response để rẽ nhánh.

### [TODO 3] Auto-Scroll xuống tin nhắn mới
* **Status**: List tin nhắn khi đầy trên màn hình (vượt quá chiều cao điện thoại) không tự động cuộn xuống dòng cuối cùng khi AI vừa trả lời xong 1 response dài.
* **Cần làm**: Thêm thư viện / hoặc thủ thuật đính kèm `ScrollController` vào `ListView` trong file `AiChatTab` → Listen lúc `messages` có item mới để tiến hành `.animateTo(scrollController.position.maxScrollExtent)`.
