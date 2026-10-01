import 'package:intl/intl.dart';

final _nombreFr = NumberFormat.decimalPattern('fr');

/// Formatage des prix en Ariary, arrondis à l'unité (« 3 010 Ar »).
///
/// L'Ariary ne s'utilise pas avec des décimales : les moyennes calculées
/// (ex. 3 310,56) sont arrondies pour rester lisibles.
String formaterPrix(num valeur) {
  return '${_nombreFr.format(valeur.round())} Ar';
}

/// Formatage d'un nombre entier en français (ex. « 1 234 »).
String formaterNombre(num valeur) {
  return _nombreFr.format(valeur.round());
}

/// Formatage d'un pourcentage signé (ex. « +2,0 % », « −0,5 % », « 0,0 % »).
String formaterPourcentage(double pct) {
  final signe = pct.abs() < 0.05 ? '' : (pct < 0 ? '−' : '+');
  return '$signe${pct.abs().toStringAsFixed(1).replaceAll('.', ',')} %';
}

/// Formatage d'une date en français.
String formaterDate(DateTime date) {
  return DateFormat('dd/MM/yyyy', 'fr').format(date);
}

/// Formatage d'une date courte (ex. « 08/09 »).
String formaterDateCourte(DateTime date) {
  return DateFormat('dd/MM', 'fr').format(date);
}

/// Formatage d'une date lisible (ex. « 17 sept. »).
String formaterDateLisible(DateTime date) {
  return DateFormat('d MMM', 'fr').format(date);
}

/// Formatage d'une heure (ex. « 14:32 »).
String formaterHeure(DateTime date) {
  return DateFormat('HH:mm', 'fr').format(date);
}

/// Nom de marché sans le préfixe « Marché » (ex. « Andranomena »), pour
/// les espaces étroits : axes de graphiques, bandeau, puces.
String nomCourtMarche(String nom) {
  final court = nom.trim().replaceFirst(RegExp(r'^march[ée]\s+', caseSensitive: false), '');
  return court.isEmpty ? nom : court;
}

/// Nom de produit sans l'unité entre parenthèses
/// (« Riz local (kilo) » → « Riz local »).
String nomCourtProduit(String nom) {
  final court = nom.replaceFirst(RegExp(r'\s*\([^)]*\)\s*$'), '').trim();
  return court.isEmpty ? nom : court;
}
