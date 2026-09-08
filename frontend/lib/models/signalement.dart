import 'releve_prix.dart';

class Signalement {
  const Signalement({
    required this.id,
    required this.releveId,
    required this.typeAnomalie,
    required this.dateDetection,
    this.releve,
  });

  final int id;
  final int releveId;
  final String typeAnomalie;
  final DateTime dateDetection;
  final RelevePrix? releve;

  String get libelleType {
    return typeAnomalie == 'prix_anormal' ? 'Prix anormal' : 'Prix obsolète';
  }

  factory Signalement.fromJson(Map<String, dynamic> json) {
    return Signalement(
      id: json['id'] as int,
      releveId: json['releve_id'] as int,
      typeAnomalie: json['type_anomalie'] as String? ?? '',
      dateDetection: DateTime.parse(json['date_detection'] as String),
      releve: json['releve'] is Map<String, dynamic>
          ? RelevePrix.fromJson(json['releve'] as Map<String, dynamic>)
          : null,
    );
  }
}