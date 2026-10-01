import 'package:flutter/material.dart';

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

  static const okBg = Color(0xFFE4F5E9);
  static const okFg = Color(0xFF166B3A);
  static const alertBg = Color(0xFFFBE7E0);
  static const alertFg = Color(0xFFC1502E);
  static const staleBg = Color(0xFFFCF0DC);
  static const staleFg = Color(0xFF8A5E15);

  // Fond sombre un cran sous l'encre : header et héros (encre) s'en détachent.
  static const darkPaper = Color(0xFF081A23);
  static const darkPaper2 = Color(0xFF163A4A);
  static const darkLine = Color(0xFF2A4A57);
  static const darkText = Color(0xFFF6FAF7);
  static const darkTextMuted = Color(0xFFB9C9C3);
  static const darkSurface = Color(0xFF163A4A);
  static const darkGreen = Color(0xFF2FAE68);
  static const darkGreenLight = Color(0xFF6FD98C);
  static const darkTerracotta = Color(0xFFE07350);
  static const darkSaffron = Color(0xFFF0B65A);
  static const darkOkBg = Color(0xFF1A3D2E);
  static const darkOkFg = Color(0xFF6FD98C);
  static const darkAlertBg = Color(0xFF4A1A14);
  static const darkAlertFg = Color(0xFFE07350);
  static const darkStaleBg = Color(0xFF3D3214);
  static const darkStaleFg = Color(0xFFF0B65A);
}

abstract final class AppFonts {
  static const display = 'Space Grotesk';
  static const sans = 'Inter';
  static const mono = 'IBM Plex Mono';
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

abstract final class AppRadius {
  static const chip = 8.0;
  static const card = 12.0;
  static const sheet = 16.0;
  static const pill = 999.0;
}

abstract final class AppShadow {
  static const card = [
    BoxShadow(
      color: Color(0x140E2A38),
      blurRadius: 12,
      offset: Offset(0, 4),
      spreadRadius: -2,
    ),
  ];
  static const cardHover = [
    BoxShadow(
      color: Color(0x1E0E2A38),
      blurRadius: 24,
      offset: Offset(0, 8),
      spreadRadius: -4,
    ),
  ];
  static const sheet = [
    BoxShadow(
      color: Color(0x1A0E2A38),
      blurRadius: 32,
      offset: Offset(0, 12),
      spreadRadius: -6,
    ),
  ];
  static const darkCard = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 12,
      offset: Offset(0, 4),
      spreadRadius: -2,
    ),
  ];
  static const darkCardHover = [
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 24,
      offset: Offset(0, 8),
      spreadRadius: -4,
    ),
  ];
}

