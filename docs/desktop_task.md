# Task: Billiard Desktop – Full Layout Build

## Phase 1: Dependencies & Config
- [x] Đọc .env – xác nhận API_BASE_URL
- [ ] Cập nhật `pubspec.yaml` desktop với dependencies mới
- [ ] Chạy `flutter pub get`

## Phase 2: Core Layer
- [ ] `core/constants/app_colors.dart`
- [ ] `core/constants/app_text_styles.dart`
- [ ] `core/services/api_client.dart` (Dio + JWT interceptor)
- [ ] `core/services/local_db_service.dart` (SQLite)
- [ ] `core/services/sync_service.dart`
- [ ] `core/router/app_router.dart` (go_router)
- [ ] `core/providers/providers.dart`

## Phase 3: Auth Feature
- [ ] `features/auth/auth_provider.dart` (Riverpod + SharedPreferences)
- [ ] `features/auth/login_screen.dart`

## Phase 4: App Shell
- [ ] `core/widgets/app_shell.dart` (NavigationRail layout)
- [ ] `core/widgets/status_bar.dart`
- [ ] Refactor `main.dart` → `app.dart`

## Phase 5: Tables Feature (Refactor)
- [ ] `features/tables/tables_provider.dart`
- [ ] `features/tables/tables_screen.dart` (refactor từ main.dart)
- [ ] Move `table_card.dart`

## Phase 6: Billing Feature
- [ ] `features/billing/billing_provider.dart`
- [ ] `features/billing/billing_screen.dart`
- [ ] `features/billing/add_product_panel.dart`
- [ ] `features/billing/member_lookup.dart`
- [ ] `features/billing/discount_panel.dart`
- [ ] `features/billing/invoice_dialog.dart` (refactor)
- [ ] `features/billing/table_merge_dialog.dart`
- [ ] `features/billing/table_transfer_dialog.dart`

## Phase 7: Statistics Feature
- [ ] `features/statistics/statistics_provider.dart`
- [ ] `features/statistics/statistics_screen.dart`

## Phase 8: Reports Feature
- [ ] `features/reports/reports_provider.dart`
- [ ] `features/reports/reports_screen.dart`

## Phase 9: Sync Feature
- [ ] `features/sync/sync_provider.dart`
- [ ] `features/sync/sync_screen.dart`

## Phase 10: Unit Tests
- [ ] `test/models/order_model_test.dart`
- [ ] `test/features/auth/auth_provider_test.dart`
- [ ] `test/features/billing/billing_provider_test.dart`
- [ ] `test/features/tables/tables_provider_test.dart`

## Phase 11: Verify
- [ ] `flutter pub get` pass
- [ ] `flutter analyze` clean
- [ ] `flutter test` pass
- [ ] `flutter run -d macos` build OK
