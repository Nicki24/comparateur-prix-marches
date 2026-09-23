import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class Chargement extends StatelessWidget {
  const Chargement({super.key, this.nombreCartes = 4});

  final int nombreCartes;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: nombreCartes,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, __) => const _CarteSquelette(),
    );
  }
}

class ChargementCentre extends StatelessWidget {
  const ChargementCentre({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: Theme.of(context).colorScheme.primary,
        strokeWidth: 2.5,
      ),
    );
  }
}

class _CarteSquelette extends StatefulWidget {
  const _CarteSquelette();

  @override
  State<_CarteSquelette> createState() => _CarteSqueletteState();
}

class _CarteSqueletteState extends State<_CarteSquelette>
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
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final baseColor = isDark
            ? Color.lerp(theme.colorScheme.surface, theme.dividerColor, _animation.value)!
            : Color.lerp(theme.colorScheme.surface, theme.dividerColor, _animation.value)!;

        return Container(
          height: 72,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(theme.cardRadius),
            border: Border.all(color: theme.dividerColor),
            boxShadow: theme.cardShadows,
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark
                      ? Color.lerp(theme.dividerColor, theme.colorScheme.surface, _animation.value)!
                      : Color.lerp(theme.dividerColor, theme.colorScheme.surface, _animation.value)!,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
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
                            ? Color.lerp(theme.dividerColor, theme.colorScheme.surface, _animation.value)!
                            : Color.lerp(theme.dividerColor, theme.colorScheme.surface, _animation.value)!,
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      height: 11,
                      width: 160,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Color.lerp(theme.dividerColor, theme.colorScheme.surface, _animation.value)!
                            : Color.lerp(theme.dividerColor, theme.colorScheme.surface, _animation.value)!,
                        borderRadius: BorderRadius.circular(AppRadius.chip),
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

class ErreurMessage extends StatelessWidget {
  const ErreurMessage({super.key, required this.message, this.onReessayer});

  final String message;
  final VoidCallback? onReessayer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: _Apparition(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: theme.alertBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.alertFg.withValues(alpha: 0.25),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.alertFg.withValues(alpha: 0.14),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.cloud_off_rounded,
                  size: 34,
                  color: theme.alertFg,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Connexion impossible',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (onReessayer != null) ...[
                const SizedBox(height: AppSpacing.lg),
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
        padding: const EdgeInsets.all(AppSpacing.xl),
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
                        ? [theme.colorScheme.surfaceContainerHighest, theme.colorScheme.surface]
                        : [theme.colorScheme.surfaceContainerHighest, theme.colorScheme.surface],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.dividerColor,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  icone,
                  size: 36,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (titre != null) ...[
                Text(
                  titre!,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (cta != null && onCta != null) ...[
                const SizedBox(height: AppSpacing.lg),
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