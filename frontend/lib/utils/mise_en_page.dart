import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Mise en page sur grand écran (web, desktop, tablette en paysage).
///
/// L'application est pensée mobile d'abord : au-delà de [largeurMax], le
/// contenu est centré au lieu de s'étirer sur toute la fenêtre. Les fonds
/// (header, bandeau des prix, barre de navigation) restent pleine largeur.
abstract final class MiseEnPage {
  /// Largeur maximale du contenu des écrans.
  static const double largeurMax = 960;

  /// Largeur maximale de la barre de navigation du bas.
  static const double largeurNavigation = 640;

  /// À partir de cette largeur de fenêtre, les éléments de structure
  /// (header…) passent en format « plein écran ».
  static const double seuilLarge = 900;

  static bool estLarge(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= seuilLarge;

  /// À partir de cette largeur, la navigation principale passe de la
  /// barre du bas au header (usage souris / clavier).
  static const double seuilBureau = 1024;

  static bool estBureau(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= seuilBureau;

  /// Marge latérale à ajouter de chaque côté pour centrer un contenu de
  /// largeur [max] dans la fenêtre (0 sur téléphone).
  static double marge(BuildContext context, {double max = largeurMax}) {
    final largeur = MediaQuery.sizeOf(context).width;
    return math.max(0, (largeur - max) / 2);
  }

  /// [base] augmenté de la marge qui centre le contenu d'une liste
  /// défilante. À utiliser comme `padding` des ListView / GridView : la
  /// zone de défilement garde toute la largeur, donc la molette et la
  /// barre de défilement fonctionnent partout dans la fenêtre.
  ///
  /// [boutonsFlottants] : nombre de boutons flottants empilés en bas à
  /// droite (bulle de l'assistant, « Nouveau »…). Le bas de la liste est
  /// rallongé d'autant pour que le dernier élément ne reste jamais caché
  /// dessous (WCAG 2.4.11).
  static EdgeInsets padding(
    BuildContext context,
    EdgeInsets base, {
    double max = largeurMax,
    int boutonsFlottants = 0,
  }) {
    final avecMarge =
        base + EdgeInsets.symmetric(horizontal: marge(context, max: max));
    if (boutonsFlottants == 0) {
      return avecMarge;
    }
    final degagement = degagementBoutonFlottant * boutonsFlottants;
    return avecMarge.copyWith(bottom: math.max(avecMarge.bottom, degagement));
  }

  /// Hauteur d'un bouton flottant (56) + sa marge (16) + un espace d'air.
  static const double degagementBoutonFlottant = 88;
}

/// Centre [child] et limite sa largeur à [largeurMax] — pour les éléments
/// fixes (titres, barres de recherche, filtres) au-dessus d'une liste.
class ContenuCentre extends StatelessWidget {
  const ContenuCentre({
    super.key,
    required this.child,
    this.largeurMax = MiseEnPage.largeurMax,
  });

  final Widget child;
  final double largeurMax;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: largeurMax),
        // Pleine largeur disponible : l'enfant garde son alignement
        // (à gauche) au lieu d'être centré sur sa largeur intrinsèque.
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}
