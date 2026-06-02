import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/app.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/providers/language_provider.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  
  try {
    await dotenv.load(fileName: "env");
  } catch (_) {
    // On web, dotenv may fail to load — fallback values in ApiConstants handle this
  }

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyCcA1HNnVTQGyhoZXCutQo4mD7Mau6toQo',
      appId: '1:228661932314:web:0d33e6c0c29f864e',
      messagingSenderId: '000000000000',
      projectId: 'watchedmovies-394dc',
      storageBucket: 'watchedmovies-394dc.appspot.com',
      authDomain: 'watchedmovies-394dc.firebaseapp.com',
    ),
  );

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en', 'US'), Locale('es', 'ES')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en', 'US'),
      child: ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const WatchedMoviesApp(),
      ),
    ),
  );
}
