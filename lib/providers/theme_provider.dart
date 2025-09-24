import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemePreference { system, light, dark }

class ThemeProvider with ChangeNotifier {
  ThemePreference _themePreference = ThemePreference.system;
  late SharedPreferences _prefs;
  
  ThemeProvider() {
    _loadPreferences();
    _startTimeBasedThemeUpdate();
  }

  ThemePreference get themePreference => _themePreference;

  ThemeMode get themeMode {
    switch (_themePreference) {
      case ThemePreference.light:
        return ThemeMode.light;
      case ThemePreference.dark:
        return ThemeMode.dark;
      case ThemePreference.system:
        return _getTimeBasedTheme();
    }
  }

  bool get isDarkMode {
    switch (_themePreference) {
      case ThemePreference.light:
        return false;
      case ThemePreference.dark:
        return true;
      case ThemePreference.system:
        return _isNightTime();
    }
  }

  void setThemePreference(ThemePreference preference) async {
    _themePreference = preference;
    await _prefs.setInt('theme_preference', preference.index);
    notifyListeners();
  }

  ThemeMode _getTimeBasedTheme() {
    return _isNightTime() ? ThemeMode.dark : ThemeMode.light;
  }

  bool _isNightTime() {
    final now = DateTime.now();
    final hour = now.hour;
    // Night time: 6 PM to 6 AM (18:00 to 06:00)
    return hour >= 18 || hour < 6;
  }

  void _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    final themeIndex = _prefs.getInt('theme_preference') ?? ThemePreference.system.index;
    _themePreference = ThemePreference.values[themeIndex];
    notifyListeners();
  }

  void _startTimeBasedThemeUpdate() {
    // Check every minute if we need to update theme
    Stream.periodic(Duration(minutes: 1)).listen((_) {
      if (_themePreference == ThemePreference.system) {
        notifyListeners();
      }
    });
  }

  String getThemeDescription() {
    switch (_themePreference) {
      case ThemePreference.system:
        return "Auto (${_isNightTime() ? 'Dark' : 'Light'})";
      case ThemePreference.light:
        return "Light";
      case ThemePreference.dark:
        return "Dark";
    }
  }
}