// Tests widget : visite guidée, centre d'aide et bascule de thème.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:comparateur_prix_app/screens/aide_screen.dart';
import 'package:comparateur_prix_app/screens/onboarding_screen.dart';
import 'package:comparateur_prix_app/services/preferences_app.dart';
import 'package:comparateur_prix_app/theme/app_theme.dart';
import 'package:comparateur_prix_app/widgets/actions_header.dart';

Widget _app(Widget home, {ThemeData? theme}) =>
    MaterialApp(theme: theme ?? AppTheme.light, home: home);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final taille in const [Size(360, 640), Size(320, 480)]) {
    testWidgets('Visite guidée : 4 étapes puis fin ($taille)', (tester) async {
      tester.view.physicalSize = taille;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      var termine = false;
      await tester.pumpWidget(
        _app(OnboardingScreen(onTermine: () => termine = true)),
      );
      await tester.pump();

      expect(find.text('Bienvenue sur MarketScope'), findsOneWidget);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Suivant'));
        for (var f = 0; f < 12; f++) {
          await tester.pump(const Duration(milliseconds: 60));
        }
      }
      expect(find.text('Contribuez à votre tour'), findsOneWidget);
      await tester.tap(find.text('C’est parti !'));
      expect(termine, isTrue);
    });
  }

  testWidgets('Visite guidée : « Passer » termine directement', (tester) async {
    var termine = false;
    await tester.pumpWidget(
      _app(OnboardingScreen(onTermine: () => termine = true)),
    );
    await tester.tap(find.text('Passer'));
    expect(termine, isTrue);
  });

  for (final theme in [AppTheme.light, AppTheme.dark]) {
    testWidgets('Centre d’aide : sections et recherche (${theme.brightness.name})',
        (tester) async {
      await tester.pumpWidget(_app(const AideScreen(), theme: theme));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Nouveau sur MarketScope ?'), findsOneWidget);
      expect(find.text('PREMIERS PAS'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'obsolete');
      await tester.pump(const Duration(seconds: 1));
      // Recherche insensible aux accents : « obsolète » est trouvé.
      expect(find.text('Que veut dire « Obsolète » ?'), findsOneWidget);
      expect(find.text('PREMIERS PAS'), findsNothing);

      await tester.enterText(find.byType(TextField), 'zzzz');
      await tester.pump();
      expect(find.textContaining('Aucune question'), findsOneWidget);
    });
  }

  testWidgets('Le bouton thème bascule clair → sombre', (tester) async {
    await tester.pumpWidget(_app(const Scaffold(body: BoutonTheme())));
    await tester.pump();
    await tester.tap(find.byType(BoutonTheme));
    await tester.pump();
    expect(PreferencesApp.instance.themeMode, ThemeMode.dark);
  });
}
