import 'package:flutter/material.dart';

/// 量潮品牌蓝
const Color kPrimaryColor = Color(0xFF15608F);

/// 构建量潮执行云应用主题
ThemeData buildTheme() {
  final ColorScheme scheme = ColorScheme.fromSeed(seedColor: kPrimaryColor);
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
    ),
  );
}
