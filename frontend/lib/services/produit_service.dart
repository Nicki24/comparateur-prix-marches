import '../models/produit.dart';
import 'api_client.dart';

class ProduitService {
  /// Liste des produits actifs (ou tous si [tout] = true — admin).
  static Future<List<Produit>> lister({bool tout = false}) async {
    final data = await ApiClient.instance.get('/produits', {
      if (tout) 'tout': '1',
    }) as Map<String, dynamic>;

    return (data['data'] as List<dynamic>)
        .map((e) => Produit.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Crée un produit (admin).
  static Future<Produit> creer({
    required String nom,
    required String uniteMesure,
    String? categorie,
  }) async {
    final data = await ApiClient.instance.post('/produits', {
      'nom': nom,
      'unite_mesure': uniteMesure,
      'categorie': categorie,
    }) as Map<String, dynamic>;

    final produitData = data['data'] is Map<String, dynamic>
        ? data['data'] as Map<String, dynamic>
        : data;
    return Produit.fromJson(produitData);
  }

  /// Désactive un produit (admin, suppression logique).
  static Future<void> desactiver(int id) async {
    await ApiClient.instance.delete('/produits/$id');
  }

  /// Modifie un produit (admin).
  static Future<Produit> modifier({
    required int id,
    required String nom,
    required String uniteMesure,
    String? categorie,
  }) async {
    final data = await ApiClient.instance.put('/produits/$id', {
      'nom': nom,
      'unite_mesure': uniteMesure,
      'categorie': categorie,
    }) as Map<String, dynamic>;

    final produitData = data['data'] is Map<String, dynamic>
        ? data['data'] as Map<String, dynamic>
        : data;
    return Produit.fromJson(produitData);
  }

  /// Réactive un produit désactivé (admin, suppression logique inverse).
  static Future<void> reactiver(int id) async {
    await ApiClient.instance.put('/produits/$id', {'actif': true});
  }
}