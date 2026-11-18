import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_delivery_application/core/constants/app_constants.dart';
import 'package:hive/hive.dart';

/// Persists and toggles Light/Dark [ThemeMode] in Hive `settings_box`.
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit({required Box<dynamic> settingsBox})
    : _settingsBox = settingsBox,
      super(_readSavedThemeMode(settingsBox));

  final Box<dynamic> _settingsBox;

  bool get isDarkMode => state == ThemeMode.dark;

  static ThemeMode _readSavedThemeMode(Box<dynamic> box) {
    final stored = box.get(AppConstants.themeModeKey);
    if (stored == 'dark') return ThemeMode.dark;
    return ThemeMode.light;
  }

  Future<void> toggleTheme() async {
    final nextMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(nextMode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    emit(mode);
    try {
      await _settingsBox.put(
        AppConstants.themeModeKey,
        mode == ThemeMode.dark ? 'dark' : 'light',
      );
    } catch (_) {
      // UI theme change still succeeds even if local write fails.
    }
  }
}
