# Hướng Dẫn Kết Nối Relay và Cổng Serial trên macOS (Mac Mini)

Tài liệu này hướng dẫn cách kết nối, nhận diện cổng Serial (cổng nối tiếp) và tích hợp các bộ Relay (rơ-le) điều khiển thiết bị (như đèn bàn bida) trên hệ điều hành macOS, áp dụng cụ thể cho dòng máy Mac Mini.

---

## 1. Khả năng kết nối Serial Port trên macOS

Hệ điều hành macOS hoàn toàn hỗ trợ giao tiếp qua cổng Serial (Serial Port) thông qua các driver điều khiển phần cứng tích hợp sẵn hoặc cài đặt thêm.

### Nhận diện cổng trên macOS
Khác với Windows sử dụng ký hiệu cổng dạng `COM1`, `COM2`, `COM3`..., macOS quản lý các cổng kết nối dưới dạng tệp tin thiết bị trong thư mục hệ thống `/dev/`.
Khi bạn cắm một thiết bị USB-to-Serial hoặc mạch điều khiển vào cổng USB của máy Mac, thiết bị sẽ xuất hiện dưới các tên phổ biến sau:
* `/dev/tty.usbserial-xxxx`
* `/dev/cu.usbserial-xxxx`
*(Trong đó `xxxx` là một chuỗi định danh duy nhất của chip nạp hoặc cổng USB).*

### Hỗ trợ Driver
Hầu hết các phiên bản macOS hiện đại (từ macOS Catalina 10.15 trở lên) đã tích hợp sẵn trình điều khiển (Driver) cho các dòng chip chuyển đổi USB-to-Serial phổ biến nhất trên thị trường:
* **FTDI** (FT232RL, FT232...)
* **WCH** (CH340, CH341 - rất phổ biến trên các mạch Arduino và Relay giá rẻ)
* **Silicon Labs** (CP210x)
* **Prolific** (PL2303)

Bạn chỉ cần cắm thiết bị vào cổng USB của Mac Mini, hệ thống sẽ tự động nhận diện thiết bị mà thường không yêu cầu cài đặt thêm Driver thủ công.

---

## 2. Các phương thức kết nối Relay với Mac Mini

Mac Mini được trang bị sẵn các cổng giao tiếp phía sau máy bao gồm: cổng mạng **Ethernet (LAN) RJ45**, cổng **USB-A** truyền thống và cổng **USB-C / Thunderbolt**. Bạn có thể kết nối với bộ điều khiển Relay theo hai phương thức chính:

### Phương thức 1: Kết nối cổng Serial (USB sang RS485 / USB Relay)

Đây là phương thức kết nối dây trực tiếp qua giao thức nối tiếp (Serial port). Do các mạch Relay công nghiệp nhiều kênh (ví dụ: bộ điều khiển 4, 8, 16, 32 kênh rơ-le) thường sử dụng chuẩn giao tiếp **RS485 (Modbus RTU)**, bạn cần có thiết bị chuyển đổi trung gian.

#### Thiết bị cần chuẩn bị:
1. **Bộ chuyển đổi USB sang RS485** (Khuyên dùng loại tích hợp chip **FTDI FT232** hoặc **CH340** để tương thích tốt nhất với macOS).
2. **Cáp kết nối nối tiếp** (Cáp đôi, cáp điện nhỏ hoặc cáp mạng).

#### Các bước kết nối vật lý:
1. **Bước 1:** Cắm đầu USB của bộ chuyển đổi **USB-to-RS485** vào cổng **USB-A** của Mac Mini (nếu máy Mac chỉ có cổng USB-C, sử dụng thêm đầu chuyển USB-C sang USB-A hoặc Hub USB-C).
2. **Bước 2:** Đấu nối dây tín hiệu từ đầu ra của bộ chuyển đổi RS485 sang mạch Relay:
   * Chân **A+** (hoặc D+) trên bộ chuyển đổi nối với chân **A+** (hoặc D+) trên mạch Relay.
   * Chân **B-** (hoặc D-) trên bộ chuyển đổi nối với chân **B-** (hoặc D-) trên mạch Relay.
   * Chân **GND** (nếu có) nối với chân **GND** của mạch Relay.
3. **Bước 3:** Cấp nguồn điện phù hợp cho mạch Relay (thường là 12V DC hoặc 24V DC tùy loại mạch).

#### Cấu hình cổng kết nối trong phần mềm:
Khi cấu hình trong ứng dụng quản lý bida (Billiard POS), tại mục cài đặt cổng Serial:
* Thay vì nhập cổng dạng `COM3` như trên Windows, bạn hãy nhập đường dẫn cổng nhận diện trên Mac Mini, ví dụ: `/dev/tty.usbserial-1410` hoặc `/dev/cu.usbserial-1410`.
* Cấu hình baud rate tiêu chuẩn thường là `9600`, data bits `8`, stop bits `1`, parity `None`.

---

### Phương thức 2: Kết nối qua mạng LAN (TCP/IP) - *Giải pháp khuyên dùng*

Nếu phần cứng Relay của bạn hỗ trợ cổng mạng RJ45 (Relay LAN), đây là giải pháp tối ưu và đơn giản nhất để triển khai trên macOS.

#### Ưu điểm:
* Không cần cài đặt driver USB-to-Serial trên máy Mac.
* Tránh được các lỗi xung đột phần cứng hoặc cổng USB bị lỏng lẻo vật lý.
* Cho phép đặt bộ Relay ở xa máy tính Mac Mini (khoảng cách kết nối dây mạng LAN lên tới 100 mét mà không sợ suy hao tín hiệu như cáp USB).

#### Các bước kết nối vật lý:
1. **Bước 1:** Cắm dây mạng từ cổng **RJ45** của mạch Relay LAN vào thiết bị **Switch** hoặc **Router** mạng nội bộ của quán bida.
2. **Bước 2:** Kết nối Mac Mini vào cùng một hệ thống mạng nội bộ đó (qua cáp mạng Ethernet hoặc kết nối Wi-Fi).
3. **Bước 3:** Thiết lập địa chỉ IP tĩnh cho mạch Relay LAN (ví dụ: `192.168.1.200`) thông qua phần mềm cấu hình đi kèm của nhà sản xuất Relay.

#### Cấu hình cổng kết nối trong phần mềm:
Trong cấu hình ứng dụng:
* Chọn kiểu kết nối: `TCP/IP` (hoặc `LAN`).
* Nhập địa chỉ **IP** của mạch Relay (Ví dụ: `192.168.1.200`).
* Nhập cổng **Port** truyền nhận dữ liệu của mạch Relay (Ví dụ: `8080` hoặc `5000` tùy theo tài liệu của nhà sản xuất).
