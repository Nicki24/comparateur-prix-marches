import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/accueil_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/preferences_app.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = PreferencesApp.instance;
    return ListenableBuilder(
      listenable: prefs,
      builder: (context, _) {
        final Widget accueil;
        if (!prefs.charge) {
          // Lecture des préférences (quelques ms) : fond encre neutre.
          accueil = const ColoredBox(color: AppColors.ink);
        } else if (!prefs.onboardingVu) {
          accueil = OnboardingScreen(onTermine: prefs.marquerOnboardingVu);
        } else {
          accueil = const AccueilScreen();
        }

        return MaterialApp(
          title: 'MarketScope',
          debugShowCheckedModeBanner: false,
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: prefs.themeMode,
          // Fondu doux entre clair et sombre plutôt qu'un changement sec.
          themeAnimationDuration: const Duration(milliseconds: 450),
          themeAnimationCurve: Curves.easeInOutCubic,
          home: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: KeyedSubtree(
              key: ValueKey(accueil.runtimeType),
              child: accueil,
            ),
          ),
        );
      },
    );
  }
}
