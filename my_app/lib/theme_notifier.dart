import 'package:flutter/material.dart';

// ValueNotifier giúp thông báo cho toàn bộ App khi giá trị thay đổi
class ThemeNotifier {
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.dark);

  static void toggleTheme(bool isDark) {
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }
}