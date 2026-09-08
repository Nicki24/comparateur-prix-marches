class Marche {
  const Marche({
    required this.id,
    required this.nom,
    required this.localisation,
    this.description,
    required this.actif,
  });

  final int id;
  final String nom;
  final String localisation;
  final String? description;
  final bool actif;

  factory Marche.fromJson(Map<String, dynamic> json) {
    return Marche(
      id: json['id'] as int,
      nom: json['nom'] as String? ?? '',
      localisation: json['localisation'] as String? ?? '',
      description: json['description'] as String?,
      actif: json['actif'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'localisation': localisation,
      'description': description,
      'actif': actif,
    };
  }
}