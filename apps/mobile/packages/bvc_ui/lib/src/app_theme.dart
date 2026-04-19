import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF0A1628); // --background
  static const foreground = Color(0xFFEDF0F5); // --foreground
  static const card = Color(0xFF111D30); // --card
  static const surface = Color(0xFF172438); // --surface
  static const primary = Color(0xFFE8A817); // --primary (gold)
  static const secondary = Color(0xFF1BB5BB); // --secondary (ocean teal)
  static const muted = Color(0xFF222D42); // --muted
  static const mutedForeground = Color(0xFF7C8A9E); // --muted-foreground
  static const border = Color(0xFF293044); // --border
  static const destructive = Color(0xFFDF2020); // --destructive
  static const success = Color(0xFF20B268); // --success
  static const warning = Color(0xFFF5A503); // --warning
  static const goldGlow = Color(0xFFFFC533); // --gold-glow
  static const oceanDeep = Color(0xFF0D3366); // --ocean-deep
  static const oceanLight = Color(0xFF26B3CC); // --ocean-light
}

class AppRadii {
  static const sm = 8.0;
  static const md = 10.0;
  static const base = 12.0;
  static const xl = 16.0;
  static const x2l = 20.0;
}

class AppShadows {
  // Approximations of the HSL shadows in design-system.md
  static const card = <BoxShadow>[
    BoxShadow(
      color: Color(0x800A1628), // background @ ~0.5
      blurRadius: 16,
      spreadRadius: -2,
      offset: Offset(0, 4),
    ),
  ];

  static const gold = <BoxShadow>[
    BoxShadow(
      color: Color(0x33E8A817), // primary @ ~0.2
      blurRadius: 24,
      spreadRadius: -4,
      offset: Offset(0, 4),
    ),
  ];
}

ThemeData buildAppTheme() {
  const cs = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primary,
    onPrimary: Color(0xFF0A1628),
    secondary: AppColors.secondary,
    onSecondary: AppColors.background,
    error: AppColors.destructive,
    onError: AppColors.foreground,
    surface: AppColors.surface,
    onSurface: AppColors.foreground,
  );

  final textTheme = const TextTheme().apply(
    bodyColor: AppColors.foreground,
    displayColor: AppColors.foreground,
  ).copyWith(
    titleLarge: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.2),
    titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.35),
    titleSmall: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.3),
    bodyLarge: const TextStyle(fontSize: 17, fontWeight: FontWeight.w400, height: 1.45),
    bodyMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5),
    bodySmall: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.4),
    labelLarge: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.2),
    labelMedium: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.25),
    labelSmall: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.25, letterSpacing: 0.35),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: cs,
    scaffoldBackgroundColor: AppColors.background,
    textTheme: textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.foreground,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.xl)),
    ),
    dividerTheme: DividerThemeData(color: AppColors.border.withValues(alpha: 0.55)),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.base)),
        ),
        textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.05)),
      ),
    ),
  );
}

