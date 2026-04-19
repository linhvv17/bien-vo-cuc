import 'package:bvc_ui/bvc_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_modular/flutter_modular.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Biển Vô Cực',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        final mq = MediaQuery.of(context);
        final userFactor = mq.textScaler.scale(1.0);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: TextScaler.linear(userFactor * 1.1),
          ),
          child: child,
        );
      },
      locale: const Locale('vi', 'VN'),
      supportedLocales: const [
        Locale('vi', 'VN'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: Modular.routerConfig,
    );
  }
}
