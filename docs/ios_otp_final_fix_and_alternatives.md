# iOS OTP Final Fix Checklist And Alternatives

Tệp Markdown: /Users/quanghuyexclusive/Code/anholding_app/docs/ios_otp_final_fix_and_alternatives.md

## 1) Mục tiêu tài liệu
- Chốt các cách cuối cùng còn đáng thử để cứu Firebase Phone Auth trên iOS.
- Nếu vẫn fail `notification-not-forwarded`, chuyển nhanh sang giải pháp OTP thay thế để không chặn release.

## 2) Hiện trạng đã xác nhận
- ✅ App iOS đã lấy được APNs token (`APNs registered, token (hex): ...`).
- ✅ `Bundle ID`, `Team ID`, Firebase iOS app, APNs key `.p8`, Cloud Messaging API, Phone provider và SMS MFA đã khớp.
- ✅ Signing iOS đã có `Profile = Ad Hoc`, `Release = App Store Connect`, cert `Apple Distribution`.
- ✅ `aps-environment = production`.
- ✅ Native AppDelegate đã forward APNs token và `canHandleNotification(...)`.
- ❌ Không thấy log `FirebaseAuth handled remote notification for phone auth`.
- ❌ TestFlight vẫn lặp lại `notification-not-forwarded`.

## 3) Checklist các cách cuối cùng để fix Firebase OTP trên iOS
### 3.1) Reset sạch artifact và runtime
1. Xóa app khỏi iPhone.
2. `Product > Clean Build Folder`.
3. Xóa Derived Data của project.
4. Build lại bằng `Profile` để test nội bộ và bằng `Archive -> TestFlight` để test production path.
5. Kiểm tra lại Xcode/Console log sau cài mới, không test trên bản app cũ.

### 3.2) Tạo lại APNs key hoàn toàn mới
1. Vào Apple Developer > Keys.
2. Revoke key APNs hiện tại nếu xác định không dùng hệ thống nào khác phụ thuộc vào key đó.
3. Tạo APNs key mới hoàn toàn.
4. Upload key mới vào Firebase Console > Cloud Messaging > Apple app configuration.
5. Rebuild app và test lại.

### 3.3) Cô lập vấn đề bằng app mẫu tối giản
1. Tạo một Flutter app tối giản chỉ gồm `firebase_core` + `firebase_auth`.
2. Dùng cùng Firebase project hoặc tạo project Firebase mới riêng cho test.
3. Cấu hình iOS signing/APNs giống app thật.
4. Test chỉ một màn hình nhập số điện thoại và gọi `verifyPhoneNumber`.
5. Nếu app mẫu chạy được, vấn đề nằm ở integration trong app hiện tại.
6. Nếu app mẫu vẫn fail, khả năng cao là regression của SDK hoặc APNs delivery path ngoài app.

### 3.4) Thử matrix version có chủ đích
- Hiện tại repo đang dùng:
  - `firebase_auth = 5.7.0`
  - `firebase_core = 3.15.2`
  - Firebase iOS SDK `11.15.0`
- Cách thử:
1. Tạo branch riêng cho việc thử version.
2. Thử nâng đồng bộ FlutterFire lên minor/patch mới nhất tương thích cùng major.
3. Nếu vẫn fail, thử pin xuống một cặp version ổn định hơn của `firebase_auth` + `firebase_core`.
4. Sau mỗi lần đổi version:
   - `flutter pub get`
   - `pod install` / build lại iOS
   - xóa app, clean build folder, test lại.

### 3.5) Dùng log native để chốt lỗi nằm ở đâu
- Log phải tìm:
  - `APNs registered, token (hex): ...`
  - `FirebaseAuth handled remote notification for phone auth`
  - `FirebaseAuth handled auth callback URL: ...`
- Diễn giải:
  - Có APNs token nhưng không có `handled remote notification`: silent push xác minh không quay về app.
  - Có callback URL nhưng vẫn fail: verification path không hoàn tất ở FirebaseAuth SDK.
  - Không có cả hai: app không nhận được verification event từ Firebase/Apple.

