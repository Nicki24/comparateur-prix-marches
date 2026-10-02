import 'package:flutter/foundation.dart';

import 'api_client.dart';

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

  List<MessageAssistant> get messages => List.unmodifiable(_messages);
  bool get enAttente => _enAttente;

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

    final historique = _messages
        .where((m) => !m.erreur)
        .map((m) => {
              'role': m.auteur == AuteurMessage.utilisateur ? 'user' : 'assistant',
              'content': m.texte,
            })
        .toList();
    final aEnvoyer = historique.length > _historiqueMax
        ? historique.sublist(historique.length - _historiqueMax)
        : historique;

    try {
      final data = await ApiClient.instance.post(
        '/assistant',
        {'messages': aEnvoyer},
        timeout: _delai,
      );
      final reponse = data is Map<String, dynamic> ? data['reponse'] : null;
      _messages.add(MessageAssistant(
        AuteurMessage.assistant,
        reponse is String && reponse.trim().isNotEmpty
            ? reponse.trim()
            : 'Je n’ai pas su répondre. Pouvez-vous reformuler ?',
      ));
    } on ApiException catch (e) {
      _messages.add(MessageAssistant(AuteurMessage.assistant, e.message, erreur: true));
    } catch (_) {
      _messages.add(const MessageAssistant(
        AuteurMessage.assistant,
        'Une erreur inattendue est survenue. Réessayez.',
        erreur: true,
      ));
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
