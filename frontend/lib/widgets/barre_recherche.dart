import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Champ de recherche compact, style MarketScope (fond surface, focus vert).
class BarreRecherche extends StatelessWidget {
  const BarreRecherche({
    super.key,
    required this.controleur,
    required this.onChange,
    this.hint = 'Rechercher…',
    this.autofocus = false,
  });

  final TextEditingController controleur;
  final ValueChanged<String> onChange;
  final String hint;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkLine : AppColors.line,
        ),
      ),
      child: TextField(
        controller: controleur,
        autofocus: autofocus,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontFamily: AppFonts.sans, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 20,
            color: AppColors.textMuted,
          ),
          suffixIcon: controleur.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                  onPressed: () {
                    controleur.clear();
                    onChange('');
                  },
                ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onChanged: onChange,
      ),
    );
  }
}