### 3.6) Tiêu chí dừng theo đuổi Firebase OTP iOS
- Dừng nếu đồng thời đúng cả 4 điều sau:
1. APNs token đã nhận.
2. Signing/provisioning/TestFlight đã đúng.
3. Firebase/APNs key mapping đã đúng.
4. TestFlight vẫn lặp lại `notification-not-forwarded` qua nhiều bản build sạch.

## 4) Giải pháp thay thế Firebase OTP cho iOS
### 4.1) Phương án khuyến nghị: OTP qua backend riêng
- Ý tưởng:
  - App gửi số điện thoại lên backend.
  - Backend tạo OTP, gửi SMS qua provider.
  - User nhập OTP.
  - Backend verify OTP và trả access token/session cho app.
- Ưu điểm:
  - Không phụ thuộc APNs verification path của Firebase Auth iOS.
  - Chủ động rate limit, resend cooldown, anti-spam, audit log.
  - Hành vi Android/iOS đồng nhất.
- Nhược điểm:
  - Phải tự vận hành backend OTP.
  - Phải xử lý bảo mật OTP, expiry, retry, abuse control.

### 4.2) Provider SMS đề xuất
- Twilio Verify
  - Mạnh, tài liệu tốt, có sẵn flow verify OTP.
- MessageBird / Vonage / Infobip
  - Phù hợp nếu cần tối ưu route/SMS theo thị trường.
- Nhà cung cấp SMS nội địa
  - Hợp nếu app tập trung thị trường Việt Nam và cần chi phí/routing tốt hơn.

### 4.3) Kiến trúc backend tối thiểu
1. `POST /otp/request`
   - Input: phone chuẩn hóa E.164
   - Logic: tạo OTP, lưu hash OTP + expiry + attempt count, gửi SMS
2. `POST /otp/verify`
   - Input: phone + otp
   - Logic: verify hash, check expiry/retry, đánh dấu used
3. `POST /auth/login-by-phone`
   - Sau khi verify thành công, tạo session/JWT cho app

### 4.4) Guardrails bắt buộc nếu tự làm OTP
- Cooldown resend 30-60s.
- Giới hạn số lần gửi theo phone/device/IP.
- OTP hết hạn ngắn, ví dụ 3-5 phút.
- Hash OTP ở server, không lưu plain text.
- Chặn brute force theo số lần nhập sai.
- Audit log cho request/verify/resend.

### 4.5) Cách chuyển đổi thực dụng cho app hiện tại
- Option A: Android giữ Firebase Phone Auth, iOS dùng backend OTP riêng.
- Option B: Cả Android và iOS cùng chuyển sang backend OTP để đồng nhất vận hành.
- Option C: Giữ Firebase chỉ như identity store, còn OTP gửi/verify qua backend, sau đó map user nội bộ thay vì dựa trực tiếp vào Firebase Phone Auth.

## 5) Khuyến nghị ra quyết định
- Nếu deadline gần:
  - Chỉ thử thêm tối đa 1 vòng với APNs key mới hoặc app mẫu tối giản.
  - Nếu vẫn fail, chuyển sang backend OTP cho iOS.
- Nếu ưu tiên đồng nhất lâu dài:
  - Chuyển toàn bộ phone OTP sang backend/provider riêng.
- Nếu vẫn muốn giữ Firebase:
  - Dành một branch riêng để thử matrix version và app mẫu tối giản, không tiếp tục chỉnh config ở app chính một cách thử-sai.

## 6) Checklist quyết định cuối
- `Continue Firebase iOS` nếu:
  - app mẫu tối giản chạy được hoặc đổi version giải quyết được lỗi.
- `Switch iOS only` nếu:
  - Android đang ổn với Firebase, nhưng iOS vẫn fail sau vòng thử cuối.
- `Switch all platforms` nếu:
  - muốn đồng nhất luồng OTP, chống abuse tốt hơn và giảm phụ thuộc vào APNs/Firebase runtime behavior.
