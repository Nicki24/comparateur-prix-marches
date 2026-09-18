import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

const _assetLogo = 'assets/marketscope_logo_round.png';

/// Marque circulaire MarketScope (icône seule).
///
/// Le PNG source est un vrai disque (fond transparent) : aucune retouche
/// de fond ou de mise à l'échelle n'est nécessaire, la transparence est
/// préservée sur n'importe quel fond (AppBar encre, cartes, etc.).
class LogoMarque extends StatelessWidget {
  const LogoMarque({super.key, this.taille = 40, this.ombre = false});

  final double taille;

  /// Ajoute une ombre douce (utile sur fonds clairs : profil, login…).
  final bool ombre;

  @override
  Widget build(BuildContext context) {
    // Margeur carré 1:1 + masque circulaire : le disque du logo reste
    // parfaitement rond quel que soit le conteneur parent (rien ne peut
    // l'étirer horizontalement ou verticalement).
    final rond = SizedBox(
      width: taille,
      height: taille,
      child: ClipOval(
        child: Image.asset(_assetLogo, fit: BoxFit.cover),
      ),
    );
    if (!ombre) {
      return rond;
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: rond,
    );
  }
}

/// Lockup de barre d'app : logo rond + wordmark « MarketScope » bicolore,
/// suivi du titre de la page courante (rétracté avec ellipsis si l'espace
/// manque). Conçu pour l'AppBar encre (textes clairs).
class MarqueHeader extends StatelessWidget {
  const MarqueHeader({
    super.key,
    this.titre,
    this.tailleLogo = 36,
  });

  final String? titre;

  /// Taille du logo rond (carré 1:1).
  final double tailleLogo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const styleMot = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w800,
      height: 1.1,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LogoMarque(taille: tailleLogo),
        const SizedBox(width: 10),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Market', style: styleMot.copyWith(color: AppColors.paper)),
              Text(
                'Scope',
                style: styleMot.copyWith(color: AppColors.greenLight),
              ),
              if (titre != null) ...[
                const SizedBox(width: 12),
                Container(
                  width: 1,
                  height: 22,
                  color: AppColors.paper.withValues(alpha: 0.25),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    titre!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.paper.withValues(alpha: 0.92),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Lockup : marque + wordmark « MarketScope ».
class MarqueComplete extends StatelessWidget {
  const MarqueComplete({
    super.key,
    this.sousTitre,
    this.couleurTexte,
    this.couleurSousTitre,
    this.tailleLogo = 88,
  });

  final String? sousTitre;
  final Color? couleurTexte;
  final Color? couleurSousTitre;
  final double tailleLogo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final couleurTitre = couleurTexte ??
        (Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkText
            : AppColors.ink);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LogoMarque(taille: tailleLogo, ombre: true),
        const SizedBox(height: 16),
        Text(
          'MarketScope',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: couleurTitre,
          ),
        ),
        if (sousTitre != null) ...[
          const SizedBox(height: 6),
          Text(
            sousTitre!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: couleurSousTitre ?? theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}