class HistoriquePoint {
  const HistoriquePoint({
    required this.date,
    required this.valeur,
  });

  final DateTime date;
  final double valeur;

  factory HistoriquePoint.fromJson(Map<String, dynamic> json) {
    return HistoriquePoint(
      date:
          json['date'] is String ? DateTime.parse(json['date'] as String) : DateTime.now(),
      valeur: (json['valeur'] as num).toDouble(),
    );
  }
}