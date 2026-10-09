import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_theme.dart';

/// Un onglet de la navigation principale.
class DestinationNav {
  const DestinationNav({
    required this.icone,
    required this.iconeActive,
    required this.label,
    this.tooltip,
  });

  final IconData icone;
  final IconData iconeActive;
  final String label;
  final String? tooltip;
}

/// Les 5 onglets racine, partagés par la barre du bas (téléphone) et les
/// liens du header (desktop).
const destinationsPrincipales = [
  DestinationNav(
    icone: PhosphorIconsRegular.house,
    iconeActive: PhosphorIconsFill.house,
    label: 'Accueil',
  ),
  DestinationNav(
    icone: PhosphorIconsRegular.storefront,
    iconeActive: PhosphorIconsFill.storefront,
    label: 'Marchés',
  ),
  DestinationNav(
    icone: PhosphorIconsRegular.basket,
    iconeActive: PhosphorIconsFill.basket,
    label: 'Produits',
  ),
  DestinationNav(
    icone: PhosphorIconsRegular.receipt,
    iconeActive: PhosphorIconsFill.receipt,
    label: 'Relevés',
    tooltip: 'Mes relevés',
  ),
  DestinationNav(
    icone: PhosphorIconsRegular.user,
    iconeActive: PhosphorIconsFill.user,
    label: 'Profil',
  ),
];

/// Expose l'onglet actif aux écrans racine : sur grand écran, leur header
/// affiche alors les onglets (voir [LiensNavigationHeader]).
class NavigationPrincipale extends InheritedWidget {
  const NavigationPrincipale({
    super.key,
    required this.index,
    required this.onSelection,
    required super.child,
  });

  final int index;
  final ValueChanged<int> onSelection;

  static NavigationPrincipale? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NavigationPrincipale>();

  @override
  bool updateShouldNotify(NavigationPrincipale oldWidget) =>
      index != oldWidget.index || onSelection != oldWidget.onSelection;
}

/// Onglets affichés dans le header marine sur desktop.
class LiensNavigationHeader extends StatelessWidget {
  const LiensNavigationHeader({super.key, required this.navigation});

  final NavigationPrincipale navigation;

  static const _espacement = 4.0;

  /// Style du libellé, partagé avec la mesure de largeur.
  static TextStyle styleLibelle({required bool actif, Color? couleur}) =>
      TextStyle(
        fontFamily: AppFonts.sans,
        fontSize: 14,
        fontWeight: actif ? FontWeight.w600 : FontWeight.w500,
        color: couleur,
      );

  /// Largeur des onglets avec libellés, mesurée avec la vraie police et
  /// le facteur de taille de texte de l'utilisateur.
  double _largeurAvecLibelles(BuildContext context) {
    final echelle = MediaQuery.textScalerOf(context);
    var total = _espacement * (destinationsPrincipales.length - 1);
    for (final d in destinationsPrincipales) {
      final mesure = TextPainter(
        text: TextSpan(text: d.label, style: styleLibelle(actif: true)),
        textDirection: TextDirection.ltr,
        textScaler: echelle,
        maxLines: 1,
      )..layout();
      total += _LienNav.margesAvecLibelle + mesure.width;
      mesure.dispose();
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, contraintes) {
        // Les libellés ne tiennent pas (fenêtre étroite, zoom navigateur,
        // grand texte) : icônes seules, libellé en infobulle.
        final compact =
            _largeurAvecLibelles(context) > contraintes.maxWidth;
        final liens = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < destinationsPrincipales.length; i++) ...[
              if (i > 0) const SizedBox(width: _espacement),
              _LienNav(
                destination: destinationsPrincipales[i],
                actif: i == navigation.index,
                compact: compact,
                onTap: () => navigation.onSelection(i),
              ),
            ],
          ],
        );
        // Filet de sécurité : jamais de débordement (qui rendrait les
        // derniers onglets impossibles à cliquer), au pire une réduction.
        return Center(
          child: FittedBox(fit: BoxFit.scaleDown, child: liens),
        );
      },
    );
  }
}

class _LienNav extends StatelessWidget {
  const _LienNav({
    required this.destination,
    required this.actif,
    required this.compact,
    required this.onTap,
  });

  /// Padding horizontal (2 × 14) + icône (20) + espace (8).
  static const double margesAvecLibelle = 2 * 14 + 20 + 8;

  final DestinationNav destination;
  final bool actif;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final couleurTexte =
        actif ? AppColors.paper : AppColors.paper.withValues(alpha: 0.72);
    final icone = Icon(
      actif ? destination.iconeActive : destination.icone,
      size: 20,
      color: actif ? AppColors.greenLight : couleurTexte,
    );
    final lien = Semantics(
      button: true,
      selected: actif,
      label: compact ? destination.label : null,
      child: Material(
        color: actif
            ? AppColors.paper.withValues(alpha: 0.10)
            : Colors.transparent,
        shape: const StadiumBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          hoverColor: AppColors.paper.withValues(alpha: 0.06),
          focusColor: AppColors.greenLight.withValues(alpha: 0.22),
          splashColor: AppColors.greenLight.withValues(alpha: 0.12),
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: compact ? 12 : 14, vertical: 10),
            child: compact
                ? icone
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      icone,
                      const SizedBox(width: 8),
                      Text(
                        destination.label,
                        maxLines: 1,
                        softWrap: false,
                        style: LiensNavigationHeader.styleLibelle(
                            actif: actif, couleur: couleurTexte),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
    final infobulle =
        compact ? destination.tooltip ?? destination.label : destination.tooltip;
    if (infobulle == null) return lien;
    return Tooltip(message: infobulle, child: lien);
  }
}
