import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Types de statut inspirés de la charte : valide (vert), alerte (terracotta),
/// obsolète (safran) et inactif/neutre (gris).
enum StatutBadgeType { ok, alerte, obsolete, neutre }

/// Pastille de statut conforme à la charte graphique.
class StatutBadge extends StatelessWidget {
  const StatutBadge({super.key, required this.type, required this.libelle});

  const StatutBadge.ok(this.libelle, {super.key})
      : type = StatutBadgeType.ok;

  const StatutBadge.alerte(this.libelle, {super.key})
      : type = StatutBadgeType.alerte;

  const StatutBadge.obsolete(this.libelle, {super.key})
      : type = StatutBadgeType.obsolete;

  const StatutBadge.neutre(this.libelle, {super.key})
      : type = StatutBadgeType.neutre;

  final StatutBadgeType type;
  final String libelle;

  @override
  Widget build(BuildContext context) {
    final (fond, premierPlan) = switch (type) {
      StatutBadgeType.ok => (AppColors.okBg, AppColors.okFg),
      StatutBadgeType.alerte => (AppColors.alertBg, AppColors.alertFg),
      StatutBadgeType.obsolete => (AppColors.staleBg, AppColors.staleFg),
      StatutBadgeType.neutre => (
          Theme.of(context).colorScheme.secondaryContainer,
          Theme.of(context).colorScheme.onSecondaryContainer,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        libelle,
        style: TextStyle(
          fontFamily: AppFonts.sans,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: premierPlan,
        ),
      ),
    );
  }
}