abstract final class AppTextStyles {
  static const displayLarge = TextStyle(
    fontFamily: AppFonts.display,
    fontWeight: FontWeight.w700,
    fontSize: 32,
    height: 1.15,
    letterSpacing: -0.5,
  );
  static const displayMedium = TextStyle(
    fontFamily: AppFonts.display,
    fontWeight: FontWeight.w700,
    fontSize: 28,
    height: 1.2,
    letterSpacing: -0.5,
  );
  static const displaySmall = TextStyle(
    fontFamily: AppFonts.display,
    fontWeight: FontWeight.w700,
    fontSize: 24,
    height: 1.25,
    letterSpacing: -0.3,
  );
  static const headlineLarge = TextStyle(
    fontFamily: AppFonts.display,
    fontWeight: FontWeight.w700,
    fontSize: 22,
    height: 1.3,
  );
  static const headlineMedium = TextStyle(
    fontFamily: AppFonts.display,
    fontWeight: FontWeight.w600,
    fontSize: 20,
    height: 1.3,
  );
  static const headlineSmall = TextStyle(
    fontFamily: AppFonts.display,
    fontWeight: FontWeight.w600,
    fontSize: 18,
    height: 1.35,
  );
  static const titleLarge = TextStyle(
    fontFamily: AppFonts.display,
    fontWeight: FontWeight.w700,
    fontSize: 16,
    height: 1.4,
  );
  static const titleMedium = TextStyle(
    fontFamily: AppFonts.sans,
    fontWeight: FontWeight.w600,
    fontSize: 15,
    height: 1.4,
  );
  static const titleSmall = TextStyle(
    fontFamily: AppFonts.sans,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    height: 1.4,
  );
  static const bodyLarge = TextStyle(
    fontFamily: AppFonts.sans,
    fontWeight: FontWeight.w400,
    fontSize: 16,
    height: 1.5,
  );
  static const bodyMedium = TextStyle(
    fontFamily: AppFonts.sans,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    height: 1.5,
  );
  static const bodySmall = TextStyle(
    fontFamily: AppFonts.sans,
    fontWeight: FontWeight.w400,
    fontSize: 12.5,
    height: 1.5,
  );
  static const labelLarge = TextStyle(
    fontFamily: AppFonts.sans,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    height: 1.4,
  );
  static const labelMedium = TextStyle(
    fontFamily: AppFonts.sans,
    fontWeight: FontWeight.w500,
    fontSize: 12.5,
    height: 1.4,
  );
  static const labelSmall = TextStyle(
    fontFamily: AppFonts.mono,
    fontWeight: FontWeight.w600,
    fontSize: 11.5,
    height: 1.3,
    letterSpacing: 0.8,
  );
  static const priceLarge = TextStyle(
    fontFamily: AppFonts.mono,
    fontWeight: FontWeight.w700,
    fontSize: 24,
    height: 1.2,
  );
  static const priceMedium = TextStyle(
    fontFamily: AppFonts.mono,
    fontWeight: FontWeight.w600,
    fontSize: 18,
    height: 1.2,
  );
  static const priceSmall = TextStyle(
    fontFamily: AppFonts.mono,
    fontWeight: FontWeight.w600,
    fontSize: 14.5,
    height: 1.2,
  );
}

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
          surfaceContainerHighest: AppColors.paper2,
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
        okBg: AppColors.okBg,
        okFg: AppColors.okFg,
        alertBg: AppColors.alertBg,
        alertFg: AppColors.alertFg,
        staleBg: AppColors.staleBg,
        staleFg: AppColors.staleFg,
      );

  static ThemeData get dark => _construire(
        brightness: Brightness.dark,
        scheme: ColorScheme.fromSeed(
          seedColor: AppColors.darkGreen,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppColors.darkGreenLight,
          onPrimary: AppColors.darkPaper,
          primaryContainer: AppColors.ink,
          onPrimaryContainer: AppColors.paper,
          secondary: AppColors.darkGreenLight,
          onSecondary: AppColors.darkPaper,
          secondaryContainer: AppColors.darkPaper2,
          onSecondaryContainer: AppColors.darkText,
          tertiary: AppColors.darkTerracotta,
          onTertiary: AppColors.white,
          surface: AppColors.darkSurface,
          surfaceContainerHighest: AppColors.darkLine,
          onSurface: AppColors.darkText,
          onSurfaceVariant: AppColors.darkTextMuted,
          outline: AppColors.darkLine,
          outlineVariant: AppColors.darkLine,
          error: AppColors.darkTerracotta,
          onError: AppColors.white,
        ),
        fond: AppColors.darkPaper,
        surface: AppColors.darkSurface,
        surface2: AppColors.darkPaper2,
        bordure: AppColors.darkLine,
        texte: AppColors.darkText,
        texteAttenue: AppColors.darkTextMuted,
        okBg: AppColors.darkOkBg,
        okFg: AppColors.darkOkFg,
        alertBg: AppColors.darkAlertBg,
        alertFg: AppColors.darkAlertFg,
        staleBg: AppColors.darkStaleBg,
        staleFg: AppColors.darkStaleFg,
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
    required Color okBg,
    required Color okFg,
    required Color alertBg,
    required Color alertFg,
    required Color staleBg,
    required Color staleFg,
  }) {
    final base = ThemeData(brightness: brightness).textTheme;

    final textTheme = base
        .copyWith(
          displayLarge: AppTextStyles.displayLarge.copyWith(color: texte),
          displayMedium: AppTextStyles.displayMedium.copyWith(color: texte),
          displaySmall: AppTextStyles.displaySmall.copyWith(color: texte),
          headlineLarge: AppTextStyles.headlineLarge.copyWith(color: texte),
          headlineMedium: AppTextStyles.headlineMedium.copyWith(color: texte),
          headlineSmall: AppTextStyles.headlineSmall.copyWith(color: texte),
          titleLarge: AppTextStyles.titleLarge.copyWith(color: texte),
          titleMedium: AppTextStyles.titleMedium.copyWith(color: texte),
          titleSmall: AppTextStyles.titleSmall.copyWith(color: texte),
          bodyLarge: AppTextStyles.bodyLarge.copyWith(color: texte),
          bodyMedium: AppTextStyles.bodyMedium.copyWith(color: texte),
          bodySmall: AppTextStyles.bodySmall.copyWith(color: texteAttenue),
          labelLarge: AppTextStyles.labelLarge.copyWith(color: texte),
          labelMedium: AppTextStyles.labelMedium.copyWith(color: texte),
          labelSmall: AppTextStyles.labelSmall.copyWith(color: texteAttenue),
        )
        .apply(
          fontFamily: AppFonts.sans,
          bodyColor: texte,
          displayColor: texte,
        );

    final buttonTextStyle = TextStyle(
      fontFamily: AppFonts.sans,
      fontWeight: FontWeight.w600,
      fontSize: 14.5,
    );
    final formePilule = StadiumBorder();
    const padragePilule = EdgeInsets.symmetric(horizontal: 20, vertical: 14);
    const rayonChamp = AppRadius.card;
    const rayonCarte = AppRadius.card;
    const rayonSheet = AppRadius.sheet;

    final shadows = brightness == Brightness.dark
        ? AppShadow.darkCard
        : AppShadow.card;
    final shadowsHover = brightness == Brightness.dark
        ? AppShadow.darkCardHover
        : AppShadow.cardHover;

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
      dividerTheme: DividerThemeData(
        color: bordure,
        thickness: 1,
        space: 1,
      ),
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
          borderRadius: BorderRadius.circular(rayonCarte),
          side: BorderSide(color: bordure),
        ),
        shadowColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface2,
        indicatorColor: (brightness == Brightness.dark
                ? AppColors.darkGreenLight
                : AppColors.green)
            .withValues(alpha: 0.16),
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
          backgroundColor: brightness == Brightness.dark
              ? AppColors.darkGreenLight
              : AppColors.green,
          foregroundColor: brightness == Brightness.dark
              ? AppColors.darkPaper
              : AppColors.white,
          disabledBackgroundColor: (brightness == Brightness.dark
                  ? AppColors.darkGreenLight
                  : AppColors.green)
              .withValues(alpha: 0.4),
          shape: formePilule,
          padding: padragePilule,
          textStyle: buttonTextStyle,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: texte,
          side: BorderSide(color: bordure),
          shape: formePilule,
          padding: padragePilule,
          textStyle: buttonTextStyle,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brightness == Brightness.dark
              ? AppColors.darkGreenLight
              : AppColors.green,
          shape: formePilule,
          textStyle: buttonTextStyle,
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
          borderSide: BorderSide(
            color: brightness == Brightness.dark
                ? AppColors.darkGreenLight
                : AppColors.green,
            width: 1.6,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rayonChamp),
          borderSide: BorderSide(
            color: brightness == Brightness.dark
                ? AppColors.darkAlertFg
                : AppColors.terracotta,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rayonChamp),
          borderSide: BorderSide(color: bordure.withValues(alpha: 0.5)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface2,
        side: BorderSide(color: bordure),
        shape: StadiumBorder(),
        labelStyle: TextStyle(fontSize: 12.5, color: texte),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: TextStyle(
          color: AppColors.paper,
          fontFamily: AppFonts.sans,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sheet),
        ),
      ),
      listTileTheme: ListTileThemeData(
        textColor: texte,
        iconColor: texteAttenue,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        tileColor: Colors.transparent,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.paper,
        unselectedLabelColor: AppColors.paper.withValues(alpha: 0.7),
        indicatorColor: brightness == Brightness.dark
            ? AppColors.darkGreenLight
            : AppColors.greenLight,
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
          selectedForegroundColor: brightness == Brightness.dark
              ? AppColors.darkPaper
              : AppColors.white,
          selectedBackgroundColor: brightness == Brightness.dark
              ? AppColors.darkGreenLight
              : AppColors.green,
          side: BorderSide(color: bordure),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: brightness == Brightness.dark ? AppColors.darkGreenLight : AppColors.green,
      ),
      extensions: <ThemeExtension<dynamic>>[
        MarketScopeTokens(
          okBg: okBg,
          okFg: okFg,
          alertBg: alertBg,
          alertFg: alertFg,
          staleBg: staleBg,
          staleFg: staleFg,
          shadows: shadows,
          shadowsHover: shadowsHover,
          rayonCarte: rayonCarte,
          rayonSheet: rayonSheet,
          rayonChamp: rayonChamp,
        ),
      ],
    );
  }
}

