// Tests des états partagés : chargement, erreur (accessibilité WCAG 2.2 AA).

import 'dart:ui' show SemanticsFlag;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:comparateur_prix_app/widgets/etats.dart';

import '../helpers/helpers.dart';

void main() {
  group(Chargement, () {
    testWidgets('annonce « Chargement en cours » aux lecteurs d’écran', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(const Chargement());

      expect(find.bySemanticsLabel('Chargement en cours'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('fige la pulsation quand les animations sont désactivées', (
      tester,
    ) async {
      await tester.pumpApp(const Chargement(), disableAnimations: true);

      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('pulse quand les animations sont autorisées', (tester) async {
      await tester.pumpApp(const Chargement());

      expect(tester.hasRunningAnimations, isTrue);
    });
  });

  group(ChargementCentre, () {
    testWidgets('annonce « Chargement en cours » aux lecteurs d’écran', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(const ChargementCentre());

      expect(find.bySemanticsLabel('Chargement en cours'), findsOneWidget);
      handle.dispose();
    });
  });

  group(ErreurMessage, () {
    testWidgets('expose le message dans une région annoncée', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(
        const ErreurMessage(message: 'Serveur injoignable.'),
        disableAnimations: true,
      );

      final region = tester.getSemantics(
        find
            .ancestor(
              of: find.text('Serveur injoignable.'),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(region.hasFlag(SemanticsFlag.isLiveRegion), isTrue);
      handle.dispose();
    });

    group('calls onReessayer', () {
      testWidgets('quand on appuie sur « Réessayer »', (tester) async {
        var appels = 0;
        await tester.pumpApp(
          ErreurMessage(message: 'Erreur', onReessayer: () => appels++),
          disableAnimations: true,
        );

        await tester.tap(find.text('Réessayer'));
        await tester.pump();

        expect(appels, equals(1));
      });
    });

    testWidgets('respecte la taille minimale des cibles tactiles (48 dp)', (
      tester,
    ) async {
      await tester.pumpApp(
        ErreurMessage(message: 'Erreur', onReessayer: () {}),
        disableAnimations: true,
      );

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });
  });
}
