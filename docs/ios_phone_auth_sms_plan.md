# iOS Phone Auth SMS Config Checklist (Debug + Release)

Tệp Markdown: /Users/quanghuyexclusive/Code/anholding_app/docs/ios_phone_auth_sms_plan.md

## 1) Đã có trong repo (✅)
- ✅ Đã dùng Firebase Phone Auth (`verifyPhoneNumber`, `signInWithCredential`) trong `lib/src/core/services/firebase_auth_service.dart`.
- ✅ Đã có cờ test phone `FIREBASE_AUTH_TEST_PHONES` và `setSettings(...)` cho môi trường debug.
- ✅ Đã bật App Check runtime, release dùng `AppleProvider.appAttestWithDeviceCheckFallback` trong `lib/src/core/firebase_bootstrap.dart`.
- ✅ Đã có `ios/Runner/GoogleService-Info.plist`.
- ✅ `BUNDLE_ID = com.anholding.app` trong `ios/Runner/GoogleService-Info.plist`.
- ✅ `PRODUCT_BUNDLE_IDENTIFIER = com.anholding.app` trong `ios/Runner.xcodeproj/project.pbxproj`.
- ✅ `DefaultFirebaseOptions.ios` khớp bundle/appId hiện tại trong `lib/firebase_options.dart`.
- ✅ `FirebaseAppDelegateProxyEnabled = true` trong `ios/Runner/Info.plist`.
- ✅ Đã đăng ký remote notifications ở native (`application.registerForRemoteNotifications()`) trong `ios/Runner/AppDelegate.swift`.
- ✅ Đã forward APNs token cho Firebase Auth + Messaging (`Auth.auth().setAPNSToken(...)`, `Messaging.messaging().apnsToken = deviceToken`) trong `ios/Runner/AppDelegate.swift`.
- ✅ Đã có URL scheme Google Sign-In (`REVERSED_CLIENT_ID`) trong `ios/Runner/Info.plist`.
- ✅ Signing hiện dùng `CODE_SIGN_STYLE = Automatic` và có `DEVELOPMENT_TEAM = CF38UX62QX`.
- ✅ Entitlements đã khai báo `aps-environment` và `com.apple.developer.devicecheck.appattest-environment`.
- ✅ Firebase Console > Authentication > Sign-in providers: Phone đang Enabled.
- ✅ Firebase Console > Authentication: đã có Phone numbers for testing (`+84 1231 23123` / `123123`).
- ✅ Firebase Console > Authentication: SMS Multi-factor Authentication đang Enabled.
- ✅ Firebase Console > Project Settings: iOS app `anholding_app (ios)` đã tồn tại với App ID `1:123770882118:ios:237e771d2b539381112247`, Team ID `CF38UX62QX`, Bundle ID `com.anholding.app`.
- ✅ Firebase Console > Cloud Messaging: API (V1) Enabled.
- ✅ Firebase Console > Cloud Messaging > Apple app configuration: đã upload APNs Authentication Key cho cả Development và Production (Key ID `U8L49HU7Q4`, Team ID `CF38UX62QX`).
- ✅ Xcode > Runner > Signing & Capabilities: đã bật Push Notifications, App Attest, Background Modes (fetch/processing/remote notifications).

## 2) Chưa xong / chưa xác nhận (❌)
- ❌ Chưa có profile App Store Connect (TestFlight/App Store) gắn Apple Distribution; Release hiện dùng Ad Hoc `AnHolding_AppStore_Push_v2` cho nội bộ, cần tạo thêm profile App Store Connect để upload TestFlight.
- ❌ Entitlements release/profile: `aps-environment` trong repo là `development`, cần xác nhận và set `production` cho build phân phối.
- ❌ App Check: Authentication đang ở Monitoring, cần có traffic verified trước khi Enforce.
- ❌ Chưa có xác nhận end-to-end OTP với số thật trên thiết bị iOS bản release/TestFlight.

