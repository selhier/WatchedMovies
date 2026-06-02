import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

/// Provider to access SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

/// State notifier for the app language
class LanguageNotifier extends Notifier<String> {
  static const _langKey = 'app_language';

  @override
  String build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getString(_langKey) ?? 'en-US'; // Default to English
  }

  /// Toggles between English and Spanish
  Future<void> toggleLanguage(BuildContext context) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final newLang = state == 'en-US' ? 'es-ES' : 'en-US';
    await prefs.setString(_langKey, newLang);
    state = newLang;
    
    // Change easy_localization locale
    if (newLang == 'es-ES') {
      context.setLocale(const Locale('es', 'ES'));
    } else {
      context.setLocale(const Locale('en', 'US'));
    }
  }
}

final languageProvider = NotifierProvider<LanguageNotifier, String>(() {
  return LanguageNotifier();
});
