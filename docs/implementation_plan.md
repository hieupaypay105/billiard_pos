# Implementation Plan - Phase 2: Desktop POS Core & IoT Development

This plan outlines the steps to execute Phase 2 of the Billiard POS system development, which builds the core cashier desktop client interface, implements background timer calculations using a Dart Isolate, connects the actual serial port hardware via `flutter_libserialport`, and adds cashier operational tools (ordering, K80 receipt printing, shift closing).

## User Review Required

> [!NOTE]
> We will add `flutter_libserialport` to the `iot_controller` package. This package relies on compiling native libraries for serial port communication. During build/run, Flutter will download and compile the serial port C dependencies for the local operating system (Windows, macOS, or Linux).

## Proposed Changes

We will modularize the `billiard_desktop` application code by moving UI code from a single `main.dart` into clean, reusable component files under `lib/src/`. We will also implement the background timer isolate and integrate the real serial port library.

---

### [Component 1] Package `iot_controller`

We will integrate `flutter_libserialport` to support real serial connections (RS485/USB) on Windows, macOS, and Linux.

#### [MODIFY] [pubspec.yaml](file:///Users/hieukona/Downloads/app/billiard_pos/packages/iot_controller/pubspec.yaml)
- Add `flutter_libserialport: ^0.2.2` to the dependencies.
- Add `flutter: sdk: flutter` to support plugins.

#### [MODIFY] [real_billiard_iot_controller.dart](file:///Users/hieukona/Downloads/app/billiard_pos/packages/iot_controller/lib/src/real_billiard_iot_controller.dart)
- Import `package:flutter_libserialport/flutter_libserialport.dart`.
- In `connect`, initialize `SerialPort` with the configured port name.
- Configure port options (baudrate 9600, data bits 8, stop bits 1, parity none).
- Use `SerialPortReader` to listen to incoming serial byte traffic and print log events.
- In `turnOn` and `turnOff`, write commands to the serial port as bytes using `SerialPort.write`.
- Log any serial port exceptions or connection errors to the status diagnostics console.

---

### [Component 2] Background Isolate Timer in `billiard_desktop`

We will offload elapsed play time calculations and ticks from the main UI thread to a background Isolate to ensure a constant 60fps+ frame rate.

#### [NEW] [timer_isolate.dart](file:///Users/hieukona/Downloads/app/billiard_pos/apps/billiard_desktop/lib/src/utils/timer_isolate.dart)
- Implement `timerIsolateEntryPoint(SendPort mainSendPort)` which sets up a bidirectional communication channel.
- Accept command messages: `start` (registers a table ID with start time), `stop` (removes table ID), and `clear`.
- Use a background `Timer.periodic(const Duration(seconds: 1))` to calculate duration for all active tables.
- Send ticks containing `{tableId: elapsedSeconds}` back to the main UI thread.

---

### [Component 3] Desktop POS Application Refactoring & Features

We will refactor the massive `main.dart` and build modular components for the UI, adding the POS features required.

#### [NEW] [table_card.dart](file:///Users/hieukona/Downloads/app/billiard_pos/apps/billiard_desktop/lib/src/widgets/table_card.dart)
- Individual card for each table.
- Implement minimalist Scandinavian design with subtle hover micro-animations.
- Use distinct background/border states: Idle (white/grey), Active (soft teal/blue), Maintenance (soft red/pink).
- Display elapsed time (from Isolate ticks) and current play cost real-time calculations.

#### [NEW] [table_grid.dart](file:///Users/hieukona/Downloads/app/billiard_pos/apps/billiard_desktop/lib/src/widgets/table_grid.dart)
- Grid layout displaying tables.
- Add Search text field to filter tables by name.
- Add Filter buttons to filter tables by type (Pool, Carom, Snooker) and status (Idle, Active).

#### [NEW] [order_dialog.dart](file:///Users/hieukona/Downloads/app/billiard_pos/apps/billiard_desktop/lib/src/widgets/order_dialog.dart)
- Dialogue to select from food/beverage products.
- Allow configuring order quantities and add items directly to an active table's services.

#### [NEW] [receipt_preview_dialog.dart](file:///Users/hieukona/Downloads/app/billiard_pos/apps/billiard_desktop/lib/src/widgets/receipt_preview_dialog.dart)
- Monospace K80 receipt preview showing billiard club information, play times, ordered products, subtotal, and total amount.
- Style the dialogue to resemble an authentic thermal receipt paper.

#### [NEW] [shift_dialog.dart](file:///Users/hieukona/Downloads/app/billiard_pos/apps/billiard_desktop/lib/src/widgets/shift_dialog.dart)
- Operational cashier dashboard.
- Display initial cash, hourly play revenues, product revenues, payment breakdown.
- Prompt user to enter actual cash in drawer to automatically calculate discrepancy, write closing note, and close current shift.

#### [MODIFY] [main.dart](file:///Users/hieukona/Downloads/app/billiard_pos/apps/billiard_desktop/lib/main.dart)
- Clean up to initialize the background Timer Isolate.
- Maintain states: Active Shift (from `ShiftModel`), List of all Tables, Table IoT Configurations, Table Start Times, Table Current Orders (product lists), Isolate Durations.
- Render the main Scaffold using the new modular widgets: `TableGrid`, `ControlPanel`, diagnostics `ConsolePanel`.
- Support launching `OrderDialog`, `ReceiptPreviewDialog`, and `ShiftDialog`.

---

## Verification Plan

### Automated Tests
- Run `flutter test` to ensure that models, UI components, and the background isolate function correctly.
- Add unit tests for the background Isolate timer to verify ticks, starts, and stops.

### Manual Verification
1. Run `billiard_desktop` locally.
2. Turn on tables, verify that the elapsed time is calculated using the background Isolate tick updates.
3. Add multiple beverages (Sting, Coca, Red Bull) and food items to an active table, verify details update instantly.
4. Turn off a table, view the K80 thermal print preview, and complete billing.
5. Click "Đóng ca" (Close Shift) to verify revenues, cash drawer math, cash discrepancy calculation, and closing transactions.
