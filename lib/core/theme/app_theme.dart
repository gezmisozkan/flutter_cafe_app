import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// Primary brand seed color (modern cafe teal).
final brandColorProvider = Provider<Color>((ref) => const Color(0xFF0E7C66));

TextTheme _textTheme(TextTheme base) {
  return base.copyWith(
    titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    headlineSmall: base.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
    labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
  );
}

AppBarTheme _appBarTheme(ColorScheme scheme) {
  return AppBarTheme(
    backgroundColor: scheme.surface,
    foregroundColor: scheme.onSurface,
    elevation: 0,
    scrolledUnderElevation: 0,
    surfaceTintColor: scheme.surfaceTint,
    centerTitle: true,
  );
}

InputDecorationTheme _inputTheme(ColorScheme scheme) {
  const borderRadius = BorderRadius.all(Radius.circular(12));
  OutlineInputBorder outline(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderSide: BorderSide(color: color, width: width),
        borderRadius: borderRadius,
      );
  return InputDecorationTheme(
    isDense: true,
    filled: true,
    fillColor: scheme.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: outline(scheme.outlineVariant),
    enabledBorder: outline(scheme.outlineVariant),
    focusedBorder: outline(scheme.primary, 2),
    errorBorder: outline(scheme.error),
    focusedErrorBorder: outline(scheme.error, 2),
  );
}

CardThemeData _cardTheme(ColorScheme scheme) {
  return CardThemeData(
    color: scheme.surface,
    elevation: 0,
    surfaceTintColor: scheme.surfaceTint,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.all(0),
  );
}

NavigationBarThemeData _navBarTheme(ColorScheme scheme) {
  return NavigationBarThemeData(
    backgroundColor: scheme.surface,
    indicatorColor: scheme.secondaryContainer,
    iconTheme: MaterialStateProperty.resolveWith((states) {
      final color = states.contains(WidgetState.selected)
          ? scheme.onSecondaryContainer
          : scheme.onSurfaceVariant;
      return IconThemeData(color: color);
    }),
    labelTextStyle: MaterialStateProperty.resolveWith((states) {
      final color = states.contains(WidgetState.selected)
          ? scheme.onSecondaryContainer
          : scheme.onSurfaceVariant;
      final weight = states.contains(WidgetState.selected)
          ? FontWeight.w600
          : FontWeight.w500;
      return TextStyle(color: color, fontWeight: weight);
    }),
  );
}

SnackBarThemeData _snackBarTheme(ColorScheme scheme) {
  return SnackBarThemeData(
    backgroundColor: scheme.inverseSurface,
    contentTextStyle: TextStyle(color: scheme.onInverseSurface),
    actionTextColor: scheme.tertiary,
    behavior: SnackBarBehavior.floating,
    elevation: 6,
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
    visualDensity: VisualDensity.adaptivePlatformDensity,
    scaffoldBackgroundColor: scheme.background,
    textTheme: _textTheme(ThemeData.light().textTheme),
    appBarTheme: _appBarTheme(scheme),
    cardTheme: _cardTheme(scheme),
    inputDecorationTheme: _inputTheme(scheme),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: const StadiumBorder(),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: const StadiumBorder(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        side: BorderSide(color: scheme.outline),
        shape: const StadiumBorder(),
      ),
    ),
    chipTheme: ChipThemeData(
      side: BorderSide(color: scheme.outlineVariant),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      selectedColor: scheme.secondaryContainer,
      backgroundColor: scheme.surface,
      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
    ),
    navigationBarTheme: _navBarTheme(scheme),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1),
    snackBarTheme: _snackBarTheme(scheme),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: scheme.surfaceTint,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
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
    visualDensity: VisualDensity.adaptivePlatformDensity,
    scaffoldBackgroundColor: scheme.background,
    textTheme: _textTheme(ThemeData.dark().textTheme),
    appBarTheme: _appBarTheme(scheme),
    cardTheme: _cardTheme(scheme),
    inputDecorationTheme: _inputTheme(scheme),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: const StadiumBorder(),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: const StadiumBorder(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        side: BorderSide(color: scheme.outline),
        shape: const StadiumBorder(),
      ),
    ),
    chipTheme: ChipThemeData(
      side: BorderSide(color: scheme.outlineVariant),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      selectedColor: scheme.secondaryContainer,
      backgroundColor: scheme.surface,
      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
    ),
    navigationBarTheme: _navBarTheme(scheme),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1),
    snackBarTheme: _snackBarTheme(scheme),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: scheme.surfaceTint,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),
  );
});
