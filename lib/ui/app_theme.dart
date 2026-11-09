import 'dart:io';

import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF0B7A75),
      ink = Color(0xFF0F2A33),
      secondary = Color(0xFF3B7D1E);
  static const background = Color(0xFFF4FAF9),
      surface = Color(0xFFFFFFFF),
      border = Color(0xFFD7E6E3),
      outline = Color(0xFF7F9C97);
  static const muted = Color(0xFF4A6370),
      danger = Color(0xFFB3261E),
      warning = Color(0xFF8A5A00);
}

/// Bảng màu "chợ trái cây": mỗi loại dữ liệu một màu.
/// - strong: chữ và nút (tương phản >= 4.5:1 với trắng)
/// - line: nét biểu đồ (>= 3:1 với trắng)
/// - tint: nền nhạt của thẻ
/// - glow: màu tươi dùng trang trí
class Hue {
  const Hue({
    required this.strong,
    required this.line,
    required this.tint,
    required this.glow,
  });
  final Color strong, line, tint, glow;

  static const leaf = Hue(
    strong: Color(0xFF0B7A75),
    line: Color(0xFF0E9488),
    tint: Color(0xFFE0F3F1),
    glow: Color(0xFF2EC4B6),
  );
  static const mango = Hue(
    strong: Color(0xFF9A5B00),
    line: Color(0xFFD98200),
    tint: Color(0xFFFFF1D2),
    glow: Color(0xFFFFB020),
  );
  static const dragon = Hue(
    strong: Color(0xFFB8215A),
    line: Color(0xFFD6336C),
    tint: Color(0xFFFCE5EF),
    glow: Color(0xFFFF5C9A),
  );
  static const melon = Hue(
    strong: Color(0xFFC1352B),
    line: Color(0xFFE5483D),
    tint: Color(0xFFFFE6E2),
    glow: Color(0xFFFF7A6B),
  );
  static const lime = Hue(
    strong: Color(0xFF3B7D1E),
    line: Color(0xFF4C9A2A),
    tint: Color(0xFFE6F4D9),
    glow: Color(0xFF8CD14F),
  );
}

/// Đổi màu nhấn của một nhánh giao diện (nút, chip, thanh điều hướng, công tắc...).
ThemeData themeWithHue(ThemeData base, Hue hue) => base.copyWith(
  colorScheme: base.colorScheme.copyWith(
    primary: hue.strong,
    onPrimary: Colors.white,
    primaryContainer: hue.tint,
    onPrimaryContainer: hue.strong,
    secondaryContainer: hue.tint,
    onSecondaryContainer: hue.strong,
  ),
  textSelectionTheme: TextSelectionThemeData(
    cursorColor: hue.strong,
    selectionColor: hue.glow.withValues(alpha: 0.35),
    selectionHandleColor: hue.strong,
  ),
);

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
    primary: Hue.leaf.strong,
    onPrimary: Colors.white,
    primaryContainer: Hue.leaf.tint,
    onPrimaryContainer: Hue.leaf.strong,
    secondary: AppColors.secondary,
    secondaryContainer: Hue.leaf.tint,
    onSecondaryContainer: Hue.leaf.strong,
    surface: AppColors.surface,
    onSurface: AppColors.ink,
    onSurfaceVariant: AppColors.muted,
    outline: AppColors.outline,
    outlineVariant: AppColors.border,
    error: AppColors.danger,
    surfaceTint: Colors.transparent,
  );
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: Platform.isWindows ? 'Segoe UI' : 'Roboto',
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
  );
  const tabular = [FontFeature.tabularFigures()];
  return base.copyWith(
    textTheme: base.textTheme
        .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink)
        .copyWith(
          headlineMedium: base.textTheme.headlineMedium?.copyWith(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            height: 1.15,
            letterSpacing: -0.4,
            color: AppColors.ink,
          ),
          titleLarge: base.textTheme.titleLarge?.copyWith(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
          titleMedium: base.textTheme.titleMedium?.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
          titleSmall: base.textTheme.titleSmall?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            fontFeatures: tabular,
          ),
          labelLarge: base.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontFeatures: tabular,
          ),
          bodyLarge: base.textTheme.bodyLarge?.copyWith(
            height: 1.45,
            fontFeatures: tabular,
          ),
          bodyMedium: base.textTheme.bodyMedium?.copyWith(
            fontSize: 15,
            height: 1.45,
            fontFeatures: tabular,
          ),
        ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
      },
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.ink,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: Hue.leaf.strong,
      selectionColor: Hue.leaf.glow.withValues(alpha: 0.35),
      selectionHandleColor: Hue.leaf.strong,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surface,
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thickness: const WidgetStatePropertyAll(7),
      radius: const Radius.circular(6),
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.hovered)
            ? AppColors.muted
            : AppColors.muted.withValues(alpha: 0.5),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      height: 70,
      elevation: 0,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w600,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: AppColors.surface,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      selectedLabelTextStyle: const TextStyle(fontWeight: FontWeight.w800),
      unselectedLabelTextStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
