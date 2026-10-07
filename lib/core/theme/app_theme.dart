import 'package:flutter/material.dart';

/// Thème Material 3 léger pour le scaffold (à peaufiner plus tard).
abstract final class AppTheme {
  static const _seed = Color(0xFF2F5D50);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: scheme.secondaryContainer,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}
