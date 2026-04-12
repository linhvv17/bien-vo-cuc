import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFE8834A),
      brightness: Brightness.dark,
      surface: const Color(0xFF1A2D3E),
    ),
    scaffoldBackgroundColor: const Color(0xFF0D1B2A),
    cardTheme: CardThemeData(
      color: const Color(0xFF1A2D3E),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}

