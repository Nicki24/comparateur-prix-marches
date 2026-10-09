// Parcours admin : suppression définitive, refus 409 et fusion.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:comparateur_prix_app/screens/admin_gestion_screen.dart';

import 'helpers/helpers.dart';

Map<String, dynamic> _marche(int id, String nom) => {
  'id': id,
  'nom': nom,
  'localisation': 'Toliara',
  'actif': true,
};

/// Faux serveur : mémorise les requêtes et répond selon [repondre].
class _FauxServeur {
  _FauxServeur(this.repondre);

  final http.Response Function(http.Request) repondre;
  final requetes = <http.Request>[];

  late final client = MockClient((requete) async {
    requetes.add(requete);
    if (requete.method == 'GET') {
      return _json({
        'data': [_marche(1, 'Bazar Be'), _marche(2, 'Bazar be')],
      });
    }
    return repondre(requete);
  });
}

http.Response _json(Object corps, [int statut = 200]) => http.Response(
  jsonEncode(corps),
  statut,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Future<void> _ouvrirMenu(WidgetTester tester, String nom) async {
  await tester.tap(find.byTooltip('Plus d’actions pour « $nom »'));
  await tester.pumpAndSettle();
}

void main() {
  group(AdminGestionScreen, () {
    testWidgets('supprime un marché après avoir retapé son nom', (
      tester,
    ) async {
      final serveur = _FauxServeur(
        (_) => _json({'message': 'Marché supprimé définitivement.'}),
      );

      await http.runWithClient(() async {
        await tester.pumpApp(
          const AdminGestionScreen(type: AdminGestionType.marches),
          disableAnimations: true,
        );
        await tester.pumpAndSettle();

        await _ouvrirMenu(tester, 'Bazar be');
        await tester.tap(find.text('Supprimer définitivement…'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Bazar be');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Supprimer'));
        await tester.pumpAndSettle();
      }, () => serveur.client);

      final suppression = serveur.requetes.singleWhere(
        (r) => r.method == 'DELETE',
      );
      expect(suppression.url.path, endsWith('/marches/2/definitif'));
      expect(find.text('Marché supprimé définitivement.'), findsOneWidget);
    });

    testWidgets('propose de désactiver quand l’API refuse (409)', (
      tester,
    ) async {
      const refus =
          'Ce marché a 3 relevés de prix : désactivez-le plutôt, '
          'ou fusionnez-le avec un autre marché.';
      final serveur = _FauxServeur(
        (r) => r.url.path.endsWith('/definitif')
            ? _json({'message': refus, 'releves': 3}, 409)
            : _json({'message': 'Marché désactivé.'}),
      );

      await http.runWithClient(() async {
        await tester.pumpApp(
          const AdminGestionScreen(type: AdminGestionType.marches),
          disableAnimations: true,
        );
        await tester.pumpAndSettle();

        await _ouvrirMenu(tester, 'Bazar be');
        await tester.tap(find.text('Supprimer définitivement…'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Bazar be');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Supprimer'));
        await tester.pumpAndSettle();

        expect(find.text('Suppression impossible'), findsOneWidget);
        expect(find.text(refus), findsOneWidget);

        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Désactiver'),
          ),
        );
        await tester.pumpAndSettle();
        // Confirmation habituelle de la désactivation.
        await tester.tap(find.widgetWithText(FilledButton, 'Désactiver'));
        await tester.pumpAndSettle();
      }, () => serveur.client);

      final desactivation = serveur.requetes.singleWhere(
        (r) => r.method == 'DELETE' && r.url.path.endsWith('/marches/2'),
      );
      expect(desactivation.url.path, endsWith('/marches/2'));
    });

    testWidgets('fusionne un doublon dans le marché choisi', (tester) async {
      final serveur = _FauxServeur(
        (_) => _json({
          'message': 'Marché fusionné dans « Bazar Be » : 2 relevés déplacés.',
        }),
      );

      await http.runWithClient(() async {
        await tester.pumpApp(
          const AdminGestionScreen(type: AdminGestionType.marches),
          disableAnimations: true,
        );
        await tester.pumpAndSettle();

        await _ouvrirMenu(tester, 'Bazar be');
        await tester.tap(find.text('Fusionner avec…'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(DropdownButtonFormField<int>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Bazar Be · Toliara').last);
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Bazar be');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Fusionner'));
        await tester.pumpAndSettle();
      }, () => serveur.client);

      final fusion = serveur.requetes.singleWhere((r) => r.method == 'POST');
      expect(fusion.url.path, endsWith('/marches/2/fusionner'));
      expect(jsonDecode(fusion.body), {'cible_id': 1});
      expect(
        find.text('Marché fusionné dans « Bazar Be » : 2 relevés déplacés.'),
        findsOneWidget,
      );
    });
  });
}
