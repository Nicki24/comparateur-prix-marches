import '../models/comparaison.dart';
import '../models/historique_point.dart';
import 'api_client.dart';

class ComparisonService {
  /// Durée pendant laquelle une comparaison déjà chargée est réutilisée.
  static const _dureeCache = Duration(minutes: 2);

  /// Cache mémoire : le bandeau, l'accueil et la liste des produits
  /// demandent les mêmes comparaisons au démarrage. La requête en cours
  /// est partagée, ce qui évite de solliciter l'API plusieurs fois.
  static final _cache = <int, ({DateTime date, Future<Comparaison> futur})>{};

  /// Comparaison du dernier prix par marché pour un produit.
  ///
  /// [forcer] ignore le cache (tirer pour rafraîchir).
  static Future<Comparaison> comparer(int produitId, {bool forcer = false}) {
    final enCache = _cache[produitId];
    if (!forcer &&
        enCache != null &&
        DateTime.now().difference(enCache.date) < _dureeCache) {
      return enCache.futur;
    }
    final futur = _charger(produitId);
    _cache[produitId] = (date: DateTime.now(), futur: futur);
    // Une erreur ne doit pas rester en cache (l'appelant la reçoit quand même).
    futur.then<void>((_) {}, onError: (Object _) => _cache.remove(produitId));
    return futur;
  }

  static Future<Comparaison> _charger(int produitId) async {
    final data = await ApiClient.instance
        .get('/produits/$produitId/comparaison') as Map<String, dynamic>;
    return Comparaison.fromJson(data);
  }

  /// Historique d'évolution du prix (moyenne, min ou max selon [mode]).
  static Future<List<HistoriquePoint>> historique(
    int produitId, {
    String mode = 'moyenne',
    int? marcheId,
  }) async {
    final data = await ApiClient.instance.get('/produits/$produitId/historique', {
      'mode': mode,
      if (marcheId != null) 'marche_id': '$marcheId',
    }) as Map<String, dynamic>;

    return (data['points'] as List<dynamic>)
        .map((e) => HistoriquePoint.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
