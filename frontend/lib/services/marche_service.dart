import '../models/marche.dart';
import 'api_client.dart';

class MarcheService {
  /// Liste des marchés actifs (ou tous si [tout] = true).
  static Future<List<Marche>> lister({bool tout = false}) async {
    final data = await ApiClient.instance.get('/marches', {
      if (tout) 'tout': '1',
    }) as Map<String, dynamic>;

    return (data['data'] as List<dynamic>)
        .map((e) => Marche.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Crée un marché (admin).
  static Future<Marche> creer({
    required String nom,
    required String localisation,
    String? description,
  }) async {
    final data = await ApiClient.instance.post('/marches', {
      'nom': nom,
      'localisation': localisation,
      'description': description,
    }) as Map<String, dynamic>;

    final marcheData = data['data'] is Map<String, dynamic>
        ? data['data'] as Map<String, dynamic>
        : data;
    return Marche.fromJson(marcheData);
  }

  /// Désactive un marché (admin, suppression logique).
  static Future<void> desactiver(int id) async {
    await ApiClient.instance.delete('/marches/$id');
  }

  /// Modifie un marché (admin).
  static Future<Marche> modifier({
    required int id,
    required String nom,
    required String localisation,
    String? description,
  }) async {
    final data = await ApiClient.instance.put('/marches/$id', {
      'nom': nom,
      'localisation': localisation,
      'description': description,
    }) as Map<String, dynamic>;

    final marcheData = data['data'] is Map<String, dynamic>
        ? data['data'] as Map<String, dynamic>
        : data;
    return Marche.fromJson(marcheData);
  }

  /// Réactive un marché désactivé (admin, suppression logique inverse).
  static Future<void> reactiver(int id) async {
    await ApiClient.instance.put('/marches/$id', {'actif': true});
  }
}