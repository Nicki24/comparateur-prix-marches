import 'package:flutter/foundation.dart';

import 'package:latlong2/latlong.dart';

import 'api_client.dart';
import 'localisation_service.dart';

enum AuteurMessage { utilisateur, assistant }

@immutable
class MessageAssistant {
  const MessageAssistant(this.auteur, this.texte, {this.erreur = false});

  final AuteurMessage auteur;
  final String texte;

  /// Message d'erreur affiché localement (jamais renvoyé à l'IA).
  final bool erreur;
}

/// Conversation avec l'assistant IA (endpoint `/assistant`).
///
/// Singleton : la discussion survit à la fermeture de la bulle, jusqu'à
/// « Nouvelle conversation » ou au redémarrage de l'app.
class ConversationAssistant extends ChangeNotifier {
  ConversationAssistant._();

  static final ConversationAssistant instance = ConversationAssistant._();

  /// Le backend accepte au plus 20 messages : on n'envoie que les derniers.
  static const _historiqueMax = 20;

  /// Plusieurs allers-retours avec l'IA côté serveur : délai généreux.
  static const _delai = Duration(seconds: 90);

  final List<MessageAssistant> _messages = [];
  bool _enAttente = false;

  /// L'utilisateur a choisi de partager sa position (bouton 📍).
  bool _partagePosition = false;
  bool _localisationEnCours = false;
  LatLng? _position;

  List<MessageAssistant> get messages => List.unmodifiable(_messages);
  bool get enAttente => _enAttente;
  bool get partagePosition => _partagePosition;
  bool get localisationEnCours => _localisationEnCours;

  /// Active ou coupe le partage de position. À l'activation, la position
  /// est lue tout de suite pour demander l'autorisation au bon moment.
  /// Renvoie un message d'erreur à afficher, ou null si tout va bien.
  Future<String?> basculerPartagePosition() async {
    if (_partagePosition) {
      _partagePosition = false;
      _position = null;
      notifyListeners();
      return null;
    }
    return _actualiserPosition();
  }

  Future<String?> _actualiserPosition() async {
    _localisationEnCours = true;
    notifyListeners();
    try {
      _position = await LocalisationService.positionActuelle();
      _partagePosition = true;
      return null;
    } on LocalisationException catch (e) {
      _partagePosition = false;
      _position = null;
      return e.message;
    } finally {
      _localisationEnCours = false;
      notifyListeners();
    }
  }

  Future<void> envoyer(String texte) async {
    final question = texte.trim();
    if (question.isEmpty || _enAttente) return;

    _messages.add(MessageAssistant(AuteurMessage.utilisateur, question));
    await _demander();
  }

  /// Renvoie la dernière question après une erreur.
  Future<void> reessayer() async {
    if (_enAttente || _messages.isEmpty || !_messages.last.erreur) return;
    _messages.removeLast();
    await _demander();
  }

  Future<void> _demander() async {
    _enAttente = true;
    notifyListeners();

    // Position rafraîchie à chaque question (l'utilisateur se déplace) ;
    // en cas d'échec on garde la dernière connue.
    if (_partagePosition) {
      try {
        _position = await LocalisationService.positionActuelle();
      } on LocalisationException {
        // Dernière position conservée.
      }
    }

    final historique = _messages
        .where((m) => !m.erreur)
        .map(
          (m) => {
            'role': m.auteur == AuteurMessage.utilisateur
                ? 'user'
                : 'assistant',
            'content': m.texte,
          },
        )
        .toList();
    final aEnvoyer = historique.length > _historiqueMax
        ? historique.sublist(historique.length - _historiqueMax)
        : historique;

    try {
      final data = await ApiClient.instance.post('/assistant', {
        'messages': aEnvoyer,
        if (_partagePosition && _position != null)
          'position': {
            'latitude': _position!.latitude,
            'longitude': _position!.longitude,
          },
      }, timeout: _delai);
      final reponse = data is Map<String, dynamic> ? data['reponse'] : null;
      _messages.add(
        MessageAssistant(
          AuteurMessage.assistant,
          reponse is String && reponse.trim().isNotEmpty
              ? reponse.trim()
              : 'Je n’ai pas su répondre. Pouvez-vous reformuler ?',
        ),
      );
    } on ApiException catch (e) {
      _messages.add(
        MessageAssistant(AuteurMessage.assistant, e.message, erreur: true),
      );
    } catch (_) {
      _messages.add(
        const MessageAssistant(
          AuteurMessage.assistant,
          'Une erreur inattendue est survenue. Réessayez.',
          erreur: true,
        ),
      );
    }

    _enAttente = false;
    notifyListeners();
  }

  void reinitialiser() {
    if (_enAttente) return;
    _messages.clear();
    notifyListeners();
  }
}