@immutable
class MarketScopeTokens extends ThemeExtension<MarketScopeTokens> {
  const MarketScopeTokens({
    required this.okBg,
    required this.okFg,
    required this.alertBg,
    required this.alertFg,
    required this.staleBg,
    required this.staleFg,
    required this.shadows,
    required this.shadowsHover,
    required this.rayonCarte,
    required this.rayonSheet,
    required this.rayonChamp,
  });

  final Color okBg;
  final Color okFg;
  final Color alertBg;
  final Color alertFg;
  final Color staleBg;
  final Color staleFg;
  final List<BoxShadow> shadows;
  final List<BoxShadow> shadowsHover;
  final double rayonCarte;
  final double rayonSheet;
  final double rayonChamp;

  @override
  MarketScopeTokens copyWith({
    Color? okBg,
    Color? okFg,
    Color? alertBg,
    Color? alertFg,
    Color? staleBg,
    Color? staleFg,
    List<BoxShadow>? shadows,
    List<BoxShadow>? shadowsHover,
    double? rayonCarte,
    double? rayonSheet,
    double? rayonChamp,
  }) {
    return MarketScopeTokens(
      okBg: okBg ?? this.okBg,
      okFg: okFg ?? this.okFg,
      alertBg: alertBg ?? this.alertBg,
      alertFg: alertFg ?? this.alertFg,
      staleBg: staleBg ?? this.staleBg,
      staleFg: staleFg ?? this.staleFg,
      shadows: shadows ?? this.shadows,
      shadowsHover: shadowsHover ?? this.shadowsHover,
      rayonCarte: rayonCarte ?? this.rayonCarte,
      rayonSheet: rayonSheet ?? this.rayonSheet,
      rayonChamp: rayonChamp ?? this.rayonChamp,
    );
  }

