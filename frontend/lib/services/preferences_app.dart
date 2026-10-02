import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Préférences locales de l'application : thème et visite guidée.
/// Notifie ses auditeurs à chaque changement (comme [Session]).
class PreferencesApp extends ChangeNotifier {
  PreferencesApp._() {
    _restaurer();
  }

  static final PreferencesApp instance = PreferencesApp._();

  static const _cleTheme = 'theme_mode';
  static const _cleOnboarding = 'onboarding_vu';

  ThemeMode _themeMode = ThemeMode.system;
  bool _onboardingVu = true;
  bool _charge = false;

  ThemeMode get themeMode => _themeMode;

  /// `false` tant que la visite guidée n'a jamais été terminée ou passée.
  bool get onboardingVu => _onboardingVu;

  /// `true` une fois les préférences lues depuis le stockage local.
  bool get charge => _charge;

  Future<void> _restaurer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final index = prefs.getInt(_cleTheme) ?? 0;
      _themeMode = ThemeMode.values[index.clamp(0, ThemeMode.values.length - 1)];
      _onboardingVu = prefs.getBool(_cleOnboarding) ?? false;
    } catch (_) {
      // Stockage indisponible : on garde les valeurs par défaut.
    }
    _charge = true;
    notifyListeners();
  }

  Future<void> changerTheme(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_cleTheme, mode.index);
  }

  /// Bascule clair ↔ sombre à partir de la luminosité affichée.
  Future<void> basculerTheme(Brightness actuelle) => changerTheme(
        actuelle == Brightness.dark ? ThemeMode.light : ThemeMode.dark,
      );

  Future<void> marquerOnboardingVu() async {
    _onboardingVu = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cleOnboarding, true);
  }
}
