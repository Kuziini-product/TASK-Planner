import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

// ── Accent color options ──
class AccentColorOption {
  final String name;
  final Color color;

  const AccentColorOption(this.name, this.color);
}

const List<AccentColorOption> accentColorOptions = [
  AccentColorOption('Teal', Color(0xFF0D7377)),
  AccentColorOption('Blue', Color(0xFF2196F3)),
  AccentColorOption('Purple', Color(0xFF9C27B0)),
  AccentColorOption('Indigo', Color(0xFF3F51B5)),
  AccentColorOption('Pink', Color(0xFFE91E63)),
  AccentColorOption('Red', Color(0xFFF44336)),
  AccentColorOption('Orange', Color(0xFFFF9800)),
  AccentColorOption('Green', Color(0xFF4CAF50)),
  AccentColorOption('Amber', Color(0xFFFFC107)),
  AccentColorOption('Cyan', Color(0xFF00BCD4)),
  AccentColorOption('Violet', Color(0xFF7C3AED)),
  AccentColorOption('Emerald', Color(0xFF059669)),
  AccentColorOption('Slate', Color(0xFF94A3B8)),
];

// ── Theme Mode Provider ──
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(AppConstants.prefThemeMode);
    if (themeIndex != null && themeIndex < ThemeMode.values.length) {
      state = ThemeMode.values[themeIndex];
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.prefThemeMode, mode.index);
  }

  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(newMode);
  }

  bool get isDark => state == ThemeMode.dark;
}

// ── Primary Color Provider ──
final primaryColorProvider =
    StateNotifierProvider<PrimaryColorNotifier, Color>(
  (ref) => PrimaryColorNotifier(),
);

class PrimaryColorNotifier extends StateNotifier<Color> {
  PrimaryColorNotifier() : super(accentColorOptions.first.color) {
    _loadColor();
  }

  Future<void> _loadColor() async {
    final prefs = await SharedPreferences.getInstance();
    final r = prefs.getInt('${AppConstants.prefAccentColor}_r');
    final g = prefs.getInt('${AppConstants.prefAccentColor}_g');
    final b = prefs.getInt('${AppConstants.prefAccentColor}_b');
    if (r != null && g != null && b != null) {
      state = Color.fromARGB(255, r, g, b);
    }
  }

  Future<void> setColor(Color color) async {
    state = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${AppConstants.prefAccentColor}_r', color.red.toInt());
    await prefs.setInt('${AppConstants.prefAccentColor}_g', color.green.toInt());
    await prefs.setInt('${AppConstants.prefAccentColor}_b', color.blue.toInt());
  }
}
