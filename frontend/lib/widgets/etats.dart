import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// ===========================================================================
// CHARGEMENT
// ===========================================================================

/// Indicateur de chargement MarketScope : shimmer de cartes squelette.
class Chargement extends StatelessWidget {
  const Chargement({super.key, this.nombreCartes = 4});

  final int nombreCartes;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: nombreCartes,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => const _CarteSqelette(),
    );
  }
}

/// Indicateur de chargement centré (pour les vues non-liste).
class ChargementCentre extends StatelessWidget {
  const ChargementCentre({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.green,
        strokeWidth: 2.5,
      ),
    );
  }
}

/// Carte squelette animée avec effet shimmer.
class _CarteSqelette extends StatefulWidget {
  const _CarteSqelette();

  @override
  State<_CarteSqelette> createState() => _CarteSqeletteState();
}

class _CarteSqeletteState extends State<_CarteSqelette>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final baseColor = isDark
            ? Color.lerp(AppColors.darkPaper2, AppColors.darkLine, _animation.value)!
            : Color.lerp(AppColors.paper2, AppColors.line, _animation.value)!;

        return Container(
          height: 72,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? AppColors.darkLine : AppColors.line),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Avatar squelette
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark
                      ? Color.lerp(AppColors.darkLine, AppColors.darkPaper2, _animation.value)!
                      : Color.lerp(AppColors.line, AppColors.paper2, _animation.value)!,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 14),
              // Lignes squelette
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 13,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Color.lerp(AppColors.darkLine, AppColors.darkPaper2, _animation.value)!
                            : Color.lerp(AppColors.line, AppColors.paper2, _animation.value)!,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 11,
                      width: 160,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Color.lerp(AppColors.darkLine, AppColors.darkPaper2, _animation.value)!
                            : Color.lerp(AppColors.line, AppColors.paper2, _animation.value)!,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ===========================================================================
// ERREUR
// ===========================================================================

/// Message d'erreur avec bouton « Réessayer », style MarketScope.
class ErreurMessage extends StatelessWidget {
  const ErreurMessage({super.key, required this.message, this.onReessayer});

  final String message;
  final VoidCallback? onReessayer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: _Apparition(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.alertBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.alertFg.withValues(alpha: 0.25),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.alertFg.withValues(alpha: 0.14),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  size: 34,
                  color: AppColors.alertFg,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Connexion impossible',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (onReessayer != null) ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onReessayer,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Réessayer'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// CONTENU VIDE
// ===========================================================================

/// État vide enrichi avec icône stylée et message contextualisé.
class ContenuVide extends StatelessWidget {
  const ContenuVide({
    super.key,
    required this.message,
    this.icone = Icons.inbox_rounded,
    this.titre,
    this.cta,
    this.onCta,
  });

  final String message;
  final IconData icone;
  final String? titre;
  final String? cta;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: _Apparition(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [AppColors.darkPaper2, AppColors.darkSurface]
                        : [AppColors.paper2, AppColors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.darkLine : AppColors.line,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ink.withValues(alpha: 0.1),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  icone,
                  size: 36,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 20),
              if (titre != null) ...[
                Text(
                  titre!,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (cta != null && onCta != null) ...[
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: onCta,
                  child: Text(cta!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Fondu + glissement doux à l'apparition des états (erreur, vide…).
class _Apparition extends StatelessWidget {
  const _Apparition({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - v)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}