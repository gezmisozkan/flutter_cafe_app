import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final brandColorProvider = Provider<Color>((ref) => Colors.brown);

TextTheme _textTheme(TextTheme base) {
  return base.copyWith(
    titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    headlineSmall: base.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
  );
}

final appThemeProvider = Provider<ThemeData>((ref) {
  final brand = ref.watch(brandColorProvider);
  final scheme = ColorScheme.fromSeed(
    seedColor: brand,
    brightness: Brightness.light,
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: scheme.background,
    textTheme: _textTheme(ThemeData.light().textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(40, 40),
        shape: const StadiumBorder(),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
});

final appDarkThemeProvider = Provider<ThemeData>((ref) {
  final brand = ref.watch(brandColorProvider);
  final scheme = ColorScheme.fromSeed(
    seedColor: brand,
    brightness: Brightness.dark,
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: scheme.background,
    textTheme: _textTheme(ThemeData.dark().textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(40, 40),
        shape: const StadiumBorder(),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
});
