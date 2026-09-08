class Produit {
  const Produit({
    required this.id,
    required this.nom,
    required this.uniteMesure,
    this.categorie,
    required this.actif,
  });

  final int id;
  final String nom;
  final String uniteMesure;
  final String? categorie;
  final bool actif;

  factory Produit.fromJson(Map<String, dynamic> json) {
    return Produit(
      id: json['id'] as int,
      nom: json['nom'] as String? ?? '',
      uniteMesure: json['unite_mesure'] as String? ?? '',
      categorie: json['categorie'] as String?,
      actif: json['actif'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'unite_mesure': uniteMesure,
      'categorie': categorie,
      'actif': actif,
    };
  }
}