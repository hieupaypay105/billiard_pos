# Hướng Dẫn Khắc Phục Lỗi Chứng Chỉ MSIX Trên Windows (Error 0x800B010A)

Tài liệu này hướng dẫn cách giải quyết lỗi xác thực chứng chỉ nhà phát hành khi cài đặt gói ứng dụng `.msix` hoặc `.msi` được build bằng công cụ đóng gói trên hệ điều hành Windows.

---

## 1. Nguyên nhân lỗi

Khi đóng gói ứng dụng Windows bằng các công cụ như thư viện `msix` trong Flutter (`dart run msix:create`), một chứng chỉ số tự ký (self-signed certificate) sẽ được tự động tạo và sử dụng để ký số cho bộ cài đặt. 

Mặc định, Windows Defender và hệ thống bảo mật của Windows chỉ cho phép cài đặt các gói ứng dụng có chứng chỉ được cấp bởi các tổ chức xác thực toàn cầu đáng tin cậy. Do đó, hệ thống sẽ chặn và báo lỗi sau:

> **"This app package's publisher certificate could not be verified. Contact your system administrator or the app developer to obtain a new app package with verified certificates. (0x800B010A)"**

---

## 2. Các bước khắc phục chi tiết

Để cài đặt được ứng dụng, bạn cần thêm chứng chỉ tự ký đi kèm gói cài đặt `.msix` vào danh sách **Trusted Root Certification Authorities** (Cơ quan cấp chứng chỉ gốc đáng tin cậy) của máy tính. Hãy thực hiện theo các bước sau:

### Bước 1: Mở Thuộc tính tệp tin
* Nhấp chuột phải vào tệp tin `.msix` (Ví dụ: `New World Pos.msix`).
* Chọn **Properties** (Thuộc tính) ở phía dưới cùng menu ngữ cảnh.

### Bước 2: Xem chi tiết Chữ ký số
* Tại cửa sổ Properties, chuyển sang tab **Digital Signatures** (Chữ ký số).
* Nhấp chọn chữ ký xuất hiện trong danh sách **Signature list**.
* Bấm vào nút **Details** (Chi tiết).

### Bước 3: Xem Chứng chỉ
* Một cửa sổ mới "Digital Signature Details" sẽ hiện lên.
* Tại tab General, bấm vào nút **View Certificate** (Xem chứng chỉ).

### Bước 4: Bắt đầu cài đặt Chứng chỉ
* Tại cửa sổ Certificate vừa xuất hiện, bấm vào nút **Install Certificate...** (Cài đặt chứng chỉ).

### Bước 5: Chọn vị trí lưu trữ (Store Location)
* Tại mục *Store Location*, chọn **Local Machine** (Máy tính cục bộ) để chứng chỉ có hiệu lực toàn hệ thống.
* Bấm **Next**.
> [!NOTE]
> *Hệ thống có thể yêu cầu quyền Quản trị viên (Administrator). Hãy bấm **Yes** nếu có hộp thoại User Account Control (UAC) xuất hiện.*

### Bước 6: Chọn Kho lưu trữ chứng chỉ (Certificate Store)
* Tích chọn tùy chọn thứ hai: **Place all certificates in the following store** (Đặt tất cả chứng chỉ vào kho lưu trữ sau).
* Bấm vào nút **Browse...** (Duyệt).
* Chọn thư mục đầu tiên có tên: **Trusted Root Certification Authorities** (Cơ quan cấp chứng chỉ gốc đáng tin cậy).
* Bấm **OK** để xác nhận.
* Bấm **Next** để tiếp tục.

### Bước 7: Hoàn tất cài đặt
* Bấm vào nút **Finish** (Hoàn tất) để kết thúc quá trình nạp chứng chỉ.
* Hệ thống sẽ hiển thị thông báo **"The import was successful."** (Nhập chứng chỉ thành công).

---

## 3. Cài đặt ứng dụng

Sau khi chứng chỉ tự ký đã được cài đặt và tin cậy trên hệ thống Windows:
1. Đóng toàn bộ các cửa sổ thuộc tính lại.
2. Nhấp đúp (Double-click) vào tệp cài đặt `.msix`.
3. Trình cài đặt Windows App Installer sẽ xuất hiện và cho phép bạn click **Install** để cài đặt ứng dụng **New World Pos** một cách bình thường và an toàn.
