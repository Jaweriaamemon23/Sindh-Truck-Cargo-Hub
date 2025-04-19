import 'package:flutter/material.dart';

class LanguageProvider with ChangeNotifier {
  Locale _locale = Locale('en', ''); // Default language is English

  Locale get locale => _locale;

  // Method to change the language
  void changeLanguage(Locale newLocale) {
    _locale = newLocale;
    notifyListeners(); // Notify listeners (the app will rebuild)
  }
}
