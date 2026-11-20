// Alertes validées : abandon de formulaire, détection des obsolètes et
// session expirée (401).

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:comparateur_prix_app/screens/admin_gestion_screen.dart';
import 'package:comparateur_prix_app/screens/saisie_releve_screen.dart';
import 'package:comparateur_prix_app/screens/signalements_screen.dart';
import 'package:comparateur_prix_app/services/session.dart';
import 'package:comparateur_prix_app/theme/app_theme.dart';
import 'package:comparateur_prix_app/widgets/alerte_session_expiree.dart';

import 'helpers/helpers.dart';

http.Response _json(Object corps, [int statut = 200]) => http.Response(
      jsonEncode(corps),
      statut,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

/// Écran minimal qui pousse le formulaire pour que le bouton Retour existe.
class _OuvertureFormulaire extends StatelessWidget {
  const _OuvertureFormulaire();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const SaisieReleveScreen(),
            ),
          ),
          child: const Text('Ouvrir le formulaire'),
        ),
      ),
    );
  }
}

void main() async {
  await initializeDateFormatting('fr_FR');

  group('Alertes supplémentaires', () {
    testWidgets('un relevé rempli ne s’abandonne pas sans confirmation', (
      tester,
    ) async {
      final client = MockClient((requete) async => _json({'data': []}));

      await http.runWithClient(() async {
        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.light,
          home: const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: _OuvertureFormulaire(),
          ),
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Ouvrir le formulaire'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField), '3200');
        await tester.pumpAndSettle();

        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.text('Modifications non enregistrées'), findsOneWidget);

        await tester.tap(find.widgetWithText(TextButton, 'Continuer la saisie'));
        await tester.pumpAndSettle();
        expect(find.text('Nouveau relevé de prix'), findsOneWidget);
        expect(find.text('Modifications non enregistrées'), findsNothing);

        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Abandonner'));
        await tester.pumpAndSettle();
        expect(find.text('Ouvrir le formulaire'), findsOneWidget);
      }, () => client);
    });

    testWidgets('un produit à moitié saisi prévient avant Annuler', (
      tester,
    ) async {
      final client = MockClient((requete) async => _json({'data': []}));

      await http.runWithClient(() async {
        await tester.pumpApp(
          const AdminGestionScreen(type: AdminGestionType.produits),
          disableAnimations: true,
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Ajouter un produit'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField).first, 'Riz');
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(TextButton, 'Annuler'));
        await tester.pumpAndSettle();
        expect(find.text('Modifications non enregistrées'), findsOneWidget);

        await tester.tap(find.widgetWithText(TextButton, 'Continuer la saisie'));
        await tester.pumpAndSettle();
        expect(find.text('Nouveau produit'), findsOneWidget);

        await tester.tap(find.widgetWithText(TextButton, 'Annuler'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Abandonner'));
        await tester.pumpAndSettle();
        expect(find.text('Nouveau produit'), findsNothing);
      }, () => client);
    });

    testWidgets('la détection des obsolètes demande confirmation', (
      tester,
    ) async {
      final requetes = <http.Request>[];
      final client = MockClient((requete) async {
        requetes.add(requete);
        if (requete.method == 'GET') {
          return _json({'data': []});
        }
        return _json({'nombre_signalements': 2});
      });

      await http.runWithClient(() async {
        await tester.pumpApp(
          const SignalementsScreen(),
          disableAnimations: true,
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Détecter les prix obsolètes'));
        await tester.pumpAndSettle();
        expect(find.text('Détecter les prix obsolètes ?'), findsOneWidget);
        expect(requetes.any((r) => r.method == 'POST'), isFalse);

        await tester.tap(find.widgetWithText(TextButton, 'Annuler'));
        await tester.pumpAndSettle();
        expect(requetes.any((r) => r.method == 'POST'), isFalse);

        await tester.tap(find.byTooltip('Détecter les prix obsolètes'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithText(FilledButton, 'Lancer la détection'),
        );
        await tester.pumpAndSettle();
      }, () => client);

      expect(
        requetes.any(
          (r) => r.url.path.endsWith('/signalements/detecter-obsoletes'),
        ),
        isTrue,
      );
    });

    testWidgets('une session expirée alerte puis renvoie à la connexion', (
      tester,
    ) async {
      addTearDown(Session.instance.effacerAlerteExpiration);

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: const AlerteSessionExpiree(
            child: Scaffold(body: SizedBox.shrink()),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Le 401 est simulé en aval par ApiClient ; ici on vérifie l'alerte
      // affichée et la navigation vers l'écran de connexion.
      Session.instance.messageExpiration =
          'Votre session a expiré. Veuillez vous reconnecter.';
      Session.instance.versionExpiration++;
      Session.instance.notifyListeners();
      await tester.pumpAndSettle();

      expect(find.text('Session expirée'), findsOneWidget);
      expect(find.textContaining('Votre session a expiré'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Se reconnecter'));
      // pump() volontairement borné : l'écran de connexion a ses propres
      // animations et pumpAndSettle() n'est pas nécessaire ici.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Session expirée'), findsNothing);
    });
  });
}
