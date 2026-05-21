# Billiard POS Monorepo Workspace

This is the monorepo workspace for the Billiard POS System, containing desktop and mobile applications, as well as shared packages.

## Structure

- `apps/`
  - `billiard_desktop/`: Desktop cash register client (Windows/macOS/Linux) with IoT integration.
  - `billiard_pos_mobile/`: Mobile POS order app for waiters (Android/iOS).
  - `billiard_manager_mobile/`: Mobile management dashboard for club managers (Android/iOS).
- `packages/`
  - `core_shared/`: Shared database entities/models, API clients, and business logic.
  - `iot_controller/`: Serial COM and TCP/IP LAN relay drivers with simulation capabilities.

## Getting Started

To get all dependencies for all workspace members:

```bash
flutter pub get
```

To run the desktop app:

```bash
cd apps/billiard_desktop
flutter run -d macos # or windows / linux
```
