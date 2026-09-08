// Test widget de base : vérifie que l'application démarre et affiche
// la barre de navigation principale.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:comparateur_prix_app/main.dart';

void main() {
  testWidgets('L’application démarre avec la navigation principale', (tester) async {
    await tester.pumpWidget(const App());
    await tester.pump();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(3));
  });
}