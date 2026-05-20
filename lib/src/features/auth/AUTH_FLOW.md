# Authentication Flow — Documentation

## Overview

Luồng xác thực gồm **5 màn hình**, sử dụng kiến trúc **MVVM** (Provider + ChangeNotifier) và **Clean Architecture**.

---

## Flow Diagram

```
SplashScreen (3s)
    │
    ▼
┌──────────────────┐     ┌────────────────────┐     ┌──────────────┐     ┌────────────────┐     ┌───────────┐
│  PhoneLoginView  │────▶│ OtpVerificationView │────▶│ SetupPinView │────▶│ ConfirmPinView │────▶│ Dashboard │
│  /phone-login    │     │ /otp-verification   │     │ /setup-pin   │     │ /confirm-pin   │     │           │
└──────────────────┘     └────────────────────┘     └──────────────┘     └────────────────┘     └───────────┘

┌──────────────┐
│ PinLoginView │─────────────────────────────────────────────────────────────────────────────────▶│ Dashboard │
│ /pin-login   │  (Returning user — direct entry)
└──────────────┘
```

---

## Screens

| #  | Screen                | Route               | Mô tả                                                        |
|----|----------------------|----------------------|---------------------------------------------------------------|
| 1  | `PhoneLoginView`      | `/phone-login`       | Nhập số điện thoại → gọi API gửi OTP                         |
| 2  | `OtpVerificationView` | `/otp-verification`  | Nhập 6 số OTP → xác thực                                     |
| 3  | `SetupPinView`        | `/setup-pin`         | Thiết lập mã PIN 6 số                                        |
| 4  | `ConfirmPinView`      | `/confirm-pin`       | Xác nhận lại PIN (phải khớp với Screen 3)                     |
| 5  | `PinLoginView`        | `/pin-login`         | Đăng nhập bằng PIN cho user đã đăng ký (returning session)    |

---

## Architecture

```
lib/src/features/auth/
├── data/                          # Data Layer
│   ├── datasources/
│   │   └── auth_remote_source.dart
│   └── repositories/
│       └── auth_repository_impl.dart
├── domain/                        # Domain Layer
│   └── repositories/
│       └── auth_repository.dart
├── presentation/                  # Presentation Layer
│   ├── provider/
│   │   ├── auth_provider.dart     # API login (username/password — legacy)
│   │   └── auth_view_model.dart   # Auth flow state (phone, OTP, PIN) — Firebase Phone Auth
│   ├── screens/
│   │   ├── phone_login_view.dart
│   │   ├── otp_verification_view.dart
│   │   ├── setup_pin_view.dart
│   │   ├── confirm_pin_view.dart
│   │   ├── pin_login_view.dart
│   │   └── login_screen.dart      # Legacy (username/password)
│   └── widgets/
│       ├── auth_background_widget.dart
│       ├── auth_bottom_card.dart
│       ├── otp_pin_input_widget.dart
│       └── primary_button.dart
└── AUTH_FLOW.md                   # (This file)
```

**Core Services:**
- `lib/src/core/services/firebase_auth_service.dart` — Firebase Phone Auth wrapper
```

---

## Shared Widgets

| Widget                 | Mô tả                                                              |
|------------------------|--------------------------------------------------------------------|
| `AuthBackgroundWidget` | Scaffold với dark background `#2B2104` + hiệu ứng gradient vàng   |
| `AuthBottomCard`       | Card bo góc 28px, nền `#FCFAF4` 70% opacity                       |
| `OtpPinInputWidget`    | 6 ô input (38×38, radius 8px), hỗ trợ `obscureText` cho PIN       |
| `PrimaryButton`        | Nút bo tròn 20px, 2 variant: filled (gold) và outlined (viền)     |

---

## State Management — `AuthViewModel`

```dart
class AuthViewModel extends ChangeNotifier {
  AuthViewModel({
    required this.pinStorage,
    required this.firebaseAuthService,
  });

  String phoneNumber;        // Số điện thoại
  String otp;                // Mã OTP 6 số
  String pin;                // Mã PIN thiết lập
  String confirmPin;         // Nhập lại PIN để xác nhận
  bool isLoading;            // Trạng thái loading
  String? errorMessage;      // Thông báo lỗi
  String? _verificationId;   // Firebase verification ID

  Future<bool> submitPhone();       // Firebase verifyPhoneNumber → gửi OTP
  Future<bool> verifyOtp();         // Firebase signInWithCredential → xác thực OTP
  bool validatePin();               // Validate PIN 6 số
  Future<bool> confirmAndSetPin();  // So sánh + lưu PIN (secure storage)
  Future<bool> loginWithPin(pin);   // Đăng nhập bằng PIN
  void reset();                     // Reset toàn bộ state
  String _formatPhone(phone);       // Convert 0xxx → +84xxx
}
```

---

## Design Tokens

| Token            | Value                       | Usage                          |
|------------------|-----------------------------|--------------------------------|
| Background       | `#2B2104`                   | Dark background cho tất cả     |
| Primary Gold     | `#B58C5F`                   | Button, active border, link    |
| Card BG          | `#FCFAF4` (70% opacity)    | Bottom card overlay            |
| Text Dark        | `#363636`                   | Button label, card title       |
| Text Hint        | `#909090`                   | Input placeholder              |
| Border Active    | `#B58C5F`                   | Ô đang focus                  |
| Border Inactive  | `#D9D9D9`                   | Ô chưa nhập                   |
| Button Radius    | `20px`                      | Pill-shaped button             |
| Card Radius      | `28px`                      | Góc bo card                    |
| PIN Box          | `38×38`, radius `8px`       | Ô input 6 số                  |
| Font             | Inter (Google Fonts)        | Toàn bộ typography             |

---

## Routing & DI

- **Router**: `lib/src/config/router/app_router.dart` — GoRouter
- **DI**: `lib/injection_container.dart` — GetIt (`AuthViewModel` registered as factory)
- **Providers**: `lib/main.dart` — MultiProvider (AuthProvider, AuthViewModel, DashboardProvider)

---

## Firebase Phone Auth — Integrated ✅

| Method | Firebase API |
|--------|-------------|
| `submitPhone()` | `FirebaseAuth.verifyPhoneNumber()` → `onCodeSent` callback |
| `verifyOtp()` | `PhoneAuthProvider.credential()` → `signInWithCredential()` |

**Test Phone:** `+84 999 999 999` — Verification Code: `123123`

**Phone Format:** `0999999999` → `+84999999999` (handled by `_formatPhone`)
