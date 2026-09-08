import '../models/comparaison.dart';
import '../models/historique_point.dart';
import 'api_client.dart';

class ComparisonService {
  /// Comparaison du dernier prix par marché pour un produit.
  static Future<Comparaison> comparer(int produitId) async {
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