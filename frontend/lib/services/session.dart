import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import 'auth_service.dart';

/// Session locale : conserve le jeton Sanctum et l'utilisateur courant.
/// Notifie tous les auditeurs à chaque changement de connexion.
///
/// Jeton et profil (e-mail) sont des données sensibles : ils vivent dans le
/// stockage chiffré (Keystore Android / Keychain iOS / WebCrypto), jamais
/// dans SharedPreferences qui est en clair.
class Session extends ChangeNotifier {
  Session._() {
    _restaurer();
  }

  static final Session instance = Session._();

  static const _cleToken = 'auth_token';
  static const _cleUser = 'auth_user';

  static const _stockage = FlutterSecureStorage();

  String? _token;
  User? _user;

  String? get token => _token;
  User? get user => _user;
  bool get estConnecte => _token != null && _user != null;

  /// Alerte « session expirée » à afficher par le widget racine.
  /// [versionExpiration] change à chaque nouvelle expiration pour que
  /// l'alerte ne s'affiche qu'une fois, même si plusieurs requêtes échouent
  /// en même temps avec un 401.
  String? messageExpiration;
  int versionExpiration = 0;

  /// Restaure la session depuis le stockage chiffré.
  Future<void> _restaurer() async {
    try {
      await _migrerAnciennesPreferences();
      final token = await _stockage.read(key: _cleToken);
      final userJson = await _stockage.read(key: _cleUser);
      if (token != null && userJson != null) {
        _token = token;
        _user = User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
        notifyListeners();
      }
    } catch (_) {
      _token = null;
      _user = null;
    }
  }

  /// Les versions précédentes stockaient la session en clair dans
  /// SharedPreferences : on la déplace une fois puis on efface l'ancienne.
  Future<void> _migrerAnciennesPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final ancienToken = prefs.getString(_cleToken);
    final ancienUser = prefs.getString(_cleUser);
    if (ancienToken == null && ancienUser == null) {
      return;
    }
    if (ancienToken != null && ancienUser != null) {
      await _stockage.write(key: _cleToken, value: ancienToken);
      await _stockage.write(key: _cleUser, value: ancienUser);
    }
    await prefs.remove(_cleToken);
    await prefs.remove(_cleUser);
  }

  Future<void> _persister() async {
    try {
      if (_token != null && _user != null) {
        await _stockage.write(key: _cleToken, value: _token);
        await _stockage.write(
          key: _cleUser,
          value: jsonEncode(_user!.toJson()),
        );
      } else {
        await _stockage.delete(key: _cleToken);
        await _stockage.delete(key: _cleUser);
      }
    } catch (_) {
      // Stockage indisponible : la session reste valable en mémoire.
    }
  }

  /// Enregistre la session après connexion / inscription.
  Future<void> connecter(String token, User user) async {
    _token = token;
    _user = user;
    messageExpiration = null;
    await _persister();
    notifyListeners();
  }

  /// Déconnecte en supprimant aussi le jeton côté serveur (si possible).
  Future<void> deconnecter() async {
    await AuthService.deconnexion();
    _token = null;
    _user = null;
    messageExpiration = null;
    await _persister();
    notifyListeners();
  }

  /// Le jeton n'est plus reconnu par l'API (401) : on vide la session
  /// localement sans rappeler /logout (qui renverrait un nouveau 401).
  Future<void> expirer() async {
    final etaitConnecte = estConnecte;
    _token = null;
    _user = null;
    await _persister();
    if (etaitConnecte) {
      messageExpiration =
          'Votre session a expiré. Veuillez vous reconnecter.';
      versionExpiration++;
    }
    notifyListeners();
  }

  /// L'alerte ayant été affichée, on évite de la rejouer sur un rebuild.
  void effacerAlerteExpiration() {
    messageExpiration = null;
  }
}

extension UserJson on User {
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'email': email, 'role': role};
  }
}
