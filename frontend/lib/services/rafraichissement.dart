import 'package:flutter/foundation.dart';

/// Signal global de changement des données métier.
///
/// Toute opération qui modifie les données (marché, produit, relevé,
/// signalement) incrémente [version] et notifie ses auditeurs. Les écrans
/// conservés en mémoire (navigation par onglets) écoutent ce notifieur pour
/// se recharger automatiquement : l'utilisateur n'a plus besoin de tirer
/// pour rafraîchir en revenant sur un onglet.
class Rafraichissement extends ChangeNotifier {
  Rafraichissement._();

  static final Rafraichissement instance = Rafraichissement._();

  int _version = 0;

  /// Numéro de la dernière modification connue. Sert aussi de clé de
  /// validité aux caches mémoire (comparaisons de prix).
  int get version => _version;

  /// À appeler après chaque écriture réussie côté API.
  void signaler() {
    _version++;
    notifyListeners();
  }
}
