import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'session.dart';

/// Exception applicative levée lors d'une erreur d'API.
class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => message;
}

/// Client HTTP centralisé : URL de base, token Bearer et gestion d'erreurs.
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  static const _timeout = Duration(seconds: 20);

  Uri _uri(String chemin, [Map<String, dynamic>? query]) {
    final base = ApiConfig.baseUrl.endsWith('/')
        ? ApiConfig.baseUrl
        : '${ApiConfig.baseUrl}/';
    final cheminNettoye = chemin.replaceFirst(RegExp(r'^/+'), '');
    return Uri.parse('$base$cheminNettoye').replace(
      queryParameters: query?.map((k, v) => MapEntry(k, '$v')),
    );
  }

  Map<String, String> _headers({bool json = true, String? token}) {
    final headers = <String, String>{};
    if (json) {
      headers['Accept'] = 'application/json';
      headers['Content-Type'] = 'application/json';
    }
    final jeton = token ?? Session.instance.token;
    if (jeton != null) {
      headers['Authorization'] = 'Bearer $jeton';
    }
    return headers;
  }

  static dynamic _decoder(String corps) {
    if (corps.isEmpty) {
      return null;
    }
    return jsonDecode(corps);
  }

  Future<dynamic> get(
    String chemin, [
    Map<String, dynamic>? query,
    String? token,
  ]) async {
    return _executer(() =>
        http.get(_uri(chemin, query), headers: _headers(token: token)));
  }

  Future<dynamic> post(String chemin, Map<String, dynamic> corps) async {
    return _executer(() => http.post(
          _uri(chemin),
          headers: _headers(),
          body: jsonEncode(corps),
        ));
  }

  Future<dynamic> put(String chemin, Map<String, dynamic> corps) async {
    return _executer(() => http.put(
          _uri(chemin),
          headers: _headers(),
          body: jsonEncode(corps),
        ));
  }

  Future<dynamic> delete(String chemin) async {
    return _executer(() => http.delete(_uri(chemin), headers: _headers()));
  }

  /// Exécute la requête et convertit les échecs réseau (serveur éteint,
  /// pas de connexion, délai dépassé) en [ApiException] lisible.
  Future<dynamic> _executer(Future<http.Response> Function() requete) async {
    final http.Response reponse;
    try {
      reponse = await requete().timeout(_timeout);
    } on TimeoutException {
      throw const ApiException(
          0, 'Le serveur met trop de temps à répondre. Réessayez.');
    } on http.ClientException {
      throw const ApiException(0,
          'Serveur injoignable. Vérifiez votre connexion internet puis réessayez.');
    }
    return _verifier(reponse);
  }

  dynamic _verifier(http.Response reponse) {
    final decode = _decoder(reponse.body);
    if (reponse.statusCode >= 200 && reponse.statusCode < 300) {
      return decode;
    }

    var message = 'Erreur serveur (${reponse.statusCode}).';
    if (decode is Map<String, dynamic>) {
      if (decode['message'] is String) {
        message = decode['message'] as String;
      }
      final erreurs = decode['errors'];
      if (erreurs is Map<String, dynamic> && erreurs.isNotEmpty) {
        message = erreurs.values
            .expand((e) => e as List<dynamic>)
            .map((e) => '$e')
            .join('\n');
      }
    }

    throw ApiException(reponse.statusCode, message);
  }
}