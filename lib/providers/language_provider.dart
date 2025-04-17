import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  bool _isSindhi = false;

  bool get isSindhi => _isSindhi;

  void toggleLanguage() {
    _isSindhi = !_isSindhi;
    notifyListeners();
  }
}
