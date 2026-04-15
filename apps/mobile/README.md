# bien_vo_cuc

A new Flutter project.

## Chạy theo môi trường (dev/uat/prod)

Dự án có sẵn `.env.dev`, `.env.uat`, `.env.prod` (đang ignore git). Script sẽ đọc file tương ứng và truyền qua `--dart-define` để đảm bảo **Release/Production chạy đúng env** mà không cần đổi file `.env`.

Yêu cầu: có file `.env.<env>` trong thư mục `apps/mobile/` (copy từ `.env.example` rồi sửa giá trị).

### Cách 1: Makefile (nhanh nhất)

```bash
make run-prod
```

Build production:

```bash
make build-apk-prod
make build-aab-prod
make build-ios-prod
```

### Cách 2: Script trực tiếp

```bash
./tool/run_env.sh prod run
./tool/run_env.sh prod run-release
./tool/run_env.sh prod build-apk
./tool/run_env.sh prod build-appbundle
./tool/run_env.sh prod build-ios
```

### Cách 3: Tự chạy bằng `flutter` (không cần file env)

```bash
flutter run --release \
  --dart-define=API_BASE_URL=https://api.bienvocuc.vn \
  --dart-define=ENVIRONMENT=production \
  --dart-define=USE_MOCK=false
```

### Cách 4: Run Configurations (Cursor/VSCode)

Đã tạo sẵn `apps/mobile/.vscode/launch.json` với các cấu hình:
- `Mobile (dev)`
- `Mobile (uat)`
- `Mobile (production)`
- `Mobile (production, release mode)`

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