## 3) Checklist thực thi đề xuất
1. Giữ nguyên cấu hình Firebase đã xác nhận: Phone Enabled, APNs key dev/prod, iOS app `com.anholding.app`.
2. Đã cấu hình Ad Hoc: profile `AnHolding_AdHoc_Push_v2` + certificate “Apple Distribution: Quang Huy Dao” cho build nội bộ (Profile config). Tạo thêm profile App Store Connect cùng certificate cho Release/TestFlight.
3. Set entitlements `aps-environment=production` cho Release/Profile.
4. Nếu thay đổi APNs key/bundle/config, tải lại `GoogleService-Info.plist` và cập nhật vào `ios/Runner/`.
5. Chạy test debug với `--dart-define=FIREBASE_AUTH_TEST_PHONES=true` cho test phone trong Console.
6. Test số thật trên iOS device (không simulator) ở bản Release/Profile với matrix: send OTP, resend, wrong OTP, timeout, too-many-requests.
7. Theo dõi App Check verified traffic cho Authentication, sau đó mới chuyển từ Monitoring sang Enforce.
8. Lưu ý banner SHA-1 release fingerprint trong Phone provider là yêu cầu cho Android, không phải blocker trực tiếp cho iOS.

## 4) Test cases tối thiểu
- Debug test phone: gửi OTP và verify thành công.
- Release/TestFlight số thật: nhận OTP và verify thành công.
- Sai OTP: hiện đúng thông báo lỗi.
- Gửi quá nhiều lần: hiện `too-many-requests` đúng.
- Thiếu APNs/forward token lỗi: bắt được `notification-not-forwarded` và fallback reCAPTCHA hoạt động.
- Số sai định dạng: chặn từ client trước khi gọi Firebase.

## 5) Assumptions
- Scope chỉ iOS.
- Không đổi provider auth (vẫn Firebase Phone Auth).
- Giữ nguyên kiến trúc hiện tại, chỉ hoàn thiện cấu hình và vận hành.

## 6) Runbook xử lý lỗi OTP production (iOS)
### 6.1) `notification-not-forwarded`
- Dấu hiệu: iOS không verify được app credential, OTP fail trước/sau gửi.
- Kiểm tra:
1. Firebase Console có APNs key (.p8) đúng project/app chưa.
2. Bundle ID thực tế có khớp `com.anholding.app` không.
3. AppDelegate có gọi `Auth.auth().setAPNSToken(...)` và `Messaging.messaging().apnsToken` không.
4. Build release có đúng `aps-environment=production` không.
- Xử lý:
1. Sửa cấu hình APNs key/bundle nếu lệch.
2. Rebuild và cài lại app sau khi đổi entitlement/profile.
3. Cho phép fallback reCAPTCHA (đã có trong service khi gặp lỗi này).

### 6.2) `app-not-authorized` / `missing-app-credential`
- Dấu hiệu: Firebase từ chối app khi gửi/verify OTP.
- Nguyên nhân phổ biến: appId/bundleId lệch, `GoogleService-Info.plist` cũ, APNs chưa hợp lệ.
- Xử lý:
1. So khớp `GoogleService-Info.plist` với Firebase app iOS hiện hành.
2. So khớp `PRODUCT_BUNDLE_IDENTIFIER` và bundle trong Firebase.
3. Tải lại plist mới, clean build, cài lại app.

### 6.3) `too-many-requests`
- Dấu hiệu: retry OTP dày, bị throttle.
- Kiểm tra: logs client, tần suất resend theo device/phone.
- Xử lý:
1. Tăng cooldown resend (30-60s).
2. Tránh auto-retry khi gặp lỗi này.
3. Thêm chặn spam theo device/phone ở client (hoặc backend nếu có).

### 6.4) `quota-exceeded`
- Dấu hiệu: vượt quota SMS của Firebase project.
- Kiểm tra: Firebase Authentication Usage/Billing.
- Xử lý:
1. Giảm resend spam.
2. Theo dõi spike theo khung giờ.
3. Nâng quota/billing nếu là traffic hợp lệ production.
