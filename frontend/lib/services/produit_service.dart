import '../models/produit.dart';
import 'api_client.dart';

class ProduitService {
  /// Liste des produits actifs (ou tous si [tout] = true — admin).
  static Future<List<Produit>> lister({bool tout = false}) async {
    final data =
        await ApiClient.instance.get('/produits', {if (tout) 'tout': '1'})
            as Map<String, dynamic>;

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
    final data =
        await ApiClient.instance.post('/produits', {
              'nom': nom,
              'unite_mesure': uniteMesure,
              'categorie': categorie,
            })
            as Map<String, dynamic>;

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
    final data =
        await ApiClient.instance.put('/produits/$id', {
              'nom': nom,
              'unite_mesure': uniteMesure,
              'categorie': categorie,
            })
            as Map<String, dynamic>;

    final produitData = data['data'] is Map<String, dynamic>
        ? data['data'] as Map<String, dynamic>
        : data;
    return Produit.fromJson(produitData);
  }

  /// Réactive un produit désactivé (admin, suppression logique inverse).
  static Future<void> reactiver(int id) async {
    await ApiClient.instance.put('/produits/$id', {'actif': true});
  }

  /// Supprime définitivement un produit sans historique (admin).
  ///
  /// L'API répond 409 ([ApiException.statusCode]) si des relevés y sont
  /// rattachés : il faut alors le désactiver ou le fusionner.
  static Future<String> supprimerDefinitivement(int id) async {
    final data =
        await ApiClient.instance.delete('/produits/$id/definitif')
            as Map<String, dynamic>?;
    return data?['message'] as String? ?? 'Élément supprimé.';
  }

  /// Fusionne le doublon [id] dans [cibleId] : ses relevés sont déplacés
  /// puis le doublon est supprimé (admin).
  static Future<String> fusionner(int id, {required int cibleId}) async {
    final data =
        await ApiClient.instance.post('/produits/$id/fusionner', {
              'cible_id': cibleId,
            })
            as Map<String, dynamic>?;
    return data?['message'] as String? ?? 'Éléments fusionnés.';
  }
}
