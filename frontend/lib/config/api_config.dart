import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;

/// Configuration de l'API REST Laravel.
///
/// * Version de production (`flutter build apk`) : serveur Wasmer.
/// * Développement (`flutter run`) : serveur Laravel local.
/// * Pour forcer une autre adresse :
///   flutter run --dart-define=API_URL=https://api.exemple.fr/api
class ApiConfig {
  ApiConfig._();

  /// API en ligne (Wasmer Edge).
  static const urlProduction = 'https://marketscope-api.wasmer.app/api';

  /// URL de base de l'API (sans slash final).
  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_URL');
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }
    if (kReleaseMode) {
      return urlProduction;
    }
    // L'émulateur Android accède à la machine hôte via 10.0.2.2.
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api';
    }
    return 'http://localhost:8000/api';
  }
}