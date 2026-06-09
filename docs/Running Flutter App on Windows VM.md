
### Planner Response

Để có thể chạy ứng dụng Flutter Desktop (`billiard_desktop`) trên máy ảo Windows (VM) từ máy Mac của bạn, tôi đã chuẩn bị sẵn mã nguồn để tương thích với Windows và tổng hợp hướng dẫn chi tiết từng bước dưới đây.

---

### 🛠️ Bước 1: Chuẩn bị mã nguồn trên máy (Tôi đã làm giúp bạn)
Mặc định, ứng dụng sử dụng gói `sqflite` (SQLite) chỉ hỗ trợ các hệ điều hành di động (Android, iOS) và macOS. Nếu chạy trên Windows, ứng dụng sẽ bị lỗi crash do thiếu plugin SQLite.

Tôi đã chỉnh sửa các tệp sau để ứng dụng hỗ trợ Windows tự động:
1. **[pubspec.yaml](file:///Users/hieukona/Downloads/app/billiard_pos/apps/billiard_desktop/pubspec.yaml)**: Thêm các gói thư viện `sqflite_common_ffi` và `sqlite3_flutter_libs` để hỗ trợ SQLite thông qua FFI trên Windows.
2. **[main.dart](file:///Users/hieukona/Downloads/app/billiard_pos/apps/billiard_desktop/lib/main.dart)**: Thêm logic cấu hình tự động chuyển đổi database factory sang chế độ FFI khi ứng dụng chạy trên nền tảng Windows hoặc Linux.

---

### 💻 Bước 2: Thiết lập máy ảo Windows trên Mac

Tùy thuộc vào loại vi xử lý (Chip) trên máy Mac của bạn, hãy chọn giải pháp máy ảo phù hợp:

1. **Nếu bạn dùng Mac Apple Silicon (Chip M1, M2, M3, M4...)**:
   * **Parallels Desktop (Khuyên dùng)**: Hiệu năng tốt nhất, hỗ trợ cài đặt Windows 11 ARM tự động chỉ với 1-click.
   * **UTM (Miễn phí)**: Giải pháp mã nguồn mở tốt để chạy Windows 11 ARM trên Apple Silicon.
2. **Nếu bạn dùng Mac Intel**:
   * **VMware Fusion (Miễn phí cho cá nhân)** hoặc **VirtualBox**: Cài đặt Windows 11 x64.

---

### ⚙️ Bước 3: Thiết lập môi trường phát triển Flutter trong máy ảo Windows

Sau khi đã khởi động máy ảo Windows thành công, hãy thực hiện cài đặt các công cụ sau **bên trong máy ảo**:

1. **Cài đặt Visual Studio 2022 (Bắt buộc để biên dịch ứng dụng C++ cho Windows)**:
   * Tải về tại: [Visual Studio Downloads](https://visualstudio.microsoft.com/downloads/) (chọn bản Community miễn phí).
   * Trong quá trình cài đặt, bạn **phải tích chọn** workload **"Desktop development with C++"** (Phát triển ứng dụng Desktop bằng C++).
2. **Cài đặt Git cho Windows**:
   * Tải về và cài đặt tại: [Git for Windows](https://git-scm.com/download/win).
3. **Cài đặt Flutter SDK**:
   * Tải Flutter SDK dành cho Windows.
   * Giải nén vào một thư mục không có dấu cách (ví dụ: `C:\src\flutter`).
   * Thêm đường dẫn `C:\src\flutter\bin` vào biến môi trường **PATH** của Windows.
4. **Kiểm tra môi trường**:
   * Mở CMD hoặc PowerShell trong máy ảo Windows và chạy lệnh:
     ```powershell
     flutter doctor
     ```
   * Đảm bảo phần **Visual Studio** có dấu tích xanh.

---

### 📂 Bước 4: Chia sẻ mã nguồn vào máy ảo Windows

Có 2 cách thông dụng để lấy code vào máy ảo:
* **Cách 1 (Chia sẻ thư mục - Khuyên dùng)**: Bật tính năng **Shared Folder** của phần mềm máy ảo (Parallels/VMware) để chia sẻ trực tiếp thư mục dự án `/Users/hieukona/Downloads/app/billiard_pos` từ máy Mac sang máy ảo Windows.
* **Cách 2 (Git Clone)**: Bạn có thể cài đặt SSH Key/mật khẩu Git trong máy ảo và clone trực tiếp mã nguồn từ repository từ xa về máy ảo Windows.

---

### 🚀 Bước 5: Chạy ứng dụng trên Windows VM

Mở terminal (CMD/PowerShell hoặc VS Code terminal) trong máy ảo Windows tại thư mục dự án `apps/billiard_desktop` và thực hiện các lệnh sau:

1. **Lấy các gói phụ thuộc mới**:
   ```powershell
   flutter pub get
   ```
2. **Chạy ứng dụng dưới chế độ Debug**:
   ```powershell
   flutter run -d windows
   ```
3. **Biên dịch ứng dụng bản phát hành (Release)**:
   ```powershell
   flutter build windows
   ```
   *Tệp thực thi (`.exe`) sau khi build sẽ nằm tại thư mục: `build\windows\x64\runner\Release`.*