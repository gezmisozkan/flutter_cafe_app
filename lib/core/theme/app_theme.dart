import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final appThemeProvider = Provider<ThemeData>((ref) {
  const brand = Colors.brown;
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: brand),
    useMaterial3: true,
    brightness: Brightness.light,
  );
});

final appDarkThemeProvider = Provider<ThemeData>((ref) {
  const brand = Colors.brown;
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: brand,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    brightness: Brightness.dark,
  );
});
