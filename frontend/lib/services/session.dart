import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import 'auth_service.dart';

/// Session locale : conserve le jeton Sanctum et l'utilisateur courant.
/// Notifie tous les auditeurs à chaque changement de connexion.
class Session extends ChangeNotifier {
  Session._() {
    _restaurer();
  }

  static final Session instance = Session._();

  static const _cleToken = 'auth_token';
  static const _cleUser = 'auth_user';

  String? _token;
  User? _user;

  String? get token => _token;
  User? get user => _user;
  bool get estConnecte => _token != null && _user != null;

  /// Restaure la session depuis le stockage local.
  Future<void> _restaurer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_cleToken);
      final userJson = prefs.getString(_cleUser);
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

  Future<void> _persister() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null && _user != null) {
      await prefs.setString(_cleToken, _token!);
      await prefs.setString(_cleUser, jsonEncode(_user!.toJson()));
    } else {
      await prefs.remove(_cleToken);
      await prefs.remove(_cleUser);
    }
  }

  /// Enregistre la session après connexion / inscription.
  Future<void> connecter(String token, User user) async {
    _token = token;
    _user = user;
    await _persister();
    notifyListeners();
  }

  /// Déconnecte en supprimant aussi le jeton côté serveur (si possible).
  Future<void> deconnecter() async {
    await AuthService.deconnexion();
    _token = null;
    _user = null;
    await _persister();
    notifyListeners();
  }
}

extension UserJson on User {
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'email': email, 'role': role};
  }
}