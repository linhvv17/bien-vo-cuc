import 'dart:io';

import 'package:flutter/foundation.dart';

/// Override when running:
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.5:3001
const String kApiBaseUrlDefine = String.fromEnvironment('API_BASE_URL', defaultValue: '');

/// Override when running:
/// flutter run --dart-define=ENVIRONMENT=production
const String kEnvironmentDefine = String.fromEnvironment('ENVIRONMENT', defaultValue: '');

/// Override when running:
/// flutter run --dart-define=USE_MOCK=false
const String kUseMockDefine = String.fromEnvironment('USE_MOCK', defaultValue: '');

/// Mặc định: khu bãi Biển Vô Cực — khớp [BEACH_LAT]/[BEACH_LNG] trên API (`apps/api`).
/// Địa danh: Xã Thụy Xuân, Huyện Thái Thụy, Tỉnh Thái Bình.
/// Override khi cần:
/// flutter run --dart-define=BEACH_LAT=20.5774021 --dart-define=BEACH_LNG=106.6192557
const String kBeachLatDefine = String.fromEnvironment('BEACH_LAT', defaultValue: '20.5774021');
const String kBeachLngDefine = String.fromEnvironment('BEACH_LNG', defaultValue: '106.6192557');

double get kBeachLat => double.tryParse(kBeachLatDefine) ?? 20.5774021;
double get kBeachLng => double.tryParse(kBeachLngDefine) ?? 106.6192557;

String? _dotenvApiBaseUrl;
String? _dotenvEnvironment;
String? _dotenvUseMock;

/// Gọi sau `dotenv.load` trong `main.dart` (flutter_dotenv).
void applyMobileDotenv({
  String? apiBaseUrl,
  String? environment,
  String? useMock,
}) {
  _dotenvApiBaseUrl = apiBaseUrl?.trim();
  if (_dotenvApiBaseUrl?.isEmpty ?? false) _dotenvApiBaseUrl = null;
  _dotenvEnvironment = environment?.trim();
  if (_dotenvEnvironment?.isEmpty ?? false) _dotenvEnvironment = null;
  _dotenvUseMock = useMock?.trim();
  if (_dotenvUseMock?.isEmpty ?? false) _dotenvUseMock = null;
}

/// Từ `apps/mobile/.env`, sau [applyMobileDotenv].
String get kAppEnvironment {
  if (kEnvironmentDefine.isNotEmpty) return kEnvironmentDefine;
  return _dotenvEnvironment ?? 'development';
}

/// `true` khi `.env` có `USE_MOCK=true`.
bool get kUseMockFromEnv {
  if (kUseMockDefine.isNotEmpty) return kUseMockDefine.toLowerCase() == 'true';
  return _dotenvUseMock?.toLowerCase() == 'true';
}

String _normalizeApiBaseUrl(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return s;

  try {
    final uri = Uri.parse(s);
    if (!uri.hasScheme || uri.host.isEmpty) return s;

    // Base URL should be origin only; strip any path/query/fragment to avoid
    // accidental values like ".../weather/forecast".
    // Use `null` (not empty string) to avoid trailing `?` / `#` in `.toString()`.
    final normalized = uri.replace(path: '', query: null, fragment: null).toString();
    // `Uri.replace(path: '')` may keep a trailing slash depending on input;
    // keep it as-is because Dio handles both variants.
    return normalized;
  } catch (_) {
    return s;
  }
}

String resolveApiBaseUrl() {
  if (kApiBaseUrlDefine.isNotEmpty) return _normalizeApiBaseUrl(kApiBaseUrlDefine);
  final fromDot = _dotenvApiBaseUrl;
  if (fromDot != null && fromDot.isNotEmpty) return _normalizeApiBaseUrl(fromDot);
  if (kIsWeb) return 'http://localhost:3001';
  // Android máy thật: dùng adb reverse -> http://127.0.0.1:3001
  // Android emulator: override bằng --dart-define=API_BASE_URL=http://10.0.2.2:3001
  // iOS máy thật: --dart-define=API_BASE_URL=http://<IP-LAN-máy-chạy-API>:3001
  if (Platform.isAndroid) return 'http://127.0.0.1:3001';
  return 'http://127.0.0.1:3001';
}

