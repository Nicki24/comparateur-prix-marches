// Tests des dialogues de confirmation forte (suppression définitive, fusion).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:comparateur_prix_app/theme/app_theme.dart';
import 'package:comparateur_prix_app/widgets/confirmation_forte.dart';

import '../helpers/helpers.dart';

FilledButton _bouton(WidgetTester tester, String libelle) => tester.widget(
  find.ancestor(of: find.text(libelle), matching: find.byType(FilledButton)),
);

/// Bouton qui ouvre le dialogue et mémorise sa valeur de retour.
class _Lanceur<T> extends StatelessWidget {
  const _Lanceur({required this.ouvrir, required this.onResultat});

  final Future<T> Function(BuildContext) ouvrir;
  final ValueChanged<T> onResultat;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () async => onResultat(await ouvrir(context)),
      child: const Text('Ouvrir'),
    );
  }
}

void main() {
  group(SuppressionDefinitiveDialog, () {
    testWidgets('le bouton reste désactivé tant que le nom n’est pas retapé', (
      tester,
    ) async {
      await tester.pumpApp(
        const SuppressionDefinitiveDialog(article: 'le marché', nom: 'Bazar'),
      );

      expect(_bouton(tester, 'Supprimer').onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'bazar');
      await tester.pump();
      expect(_bouton(tester, 'Supprimer').onPressed, isNull);

      await tester.enterText(find.byType(TextField), '  Bazar ');
      await tester.pump();
      expect(_bouton(tester, 'Supprimer').onPressed, isNotNull);
    });

    testWidgets('renvoie true après confirmation, false après annulation', (
      tester,
    ) async {
      bool? resultat;
      await tester.pumpApp(
        _Lanceur<bool>(
          ouvrir: (c) => SuppressionDefinitiveDialog.afficher(
            c,
            article: 'le produit',
            nom: 'Riz',
          ),
          onResultat: (r) => resultat = r,
        ),
      );

      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(resultat, isFalse);

      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Riz');
      await tester.pump();
      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();
      expect(resultat, isTrue);
    });

    testWidgets('le champ de confirmation est étiqueté pour les lecteurs '
        'd’écran', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(
        const SuppressionDefinitiveDialog(article: 'le marché', nom: 'Bazar'),
      );

      expect(
        find.bySemanticsLabel(RegExp('Retapez « Bazar » pour confirmer')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('respecte les tailles de cible et le contraste', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(
        const SuppressionDefinitiveDialog(article: 'le marché', nom: 'Bazar'),
      );
      await tester.enterText(find.byType(TextField), 'Bazar');
      // Laisse la couleur du bouton finir sa transition (désactivé → actif).
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('garde un contraste suffisant en thème sombre', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(
        const SuppressionDefinitiveDialog(article: 'le marché', nom: 'Bazar'),
        theme: AppTheme.dark,
      );
      await tester.enterText(find.byType(TextField), 'Bazar');
      // Laisse la couleur du bouton finir sa transition (désactivé → actif).
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  });

  group(FusionDialog, () {
    const cibles = [
      CibleFusion(id: 1, nom: 'Bazar Be', detail: 'Toliara'),
      CibleFusion(id: 2, nom: 'Sanfil', detail: 'inactif'),
    ];

    testWidgets('exige une cible et le nom du doublon avant de fusionner', (
      tester,
    ) async {
      int? resultat;
      await tester.pumpApp(
        _Lanceur<int?>(
          ouvrir: (c) => FusionDialog.afficher(
            c,
            article: 'le marché',
            nom: 'Bazar be',
            cibles: cibles,
          ),
          onResultat: (r) => resultat = r,
        ),
      );
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      expect(_bouton(tester, 'Fusionner').onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'Bazar be');
      await tester.pump();
      expect(_bouton(tester, 'Fusionner').onPressed, isNull);

      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bazar Be · Toliara').last);
      await tester.pumpAndSettle();
      expect(_bouton(tester, 'Fusionner').onPressed, isNotNull);

      await tester.tap(find.text('Fusionner'));
      await tester.pumpAndSettle();
      expect(resultat, 1);
    });

    testWidgets('annonce l’absence de cible disponible', (tester) async {
      await tester.pumpApp(
        const FusionDialog(article: 'le produit', nom: 'Riz', cibles: []),
      );

      expect(
        find.text('Aucun autre élément disponible pour la fusion.'),
        findsOneWidget,
      );
      expect(_bouton(tester, 'Fusionner').onPressed, isNull);
    });
  });
}
