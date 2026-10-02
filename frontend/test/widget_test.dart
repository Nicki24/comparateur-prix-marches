// Tests widget : démarrage, en-tête lisible et parcours de connexion.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:comparateur_prix_app/main.dart';
import 'package:comparateur_prix_app/screens/login_screen.dart';
import 'package:comparateur_prix_app/widgets/marketscope_header.dart';

void main() {
  // Visite guidée déjà vue : on arrive directement sur l'accueil.
  setUp(() => SharedPreferences.setMockInitialValues({'onboarding_vu': true}));

  testWidgets('L’application démarre avec la navigation principale', (tester) async {
    await tester.pumpWidget(const App());
    await tester.pump();

    expect(find.byType(NavigationBar), findsOneWidget);
    // Navigation V2 : Accueil · Marchés · Produits · Relevés · Profil.
    expect(find.byType(NavigationDestination), findsNWidgets(5));
  });

  testWidgets('Le header affiche le wordmark en texte (lisible)', (tester) async {
    await tester.pumpWidget(const App());
    await tester.pump();

    expect(find.byType(MarketScopeWordmark), findsWidgets);
    expect(find.text('MarketScope', findRichText: true), findsWidgets);
  });

  testWidgets('Profil → « Se connecter » ouvre l’écran de connexion', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const App());
    await tester.pump();

    await tester.tap(find.text('Profil'));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.widgetWithText(FilledButton, 'Se connecter'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
