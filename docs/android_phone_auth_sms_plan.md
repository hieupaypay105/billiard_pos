# Android Phone Auth SMS Config Checklist (Debug + Release)

Tệp Markdown: /Users/quanghuyexclusive/Code/anholding_app/docs/android_phone_auth_sms_plan.md

## 1) Đã có trong repo (✅)
- ✅ Đã dùng Firebase Phone Auth (verifyPhoneNumber, signInWithCredential) trong lib/src/core/services/firebase_auth_service.dart.
- ✅ Đã có cờ test phone FIREBASE_AUTH_TEST_PHONES và setSettings(...) cho môi trường debug.
- ✅ Đã bật App Check runtime, release dùng Play Integrity trong lib/src/core/firebase_bootstrap.dart.
- ✅ Đã apply plugin com.google.gms.google-services trong android/app/build.gradle.kts.
- ✅ Đã có android/app/google-services.json.
- ✅ applicationId = com.anholding.app khớp Android config hiện tại.
- ✅ Đã có quyền INTERNET trong android/app/src/main/AndroidManifest.xml.
- ✅ Đã có normalize phone về E.164 (+84...) trong lib/src/features/auth/presentation/provider/auth_view_model.dart.
- ✅ Firebase Console: Authentication > Sign-in providers đã bật Phone và Google.
- ✅ Firebase Console: SMS Multi-factor Authentication đang Enabled.
- ✅ Firebase Console: Android app com.anholding.app đã có SHA fingerprints (2x SHA-1, 1x SHA-256).
- ✅ Release build đã cấu hình dùng keystore thật nếu có android/key.properties (fallback debug nếu chưa có).
- ✅ Release signing không còn hardcode debug key trong android/app/build.gradle.kts.
- ✅ Firebase Console: đã cấu hình Phone numbers for testing.
- ✅ Đã tạo android/key.properties trỏ tới /Users/quanghuyexclusive/upload-keystore.jks (alias `upload`).
- ✅ `flutter build apk --release` chạy thành công.

## 2) Chưa xong / chưa xác nhận (❌)
- ❌ App Check: Authentication đang ở Monitoring, 0% verified (cần tạo traffic và kiểm tra token trước khi Enforce).
- ❌ Firebase Console cảnh báo cần SHA-1 release fingerprint cho Android để enable Phone provider (cần xác nhận SHA-1 release đã add đúng).

## 3) Checklist thực thi đề xuất
1. (Optional) Thêm test phone/code trong Firebase Console để debug nhanh.
2. Xác nhận SHA-1/SHA-256 đã đủ cho debug + release; bổ sung nếu thiếu.
3. Nếu có thay SHA, tải mới google-services.json, thay vào android/app/google-services.json.
4. Tạo android/key.properties và cấu hình release signing thật (không dùng debug signing cho build release).
5. Test debug với --dart-define=FIREBASE_AUTH_TEST_PHONES=true.
6. Test số thật ở release build với test matrix: send OTP, resend, wrong OTP, timeout, too-many-requests.
7. Cấu hình App Check cho Authentication (monitor trước, enforce sau khi pass test).

## 4) Test cases tối thiểu
- Debug test phone: gửi OTP và verify thành công.
- Release số thật: nhận SMS và verify thành công.
- Sai OTP: hiện đúng thông báo lỗi.
- Gửi quá nhiều lần: hiện too-many-requests đúng.
- Số sai định dạng: chặn từ client trước khi gọi Firebase.

## 5) Assumptions
- Scope chỉ Android.
- Không đổi provider auth (vẫn Firebase Phone Auth).
- Giữ nguyên kiến trúc hiện tại, chỉ hoàn thiện cấu hình và vận hành.

## 6) Runbook xử lý lỗi OTP production
### 6.1) Quota / `quota-exceeded`
- Dấu hiệu: không gửi được SMS, error `quota-exceeded` hoặc tỉ lệ fail tăng đột biến.
- Kiểm tra:
1. Firebase Console > Authentication > Usage (hoặc Billing) xem quota SMS.
2. So sánh spike theo thời gian với log backend/analytics.
- Xử lý:
1. Giảm tần suất resend ở client (cooldown rõ ràng).
2. Chặn spam theo IP/device (nếu có backend).
3. Nếu là production spike hợp lệ: nâng quota / bật billing.

### 6.2) `too-many-requests`
- Dấu hiệu: gửi quá nhiều OTP trong thời gian ngắn.
- Kiểm tra: logs ở client, tần suất retry.
- Xử lý:
1. Tăng cooldown resend (UI lockout 30-60s).
2. Tránh auto-retry khi gặp lỗi này.
3. Thêm rate limit theo device/phone ở client.

### 6.3) `app-not-authorized`
- Dấu hiệu: Firebase trả lỗi app chưa được authorize.
- Nguyên nhân phổ biến: thiếu/nhầm SHA-1, dùng sai appId, google-services.json cũ.
- Xử lý:
1. Xác nhận appId đúng `com.anholding.app`.
2. Add đúng SHA-1 (debug hoặc release keystore đang ký APK).
3. Tải lại `google-services.json`, clean build.
4. Nếu dùng Play App Signing: dùng SHA-1 App signing key từ Play Console.

### 6.4) SHA mismatch / cảnh báo SHA-1 release
- Dấu hiệu: Firebase console cảnh báo cần SHA-1 release, OTP fail ở release build.
- Xử lý:
1. Kiểm tra release build đang ký bằng key nào (debug vs release).
2. So khớp SHA-1 của key đó với Firebase.
3. Tải mới `google-services.json`, build lại.
