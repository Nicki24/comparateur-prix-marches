import 'package:flutter/material.dart';

/// Jetons de la charte graphique MarketScope (v1).
abstract final class AppColors {
  static const ink = Color(0xFF0E2A38);
  static const ink2 = Color(0xFF163A4A);
  static const green = Color(0xFF1C8A4E);
  static const greenLight = Color(0xFF4CC26B);
  static const terracotta = Color(0xFFC1502E);
  static const saffron = Color(0xFFE0A23B);
  static const paper = Color(0xFFF6FAF7);
  static const paper2 = Color(0xFFEBF2ED);
  static const line = Color(0xFFD7E3DA);
  static const text = Color(0xFF12242A);
  static const textMuted = Color(0xFF5A6D66);
  static const white = Color(0xFFFFFFFF);

  // Badges de statut.
  static const okBg = Color(0xFFE4F5E9);
  static const okFg = Color(0xFF166B3A);
  static const alertBg = Color(0xFFFBE7E0);
  static const alertFg = Color(0xFFC1502E);
  static const staleBg = Color(0xFFFCF0DC);
  static const staleFg = Color(0xFF8A5E15);

  // Variantes sombres (préférence système).
  static const darkPaper = Color(0xFF0B1B22);
  static const darkPaper2 = Color(0xFF102630);
  static const darkLine = Color(0xFF1E3944);
  static const darkText = Color(0xFFEAF3EE);
  static const darkTextMuted = Color(0xFF9FB6AE);
  static const darkSurface = Color(0xFF0F262E);
}

/// Familles de la charte : Space Grotesk (titres), Inter (interface),
/// IBM Plex Mono (prix et données).
abstract final class AppFonts {
  static const display = 'Space Grotesk';
  static const sans = 'Inter';
  static const mono = 'IBM Plex Mono';
}

/// Style des prix chiffrés (effet « ticker de marché »).
TextStyle stylePrix({
  double taille = 16,
  Color? couleur,
  FontWeight poids = FontWeight.w600,
}) {
  return TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: taille,
    fontWeight: poids,
    color: couleur,
  );
}

/// Thème MarketScope respectant la charte graphique.
abstract final class AppTheme {
  static ThemeData get light => _construire(
        brightness: Brightness.light,
        scheme: ColorScheme.fromSeed(seedColor: AppColors.green).copyWith(
          primary: AppColors.green,
          onPrimary: AppColors.white,
          primaryContainer: AppColors.ink,
          onPrimaryContainer: AppColors.paper,
          secondary: AppColors.ink,
          onSecondary: AppColors.white,
          secondaryContainer: AppColors.paper2,
          onSecondaryContainer: AppColors.ink,
          tertiary: AppColors.terracotta,
          onTertiary: AppColors.white,
          surface: AppColors.white,
          onSurface: AppColors.text,
          onSurfaceVariant: AppColors.textMuted,
          outline: AppColors.line,
          outlineVariant: AppColors.line,
          error: AppColors.terracotta,
          onError: AppColors.white,
        ),
        fond: AppColors.paper,
        surface: AppColors.white,
        surface2: AppColors.paper2,
        bordure: AppColors.line,
        texte: AppColors.text,
        texteAttenue: AppColors.textMuted,
      );

  static ThemeData get dark => _construire(
        brightness: Brightness.dark,
        scheme: ColorScheme.fromSeed(
          seedColor: AppColors.green,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppColors.greenLight,
          onPrimary: AppColors.darkPaper,
          primaryContainer: AppColors.ink,
          onPrimaryContainer: AppColors.paper,
          secondary: AppColors.greenLight,
          onSecondary: AppColors.darkPaper,
          secondaryContainer: AppColors.darkPaper2,
          onSecondaryContainer: AppColors.darkText,
          tertiary: AppColors.terracotta,
          onTertiary: AppColors.white,
          surface: AppColors.darkSurface,
          onSurface: AppColors.darkText,
          onSurfaceVariant: AppColors.darkTextMuted,
          outline: AppColors.darkLine,
          outlineVariant: AppColors.darkLine,
          error: AppColors.terracotta,
          onError: AppColors.white,
        ),
        fond: AppColors.darkPaper,
        surface: AppColors.darkSurface,
        surface2: AppColors.darkPaper2,
        bordure: AppColors.darkLine,
        texte: AppColors.darkText,
        texteAttenue: AppColors.darkTextMuted,
      );

