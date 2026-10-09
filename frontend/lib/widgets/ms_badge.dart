import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_theme.dart';
import '../utils/formats.dart';

/// Badge de variation : baisse (vert) / hausse (terracotta) / neutre.
/// Toujours icône + texte (pas d'info portée uniquement par la couleur).
class MarketScopeVariationBadge extends StatelessWidget {
  const MarketScopeVariationBadge({
    super.key,
    required this.variationPct,
    this.compact = false,
  });

  final double variationPct;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stable = variationPct.abs() < 0.05;
    final baisse = !stable && variationPct < 0;
    final fond = stable
        ? theme.colorScheme.secondaryContainer
        : (baisse ? theme.okBg : theme.alertBg);
    final fg = stable
        ? theme.colorScheme.onSecondaryContainer
        : (baisse ? theme.okFg : theme.alertFg);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            stable
                ? PhosphorIconsRegular.minus
                : (baisse
                    ? PhosphorIconsRegular.arrowDown
                    : PhosphorIconsRegular.arrowUp),
            size: compact ? 11 : 12,
            color: fg,
            semanticLabel: stable
                ? 'Stable'
                : (baisse ? 'En baisse' : 'En hausse'),
          ),
          const SizedBox(width: 3),
          Text(
            formaterPourcentage(variationPct),
            style: TextStyle(
              fontFamily: AppFonts.mono,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge « Meilleur prix » / « Plus cher » pour la comparaison.
class MarketScopeRangBadge extends StatelessWidget {
  const MarketScopeRangBadge.meilleur({super.key}) : _meilleur = true;
  const MarketScopeRangBadge.cher({super.key}) : _meilleur = false;

  final bool _meilleur;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_meilleur) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: theme.okBg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIconsRegular.checkCircle,
                size: 11, color: theme.okFg),
            const SizedBox(width: 3),
            Text(
              'Meilleur prix',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: theme.okFg,
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: theme.alertBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Plus cher',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: theme.alertFg,
        ),
      ),
    );
  }
}
