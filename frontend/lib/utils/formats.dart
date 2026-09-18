import 'package:intl/intl.dart';

/// Formatage des prix en Ariary, style français.
String formaterPrix(num valeur, {bool avecUnite = true}) {
  final nf = NumberFormat.decimalPattern('fr');
  return '${nf.format(valeur)} Ar${avecUnite ? '' : ''}';
}

/// Formatage d'un nombre entier en français (ex. « 1 234 »).
String formaterNombre(num valeur) {
  final nf = NumberFormat.decimalPattern('fr');
  return nf.format(valeur.round());
}

/// Formatage d'une date en français.
String formaterDate(DateTime date) {
  return DateFormat('dd/MM/yyyy', 'fr').format(date);
}

/// Formatage d'une date courte (ex. « 08/09 »).
String formaterDateCourte(DateTime date) {
  return DateFormat('dd/MM', 'fr').format(date);
}

/// Formatage d'une heure (ex. « 14:32 »).
String formaterHeure(DateTime date) {
  return DateFormat('HH:mm', 'fr').format(date);
}