import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Asset du badge rond MarketScope (logo officiel complet).
const _assetBadge = 'assets/marketscope_logo_round.png';

/// Wordmark « MarketScope » rendu en texte vectoriel (Space Grotesk Bold).
///
/// Remplace l'ancien PNG : « Market » y était en bleu marine, donc
/// invisible sur le header marine, et le fichier contenait ~35 % de marges
/// vides qui rendaient les lettres minuscules. Le texte vectoriel reste net
/// à toutes les tailles, est lu par les lecteurs d'écran et adapte ses
/// couleurs au fond :
///
/// * fond sombre (header, héros encre) : « Market » blanc cassé,
///   « Scope » vert clair ;
/// * fond clair : « Market » encre, « Scope » vert de marque.
class MarketScopeWordmark extends StatelessWidget {
  const MarketScopeWordmark({
    super.key,
    this.taille = 20,
    this.surFondSombre = true,
  });

  /// Taille de police (hauteur visuelle ≈ 0,72 × taille).
  final double taille;

  final bool surFondSombre;

  @override
  Widget build(BuildContext context) {
    final couleurMarket = surFondSombre ? AppColors.paper : AppColors.ink;
    final couleurScope =
        surFondSombre ? AppColors.greenLight : AppColors.green;
    final style = TextStyle(
      fontFamily: AppFonts.display,
      fontWeight: FontWeight.w700,
      fontSize: taille,
      height: 1.0,
      letterSpacing: -0.03 * taille,
    );
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'Market', style: style.copyWith(color: couleurMarket)),
          TextSpan(text: 'Scope', style: style.copyWith(color: couleurScope)),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.fade,
      softWrap: false,
      semanticsLabel: 'MarketScope',
    );
  }
}

/// Badge rond officiel, cerclé d'un liseré clair pour se détacher du marine.
class MarketScopeBadge extends StatelessWidget {
  const MarketScopeBadge({super.key, this.taille = 32});

  final double taille;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: taille,
      height: taille,
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white,
        border: Border.all(
          color: AppColors.greenLight.withValues(alpha: 0.55),
        ),
      ),
      child: ClipOval(
        child: Image.asset(
          _assetBadge,
          fit: BoxFit.cover,
          excludeFromSemantics: true,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}

/// Header global MarketScope.
///
/// * Onglets racine (sans [titre]) : badge + wordmark de marque.
/// * Pages empilées (avec [titre]) : bouton retour + titre de la page
///   (et [sousTitre] facultatif) — l'utilisateur sait toujours où il est.
///
/// Fond marine du thème, hauteur standard, fine ligne d'accent en bas.
class MarketScopeHeader extends StatelessWidget
    implements PreferredSizeWidget {
  const MarketScopeHeader({
    super.key,
    this.titre,
    this.sousTitre,
    this.actions,
    this.bottom,
  });

  /// Titre de page (pages empilées). `null` → affiche la marque.
  final String? titre;

  final String? sousTitre;

  /// Actions contextuelles à droite (avec `tooltip`).
  final List<Widget>? actions;

  /// Élément sous la barre (onglets).
  final PreferredSizeWidget? bottom;

  static const double hauteurBarre = kToolbarHeight;

  @override
  Size get preferredSize =>
      Size.fromHeight(hauteurBarre + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final Widget titreWidget;
    if (titre == null) {
      titreWidget = Semantics(
        header: true,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MarketScopeBadge(),
            SizedBox(width: 10),
            Flexible(child: MarketScopeWordmark(taille: 21)),
          ],
        ),
      );
    } else {
      titreWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            titre!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w700,
              fontSize: 18,
              height: 1.2,
              color: AppColors.paper,
            ),
          ),
          if (sousTitre != null)
            Text(
              sousTitre!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppFonts.sans,
                fontSize: 12,
                height: 1.3,
                color: AppColors.paper.withValues(alpha: 0.65),
              ),
            ),
        ],
      );
    }

    return AppBar(
      backgroundColor: AppColors.ink,
      foregroundColor: AppColors.paper,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: false,
      titleSpacing: titre == null ? AppSpacing.md : 0,
      title: titreWidget,
      actions: [
        ...?actions,
        const SizedBox(width: AppSpacing.xs),
      ],
      shape: Border(
        bottom: BorderSide(color: AppColors.paper.withValues(alpha: 0.06)),
      ),
      bottom: bottom,
    );
  }
}
