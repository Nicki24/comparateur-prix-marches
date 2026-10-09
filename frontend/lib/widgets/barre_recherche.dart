import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_theme.dart';

class BarreRecherche extends StatelessWidget {
  const BarreRecherche({
    super.key,
    required this.controleur,
    required this.onChange,
    this.hint = 'Rechercher…',
    this.autofocus = false,
    this.enabled = true,
    this.onSubmitted,
  });

  final TextEditingController controleur;
  final ValueChanged<String> onChange;
  final String hint;
  final bool autofocus;
  final bool enabled;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
      decoration: BoxDecoration(
        color: enabled
            ? (isDark ? theme.colorScheme.surface : theme.colorScheme.surface)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isDark ? theme.dividerColor : theme.dividerColor,
        ),
        boxShadow: enabled ? theme.cardShadows : [],
      ),
      child: TextField(
        controller: controleur,
        autofocus: autofocus,
        enabled: enabled,
        textInputAction: TextInputAction.search,
        style: theme.textTheme.bodyMedium?.copyWith(fontFamily: AppFonts.sans),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            fontFamily: AppFonts.sans,
          ),
          prefixIcon: Icon(
            PhosphorIconsRegular.magnifyingGlass,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          suffixIcon: controleur.text.isEmpty
              ? null
              : IconButton(
                  icon: Icon(
                    PhosphorIconsRegular.x,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () {
                    controleur.clear();
                    onChange('');
                  },
                  tooltip: 'Effacer',
                ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: onChange,
        onSubmitted: onSubmitted,
      ),
    );
  }
}