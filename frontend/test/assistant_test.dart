// Tests widget : bulle et fenêtre de l'assistant IA.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:comparateur_prix_app/theme/app_theme.dart';
import 'package:comparateur_prix_app/widgets/assistant_chat.dart';

void main() {
  for (final theme in [AppTheme.light, AppTheme.dark]) {
    testWidgets('La bulle ouvre l’assistant avec suggestions (${theme.brightness.name})',
        (tester) async {
      tester.view.physicalSize = const Size(360, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: const Scaffold(floatingActionButton: BulleAssistant()),
      ));
      await tester.tap(find.byType(BulleAssistant));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Assistant MarketScope'), findsWidgets);
      expect(find.text('Où acheter le riz le moins cher ?'), findsOneWidget);
      expect(find.byTooltip('Envoyer'), findsOneWidget);

      // Le bouton Envoyer s'active quand on tape une question.
      final envoyer = find.widgetWithIcon(IconButton, Icons.arrow_upward_rounded);
      expect(tester.widget<IconButton>(envoyer).onPressed, isNull);
      await tester.enterText(find.byType(TextField), 'Prix du sucre ?');
      await tester.pump();
      expect(tester.widget<IconButton>(envoyer).onPressed, isNotNull);

      await tester.tap(find.byTooltip('Fermer'));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('Où acheter le riz le moins cher ?'), findsNothing);
    });
  }
}
