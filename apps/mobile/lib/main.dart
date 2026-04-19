import 'package:bvc_common/bvc_common.dart';
import 'package:bvc_network/bvc_network.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/app_auth_guard.dart';
import 'app/app_module.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
    applyMobileDotenv(
      apiBaseUrl: dotenv.env['API_BASE_URL'],
      environment: dotenv.env['ENVIRONMENT'],
      useMock: dotenv.env['USE_MOCK'],
    );
  } catch (_) {}
  ensureVietnamTimeZonesInitialized();

  final container = ProviderContainer();
  appProviderContainer = container;

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: ModularApp(module: AppModule(), child: const App()),
    ),
  );
}
