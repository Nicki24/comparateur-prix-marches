import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Configuration de l'API REST Laravel.
///
/// Pour changer l'adresse au lancement :
///   flutter run --dart-define=API_URL=https://api.exemple.fr/api
class ApiConfig {
  ApiConfig._();

  /// URL de base de l'API (sans slash final).
  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_URL');
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }
    // L'émulateur Android accède à la machine hôte via 10.0.2.2.
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api';
    }
    return 'http://localhost:8000/api';
  }
}