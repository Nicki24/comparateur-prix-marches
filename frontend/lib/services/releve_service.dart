import '../models/releve_prix.dart';
import 'api_client.dart';

class ReleveService {
  /// Soumet un relevé de prix (contributeur authentifié).
  ///
  /// Retourne le relevé créé (statut éventuellement « signale » si
  /// le prix a été détecté comme anormal).
  static Future<RelevePrix> creer({
    required int produitId,
    required int marcheId,
    required double valeur,
    required DateTime dateReleve,
    String? commentaire,
  }) async {
    final data = await ApiClient.instance.post('/releves', {
      'produit_id': produitId,
      'marche_id': marcheId,
      'valeur': valeur,
      'date_releve': dateReleve.toIso8601String().substring(0, 10),
      'commentaire': commentaire,
    }) as Map<String, dynamic>;

    final releveData = data['data'] is Map<String, dynamic>
        ? data['data'] as Map<String, dynamic>
        : data;
    return RelevePrix.fromJson(releveData);
  }

  /// Historique personnel : les relevés de l'utilisateur connecté.
  static Future<List<RelevePrix>> mesReleves() async =>
      (await mesRelevesAvecTotal()).releves;

  /// Les 100 relevés les plus récents de l'utilisateur, avec le nombre
  /// total réel (métadonnée de pagination : peut dépasser 100).
  static Future<({List<RelevePrix> releves, int total})>
      mesRelevesAvecTotal() async {
    final data = await ApiClient.instance.get('/mes-releves', {
      'per_page': '100',
    }) as Map<String, dynamic>;

    final items = data['data'] is List<dynamic>
        ? data['data'] as List<dynamic>
        : data['data']?['data'] as List<dynamic>;
    final releves = items
        .map((e) => RelevePrix.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = data['meta'];
    final total = meta is Map<String, dynamic> && meta['total'] is num
        ? (meta['total'] as num).toInt()
        : releves.length;
    return (releves: releves, total: total);
  }

  /// Historique des relevés par produit (filtrable par marché).
  static Future<List<RelevePrix>> lister({
    int? produitId,
    int? marcheId,
  }) async {
    final data = await ApiClient.instance.get('/releves', {
      if (produitId != null) 'produit_id': '$produitId',
      if (marcheId != null) 'marche_id': '$marcheId',
      'per_page': '100',
    }) as Map<String, dynamic>;

    final items = data['data'] is List<dynamic>
        ? data['data'] as List<dynamic>
        : data['data']?['data'] as List<dynamic>;
    return items
        .map((e) => RelevePrix.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}