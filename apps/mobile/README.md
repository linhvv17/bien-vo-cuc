# bien_vo_cuc

A new Flutter project.

## Android máy thật (Debug) – đúng cấu hình dự án này

### Cách 1: Android Studio (khuyên dùng)
- Chọn Run Configuration: **`main.dart (Android device + adb reverse)`**
- Trước khi bấm Run/Debug, chạy:

```bash
adb reverse tcp:3001 tcp:3001
```

### Cách 2: CLI

```bash
adb reverse tcp:3001 tcp:3001
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:3001
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
