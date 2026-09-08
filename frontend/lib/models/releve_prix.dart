import 'produit.dart';
import 'marche.dart';

class RelevePrix {
  const RelevePrix({
    required this.id,
    required this.valeur,
    required this.dateReleve,
    required this.statut,
    this.commentaire,
    this.produit,
    this.marche,
  });

  final int id;
  final double valeur;
  final DateTime dateReleve;
  final String statut;
  final String? commentaire;
  final Produit? produit;
  final Marche? marche;

  bool get estSignale => statut == 'signale';

  factory RelevePrix.fromJson(Map<String, dynamic> json) {
    return RelevePrix(
      id: json['id'] as int,
      valeur: (json['valeur'] as num).toDouble(),
      dateReleve: json['date_releve'] is String
          ? DateTime.parse(json['date_releve'] as String)
          : DateTime.now(),
      statut: json['statut'] as String? ?? 'valide',
      commentaire: json['commentaire'] as String?,
      produit: json['produit'] is Map<String, dynamic>
          ? Produit.fromJson(json['produit'] as Map<String, dynamic>)
          : null,
      marche: json['marche'] is Map<String, dynamic>
          ? Marche.fromJson(json['marche'] as Map<String, dynamic>)
          : null,
    );
  }
}