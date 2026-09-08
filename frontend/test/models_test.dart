// Vérifie le décodage des modèles à partir des réponses JSON réelles de l'API.

import 'package:flutter_test/flutter_test.dart';

import 'package:comparateur_prix_app/models/comparaison.dart';
import 'package:comparateur_prix_app/models/marche.dart';
import 'package:comparateur_prix_app/models/produit.dart';
import 'package:comparateur_prix_app/models/releve_prix.dart';
import 'package:comparateur_prix_app/models/signalement.dart';
import 'package:comparateur_prix_app/models/user.dart';

void main() {
  test('Marche.fromJson', () {
    final marche = Marche.fromJson(const {
      'id': 4,
      'nom': 'Marché Mahavoky',
      'localisation': 'Toliara',
      'description': null,
      'actif': true,
      'created_at': '2026-09-08T10:00:00.000000Z',
      'updated_at': '2026-09-08T10:00:00.000000Z',
    });
    expect(marche.id, 4);
    expect(marche.nom, 'Marché Mahavoky');
    expect(marche.actif, isTrue);
  });

  test('Produit.fromJson', () {
    final produit = Produit.fromJson(const {
      'id': 1,
      'nom': 'Riz local',
      'unite_mesure': 'kilo',
      'categorie': 'Céréales',
      'actif': true,
    });
    expect(produit.nom, 'Riz local');
    expect(produit.uniteMesure, 'kilo');
  });

  test('User.fromJson et estAdmin', () {
    final user = User.fromJson(const {
      'id': 2,
      'name': 'Admin',
      'email': 'admin@comparateur.mg',
      'role': 'admin',
    });
    expect(user.estAdmin, isTrue);
    expect(User.fromJson(const {'role': 'contributeur'}).estAdmin, isFalse);
  });

  test('RelevePrix.fromJson (prix numérique + relations)', () {
    final releve = RelevePrix.fromJson(const {
      'id': 1,
      'valeur': 3200,
      'date_releve': '2026-09-08',
      'commentaire': null,
      'statut': 'valide',
      'produit': {'id': 1, 'nom': 'Riz local', 'unite_mesure': 'kilo'},
      'marche': {'id': 1, 'nom': 'Marché', 'localisation': 'Toliara'},
    });
    expect(releve.valeur, 3200);
    expect(releve.dateReleve, DateTime(2026, 9, 8));
    expect(releve.produit?.nom, 'Riz local');
    expect(releve.marche?.nom, 'Marché');
    expect(releve.estSignale, isFalse);
  });

  test('Signalement.fromJson', () {
    final signalement = Signalement.fromJson(const {
      'id': 1,
      'releve_id': 483,
      'type_anomalie': 'prix_anormal',
      'date_detection': '2026-09-08T11:10:00.000000Z',
    });
    expect(signalement.libelleType, 'Prix anormal');
    expect(signalement.releveId, 483);
  });

  test('Comparaison.fromJson gère les prix en chaîne', () {
    final comparaison = Comparaison.fromJson(const {
      'produit': {
        'id': 1,
        'nom': 'Riz local',
        'unite_mesure': 'kilo',
        'actif': true,
      },
      'prix_minimum': '3200.00',
      'prix_par_marche': [
        {
          'marche': {'id': 1, 'nom': 'Marché A', 'localisation': 'Toliara', 'actif': true},
          'dernier_prix': '3200.00',
          'date_dernier_releve': '2026-09-08',
          'nb_releves': 1,
          'ecart_pourcentage': 0.0,
        },
        {
          'marche': {'id': 2, 'nom': 'Marché B', 'localisation': 'Toliara', 'actif': true},
          'dernier_prix': 3500,
          'date_dernier_releve': '2026-09-07',
          'nb_releves': 1,
          'ecart_pourcentage': 9.38,
        },
      ],
    });
    expect(comparaison.prixMinimum, 3200);
    expect(comparaison.prixParMarche, hasLength(2));
    expect(comparaison.prixParMarche.first.dernierPrix, 3200);
    expect(comparaison.prixParMarche.last.dernierPrix, 3500);
  });
}