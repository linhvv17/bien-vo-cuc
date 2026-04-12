import 'package:bvc_common/bvc_common.dart';
import 'package:bvc_network/bvc_network.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
    applyMobileDotenv(
      apiBaseUrl: dotenv.env['API_BASE_URL'],
      environment: dotenv.env['ENVIRONMENT'],
      useMock: dotenv.env['USE_MOCK'],
    );
  } catch (_) {
    // Không có `.env` (copy từ `.env.example`) — vẫn dùng dart-define / mặc định trong bvc_network.
  }
  ensureVietnamTimeZonesInitialized();
  runApp(const ProviderScope(child: App()));
}

