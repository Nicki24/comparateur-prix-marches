import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum StatutBadgeType { ok, alerte, obsolete, neutre }

class StatutBadge extends StatelessWidget {
  const StatutBadge({super.key, required this.type, required this.libelle});

  const StatutBadge.ok(this.libelle, {super.key}) : type = StatutBadgeType.ok;

  const StatutBadge.alerte(this.libelle, {super.key}) : type = StatutBadgeType.alerte;

  const StatutBadge.obsolete(this.libelle, {super.key}) : type = StatutBadgeType.obsolete;

  const StatutBadge.neutre(this.libelle, {super.key}) : type = StatutBadgeType.neutre;

  final StatutBadgeType type;
  final String libelle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (fond, premierPlan) = switch (type) {
      StatutBadgeType.ok => (theme.okBg, theme.okFg),
      StatutBadgeType.alerte => (theme.alertBg, theme.alertFg),
      StatutBadgeType.obsolete => (theme.staleBg, theme.staleFg),
      StatutBadgeType.neutre => (
          theme.colorScheme.secondaryContainer,
          theme.colorScheme.onSecondaryContainer,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(AppRadius.pill),
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