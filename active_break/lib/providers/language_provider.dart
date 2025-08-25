import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  static const String _languageKey = 'language_code';
  
  Locale _locale = const Locale('en', 'US');
  
  Locale get locale => _locale;
  
  bool get isEnglish => _locale.languageCode == 'en';
  bool get isChinese => _locale.languageCode == 'zh';

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey) ?? 'en';
    _locale = languageCode == 'en' ? const Locale('en', 'US') : const Locale('zh', 'CN');
    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    _locale = languageCode == 'en' ? const Locale('en', 'US') : const Locale('zh', 'CN');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
    notifyListeners();
  }

  // Supported locales
  static const List<Locale> supportedLocales = [
    Locale('zh', 'CN'),
    Locale('en', 'US'),
  ];
}
