import 'package:latlong2/latlong.dart';

class Marche {
  const Marche({
    required this.id,
    required this.nom,
    required this.localisation,
    this.quartier,
    this.latitude,
    this.longitude,
    this.description,
    required this.actif,
  });

  final int id;
  final String nom;
  final String localisation;
  final String? quartier;

  /// Coordonnées GPS posées par l'administrateur sur la carte (facultatives).
  final double? latitude;
  final double? longitude;
  final String? description;
  final bool actif;

  /// « Quartier, Ville » si le quartier est connu, sinon la ville seule.
  String get adresse {
    final q = quartier?.trim() ?? '';
    return q.isEmpty ? localisation : '$q, $localisation';
  }

  /// Point sur la carte, ou null si le marché n'a pas encore été placé.
  LatLng? get position => latitude != null && longitude != null
      ? LatLng(latitude!, longitude!)
      : null;

  factory Marche.fromJson(Map<String, dynamic> json) {
    return Marche(
      id: json['id'] as int,
      nom: json['nom'] as String? ?? '',
      localisation: json['localisation'] as String? ?? '',
      quartier: json['quartier'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      description: json['description'] as String?,
      actif: json['actif'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'localisation': localisation,
      'quartier': quartier,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'actif': actif,
    };
  }
}
