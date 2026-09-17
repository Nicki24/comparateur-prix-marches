import '../models/user.dart';
import 'api_client.dart';
import 'session.dart';

class AuthService {
  /// Connexion : retourne le jeton d'accès.
  static Future<String> login({required String email, required String password}) async {
    final data = await ApiClient.instance.post('/login', {
      'email': email,
      'password': password,
    }) as Map<String, dynamic>;

    return data['token'] as String;
  }

  /// Inscription d'un contributeur : retourne le jeton d'accès.
  static Future<String> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final data = await ApiClient.instance.post('/register', {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
    }) as Map<String, dynamic>;

    return data['token'] as String;
  }

  /// Récupère l'utilisateur authentifié (token explicit ou session en cours).
  static Future<User> utilisateurCourant({String? token}) async {
    final data =
        await ApiClient.instance.get('/user', null, token) as Map<String, dynamic>;
    final userData = data['data'] is Map<String, dynamic>
        ? data['data'] as Map<String, dynamic>
        : data;
    return User.fromJson(userData);
  }

  /// Déconnecte côté serveur (le jeton courant est révoqué).
  static Future<void> deconnexion() async {
    if (Session.instance.token != null) {
      try {
        await ApiClient.instance.post('/logout', {});
      } catch (_) {
        // On déconnecte localement même si le serveur est injoignable.
      }
    }
  }
}