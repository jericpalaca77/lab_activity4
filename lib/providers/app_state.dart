import 'package:flutter/material.dart';

/// Global app state: Dark/Light theme and the user's profile name.
class AppState extends ChangeNotifier {
  bool _isDark = false;
  String _userName = 'Student';

  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;
  String get themeLabel => _isDark ? 'Dark' : 'Light';
  String get userName => _userName.trim().isEmpty ? 'Student' : _userName.trim();

  void setDark(bool value) {
    _isDark = value;
    notifyListeners();
  }

  void setUserName(String value) {
    _userName = value;
    notifyListeners();
  }
}