  static ThemeData _construire({
    required Brightness brightness,
    required ColorScheme scheme,
    required Color fond,
    required Color surface,
    required Color surface2,
    required Color bordure,
    required Color texte,
    required Color texteAttenue,
  }) {
    final base = ThemeData(brightness: brightness).textTheme;

    final textTheme = base
        .copyWith(
          displayLarge: base.displayLarge?.copyWith(
            fontFamily: AppFonts.display,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          displayMedium: base.displayMedium?.copyWith(
            fontFamily: AppFonts.display,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          displaySmall: base.displaySmall?.copyWith(
            fontFamily: AppFonts.display,
            fontWeight: FontWeight.w700,
          ),
          headlineLarge: base.headlineLarge?.copyWith(
            fontFamily: AppFonts.display,
            fontWeight: FontWeight.w700,
          ),
          headlineMedium: base.headlineMedium?.copyWith(
            fontFamily: AppFonts.display,
            fontWeight: FontWeight.w600,
          ),
          headlineSmall: base.headlineSmall?.copyWith(
            fontFamily: AppFonts.display,
            fontWeight: FontWeight.w600,
          ),
          titleLarge: base.titleLarge?.copyWith(
            fontFamily: AppFonts.display,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: base.titleMedium?.copyWith(
            fontFamily: AppFonts.sans,
            fontWeight: FontWeight.w600,
          ),
          titleSmall: base.titleSmall?.copyWith(
            fontFamily: AppFonts.sans,
            fontWeight: FontWeight.w600,
          ),
        )
        .apply(
          fontFamily: AppFonts.sans,
          bodyColor: texte,
          displayColor: texte,
        );

    final styleBouton = TextStyle(
      fontFamily: AppFonts.sans,
      fontWeight: FontWeight.w600,
      fontSize: 14.5,
    );
    final formePilule = StadiumBorder();
    const padragePilule = EdgeInsets.symmetric(horizontal: 20, vertical: 14);
    const rayonChamp = 12.0;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: fond,
      fontFamily: AppFonts.sans,
      textTheme: textTheme,
      canvasColor: fond,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      dividerTheme: DividerThemeData(color: bordure, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.display,
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: AppColors.paper,
        ),
        iconTheme: IconThemeData(color: AppColors.paper),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: bordure),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface2,
        indicatorColor: AppColors.green.withValues(alpha: 0.16),
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontFamily: AppFonts.sans,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: texte,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.green,
          foregroundColor: AppColors.white,
          disabledBackgroundColor:
              AppColors.green.withValues(alpha: 0.4),
          shape: formePilule,
          padding: padragePilule,
          textStyle: styleBouton,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: texte,
          side: BorderSide(color: bordure),
          shape: formePilule,
          padding: padragePilule,
          textStyle: styleBouton,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.green,
          shape: formePilule,
          textStyle: styleBouton,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        labelStyle: TextStyle(color: texteAttenue, fontSize: 14),
        hintStyle: TextStyle(color: texteAttenue.withValues(alpha: 0.8)),
        prefixIconColor: texteAttenue,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rayonChamp),
          borderSide: BorderSide(color: bordure),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rayonChamp),
          borderSide: BorderSide(color: bordure),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rayonChamp),
          borderSide: BorderSide(color: AppColors.green, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rayonChamp),
          borderSide: BorderSide(color: AppColors.terracotta),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface2,
        side: BorderSide(color: bordure),
        shape: StadiumBorder(),
        labelStyle: TextStyle(fontSize: 12.5, color: texte),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: TextStyle(
          color: AppColors.paper,
          fontFamily: AppFonts.sans,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      listTileTheme: ListTileThemeData(
        textColor: texte,
        iconColor: texteAttenue,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.paper,
        unselectedLabelColor: AppColors.paper.withValues(alpha: 0.7),
        indicatorColor: AppColors.greenLight,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle: TextStyle(
          fontFamily: AppFonts.sans,
          fontWeight: FontWeight.w600,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          foregroundColor: texte,
          selectedForegroundColor: AppColors.white,
          selectedBackgroundColor: AppColors.green,
          side: BorderSide(color: bordure),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.green,
      ),
    );
  }
}