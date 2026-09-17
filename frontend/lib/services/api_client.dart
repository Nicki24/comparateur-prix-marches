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
    final reponse = await http
        .get(_uri(chemin, query), headers: _headers(token: token))
        .timeout(_timeout);
    return _verifier(reponse);
  }

  Future<dynamic> post(String chemin, Map<String, dynamic> corps) async {
    final reponse = await http
        .post(
          _uri(chemin),
          headers: _headers(),
          body: jsonEncode(corps),
        )
        .timeout(_timeout);
    return _verifier(reponse);
  }

  Future<dynamic> put(String chemin, Map<String, dynamic> corps) async {
    final reponse = await http
        .put(
          _uri(chemin),
          headers: _headers(),
          body: jsonEncode(corps),
        )
        .timeout(_timeout);
    return _verifier(reponse);
  }

  Future<dynamic> delete(String chemin) async {
    final reponse = await http
        .delete(_uri(chemin), headers: _headers())
        .timeout(_timeout);
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