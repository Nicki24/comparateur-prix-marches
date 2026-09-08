import 'marche.dart';
import 'produit.dart';

class PrixParMarche {
  const PrixParMarche({
    required this.marche,
    required this.dernierPrix,
    this.dateDernierReleve,
    required this.nbReleves,
    this.ecartPourcentage,
  });

  final Marche marche;
  final double? dernierPrix;
  final String? dateDernierReleve;
  final int nbReleves;
  final double? ecartPourcentage;

  factory PrixParMarche.fromJson(Map<String, dynamic> json) {
    return PrixParMarche(
      marche: Marche.fromJson(json['marche'] as Map<String, dynamic>),
      dernierPrix: _nombre(json['dernier_prix']),
      dateDernierReleve: json['date_dernier_releve'] as String?,
      nbReleves: (json['nb_releves'] as num?)?.toInt() ?? 0,
      ecartPourcentage: _nombre(json['ecart_pourcentage']),
    );
  }
}

/// Convertit une valeur JSON (num ou chaîne « 3200.00 ») en double.
double? _nombre(Object? valeur) {
  if (valeur == null) {
    return null;
  }
  if (valeur is num) {
    return valeur.toDouble();
  }
  return double.tryParse(valeur.toString());
}

class Comparaison {
  const Comparaison({
    required this.produit,
    required this.prixMinimum,
    required this.prixParMarche,
  });

  final Produit produit;
  final double? prixMinimum;
  final List<PrixParMarche> prixParMarche;

  factory Comparaison.fromJson(Map<String, dynamic> json) {
    return Comparaison(
      produit: Produit.fromJson(json['produit'] as Map<String, dynamic>),
      prixMinimum: _nombre(json['prix_minimum']),
      prixParMarche: (json['prix_par_marche'] as List<dynamic>? ?? [])
          .map((e) => PrixParMarche.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}