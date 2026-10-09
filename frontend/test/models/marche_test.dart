import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:comparateur_prix_app/models/marche.dart';

void main() {
  group(Marche, () {
    group('fromJson', () {
      test('lit le quartier et la position GPS', () {
        final marche = Marche.fromJson(const {
          'id': 1,
          'nom': 'Marché test',
          'localisation': 'Ville',
          'quartier': 'Quartier A',
          'latitude': -23.35,
          'longitude': 43,
          'actif': true,
        });

        expect(marche.position, equals(const LatLng(-23.35, 43)));
        expect(marche.adresse, equals('Quartier A, Ville'));
      });

      test('returns null position when the market is not placed yet', () {
        final marche = Marche.fromJson(const {
          'id': 2,
          'nom': 'Sans GPS',
          'localisation': 'Ville',
          'latitude': null,
          'longitude': null,
        });

        expect(marche.position, isNull);
        expect(marche.adresse, equals('Ville'));
      });
    });
  });
}
