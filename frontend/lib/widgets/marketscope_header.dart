import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/mise_en_page.dart';
import 'actions_header.dart';
import 'navigation_principale.dart';

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
/// Sur les onglets racine, les boutons Aide et Thème sont ajoutés
/// automatiquement après les [actions] propres à l'écran.
///
/// Fond marine du thème, fine ligne d'accent en bas.
///
/// Deux formats selon la largeur de la fenêtre (voir [MiseEnPage.estLarge]) :
/// * compact (téléphone) : barre standard de 56 px, badge 32 px ;
/// * large (plein écran) : barre de 76 px, badge et wordmark agrandis,
///   accroche sous la marque, et contenu aligné sur la colonne centrale.
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
  static const double hauteurBarreLarge = 76;

  /// `preferredSize` n'a pas accès au contexte : la largeur est lue sur la
  /// fenêtre. Le Scaffold se reconstruit quand elle change.
  static bool get _fenetreLarge {
    final vue = WidgetsBinding.instance.platformDispatcher.implicitView;
    if (vue == null) return false;
    return vue.physicalSize.width / vue.devicePixelRatio >=
        MiseEnPage.seuilLarge;
  }

  @override
  Size get preferredSize => Size.fromHeight(
      (_fenetreLarge ? hauteurBarreLarge : hauteurBarre) +
          (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final large = MiseEnPage.estLarge(context);
    // Onglets racine sur desktop : la navigation principale vit ici.
    final navigation = titre == null && MiseEnPage.estBureau(context)
        ? NavigationPrincipale.maybeOf(context)
        : null;
    final Widget titreWidget;
    if (navigation != null) {
      titreWidget = Row(
        children: [
          Semantics(
            header: true,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MarketScopeBadge(taille: 44),
                SizedBox(width: 12),
                MarketScopeWordmark(taille: 26),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: LiensNavigationHeader(navigation: navigation),
          ),
        ],
      );
    } else if (titre == null) {
      titreWidget = Semantics(
        header: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MarketScopeBadge(taille: large ? 48 : 32),
            SizedBox(width: large ? 14 : 10),
            Flexible(
              child: large
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const MarketScopeWordmark(taille: 28),
                        const SizedBox(height: 5),
                        Text(
                          'Comparez les prix des marchés de Toliara',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppFonts.sans,
                            fontSize: 12.5,
                            height: 1.2,
                            color: AppColors.paper.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    )
                  : const MarketScopeWordmark(taille: 21),
            ),
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
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w700,
              fontSize: large ? 22 : 18,
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
                fontSize: large ? 13.5 : 12,
                height: 1.3,
                color: AppColors.paper.withValues(alpha: 0.65),
              ),
            ),
        ],
      );
    }

    // Sur grand écran, logo / bouton retour et actions sont alignés sur
    // les bords du contenu centré plutôt que sur ceux de la fenêtre.
    final marge = MiseEnPage.marge(context);
    final retour = titre != null &&
        (ModalRoute.of(context)?.impliesAppBarDismissal ?? false);

    return AppBar(
      backgroundColor: AppColors.ink,
      foregroundColor: AppColors.paper,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: false,
      toolbarHeight: large ? hauteurBarreLarge : hauteurBarre,
      iconTheme: IconThemeData(size: large ? 26 : 24),
      actionsIconTheme: IconThemeData(size: large ? 26 : 24),
      leading: retour && marge > 0
          ? Padding(
              padding: EdgeInsets.only(left: marge),
              child: const BackButton(),
            )
          : null,
      leadingWidth: retour && marge > 0 ? kToolbarHeight + marge : null,
      // La marge de centrage passe par un Padding et non par titleSpacing :
      // AppBar retire titleSpacing deux fois de la largeur du titre, ce
      // qui l'étranglait sur grand écran (onglets en débordement).
      titleSpacing: 0,
      title: titre == null
          ? Padding(
              padding: EdgeInsets.only(left: AppSpacing.md + marge),
              child: titreWidget,
            )
          : titreWidget,
      actions: [
        ...?actions,
        if (titre == null) ...const [BoutonAide(), BoutonTheme()],
        SizedBox(width: (large ? AppSpacing.sm : AppSpacing.xs) + marge),
      ],
      shape: Border(
        bottom: BorderSide(color: AppColors.paper.withValues(alpha: 0.06)),
      ),
      bottom: bottom,
    );
  }
}
