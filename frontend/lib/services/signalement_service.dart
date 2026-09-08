import '../models/signalement.dart';
import 'api_client.dart';

class SignalementService {
  /// Liste des signalements d'anomalies (admin).
  static Future<List<Signalement>> lister() async {
    final data = await ApiClient.instance
        .get('/signalements') as Map<String, dynamic>;

    return (data['data'] as List<dynamic>)
        .map((e) => Signalement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Déclenche manuellement la détection des prix obsolètes (admin).
  static Future<int> detecterObsoletes() async {
    final data = await ApiClient.instance
        .post('/signalements/detecter-obsoletes', {}) as Map<String, dynamic>;

    return (data['nombre_signalements'] as num?)?.toInt() ?? 0;
  }
}