  @override
  MarketScopeTokens lerp(ThemeExtension<MarketScopeTokens>? other, double t) {
    if (other is! MarketScopeTokens) return this;
    return MarketScopeTokens(
      okBg: Color.lerp(okBg, other.okBg, t)!,
      okFg: Color.lerp(okFg, other.okFg, t)!,
      alertBg: Color.lerp(alertBg, other.alertBg, t)!,
      alertFg: Color.lerp(alertFg, other.alertFg, t)!,
      staleBg: Color.lerp(staleBg, other.staleBg, t)!,
      staleFg: Color.lerp(staleFg, other.staleFg, t)!,
      shadows: shadows,
      shadowsHover: shadowsHover,
      rayonCarte: rayonCarte,
      rayonSheet: rayonSheet,
      rayonChamp: rayonChamp,
    );
  }
}

extension MarketScopeTheme on ThemeData {
  MarketScopeTokens get msTokens => extension<MarketScopeTokens>()!;
  Color get okBg => msTokens.okBg;
  Color get okFg => msTokens.okFg;
  Color get alertBg => msTokens.alertBg;
  Color get alertFg => msTokens.alertFg;
  Color get staleBg => msTokens.staleBg;
  Color get staleFg => msTokens.staleFg;
  List<BoxShadow> get cardShadows => msTokens.shadows;
  List<BoxShadow> get cardShadowsHover => msTokens.shadowsHover;
  double get cardRadius => msTokens.rayonCarte;
  double get sheetRadius => msTokens.rayonSheet;
  double get fieldRadius => msTokens.rayonChamp;

  bool get estSombre => brightness == Brightness.dark;

  /// Vert de marque lisible sur le fond courant (clair ou sombre).
  Color get marque => estSombre ? AppColors.darkGreenLight : AppColors.green;

  /// Fond des cartes.
  Color get fondCarte => estSombre ? AppColors.darkSurface : AppColors.white;

  /// Bordure fine des cartes et séparateurs.
  Color get ligne => estSombre ? AppColors.darkLine : AppColors.line;
}