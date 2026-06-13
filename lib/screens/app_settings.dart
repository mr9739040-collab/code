import 'package:flutter/material.dart';

class AppSettings extends ChangeNotifier {
  /// 🌙 THEME
  bool _isDark = true;
  bool get isDark => _isDark;

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }

  /// 🌐 LANGUAGE
  String _language = "English";
  String get language => _language;

  void toggleLanguage() {
    _language = _language == "English" ? "Hindi" : "English";
    notifyListeners();
  }
}
