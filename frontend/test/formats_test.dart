import 'package:comparateur_prix_app/utils/formats.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  test('formaterPrix arrondit à l’Ariary et sépare les milliers', () {
    final prix = formaterPrix(3310.56);
    // Espace insécable (fine) de la locale française entre les milliers.
    expect(prix.replaceAll(RegExp(r'\s'), ' '), '3 311 Ar');
  });

  test('formaterPourcentage : signe, virgule et état stable', () {
    expect(formaterPourcentage(2), '+2,0 %');
    expect(formaterPourcentage(-0.54), '−0,5 %');
    expect(formaterPourcentage(0.01), '0,0 %');
  });

  test('nomCourtMarche retire le préfixe « Marché »', () {
    expect(nomCourtMarche('Marché Andranomena'), 'Andranomena');
    expect(nomCourtMarche('marche Ankijabe'), 'Ankijabe');
    expect(nomCourtMarche('Bazar Be'), 'Bazar Be');
  });

  test('nomCourtProduit retire l’unité entre parenthèses', () {
    expect(nomCourtProduit('Riz local (kilo)'), 'Riz local');
    expect(nomCourtProduit('Savon'), 'Savon');
  });
}
