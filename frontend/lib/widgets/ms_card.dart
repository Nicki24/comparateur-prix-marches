import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'tap_scale.dart';

/// Carte standard MarketScope : fond blanc / sombre adapté,
/// bordure très légère, radius 12, ombre légère, padding cohérent.
///
/// Variantes : [MarketScopeCard], [MarketScopeStatCard],
/// [MarketScopeChartCard], [MarketScopeSectionTitle].
class MarketScopeCard extends StatelessWidget {
  const MarketScopeCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
    this.couleur,
    this.bordure,
    this.sansOmbre = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? couleur;
  final Color? bordure;
  final bool sansOmbre;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fond = couleur ??
        (isDark ? AppColors.darkSurface : AppColors.white);
    final couleurBordure =
        bordure ?? (isDark ? AppColors.darkLine : AppColors.line);

    final contenu = Container(
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: couleurBordure),
        boxShadow: sansOmbre ? null : theme.cardShadows,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    if (onTap != null) {
      return TapScale(child: contenu);
    }
    return contenu;
  }
}

/// Carte statistique : icône + valeur mono + label.
class MarketScopeStatCard extends StatelessWidget {
  const MarketScopeStatCard({
    super.key,
    required this.icone,
    required this.couleur,
    required this.valeur,
    required this.label,
    this.sousValeur,
    this.onTap,
  });

  final IconData icone;
  final Color couleur;
  final String valeur;
  final String label;
  final Widget? sousValeur;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MarketScopeCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: couleur.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icone, size: 18, color: couleur),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            valeur,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.priceMedium.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.3,
            ),
          ),
          if (sousValeur != null) ...[
            const SizedBox(height: 6),
            sousValeur!,
          ],
        ],
      ),
    );
  }
}

/// Carte graphique : titre + sous-titre + contenu chart.
class MarketScopeChartCard extends StatelessWidget {
  const MarketScopeChartCard({
    super.key,
    required this.titre,
    this.sousTitre,
    required this.child,
    this.action,
  });

  final String titre;
  final String? sousTitre;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MarketScopeCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 30,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titre,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (sousTitre != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        sousTitre!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

/// Titre de section : barre verte + icône + label mono + action.
class MarketScopeSectionTitle extends StatelessWidget {
  const MarketScopeSectionTitle({
    super.key,
    required this.titre,
    this.icone,
    this.actionLabel,
    this.onAction,
    this.padding =
        const EdgeInsets.symmetric(horizontal: AppSpacing.md),
  });

  final String titre;
  final IconData? icone;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Marge externe (zéro si le parent padde déjà, ex. item de ListView).
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          if (icone != null) ...[
            const SizedBox(width: 8),
            Icon(icone, size: 18, color: theme.colorScheme.primary),
          ],
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              titre.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontFamily: AppFonts.mono,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(48, 36),
              ),
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}
