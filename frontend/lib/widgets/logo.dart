import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'marketscope_header.dart';

const _assetLogo = 'assets/marketscope_logo_round.png';

/// Marque circulaire MarketScope (icône seule).
class LogoMarque extends StatelessWidget {
  const LogoMarque({super.key, this.taille = 40, this.ombre = false});

  final double taille;

  /// Ajoute une ombre douce (utile sur fonds clairs : profil, login…).
  final bool ombre;

  @override
  Widget build(BuildContext context) {
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

/// Lockup vertical : marque + wordmark + sous-titre facultatif.
///
/// Le wordmark s'adapte au fond : si [couleurTexte] est claire (texte posé
/// sur un fond encre), la variante « fond sombre » est utilisée.
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
    final surFondSombre = couleurTexte != null
        ? couleurTexte!.computeLuminance() > 0.5
        : theme.brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LogoMarque(taille: tailleLogo, ombre: true),
        const SizedBox(height: 16),
        MarketScopeWordmark(taille: 30, surFondSombre: surFondSombre),
        if (sousTitre != null) ...[
          const SizedBox(height: 8),
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
