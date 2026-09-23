import 'package:flutter/material.dart';

/// Apparition progressive + léger slide vertical.
/// Utilisée pour les cartes, sections, badges. Respecte
/// `accessibleNavigation` (pas d'animation si reduced-motion).
class MsApparition extends StatelessWidget {
  const MsApparition({
    super.key,
    required this.child,
    this.delai = Duration.zero,
    this.decalage = 12.0,
    this.duree = const Duration(milliseconds: 380),
  });

  final Widget child;
  final Duration delai;
  final double decalage;
  final Duration duree;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.of(context).accessibleNavigation;
    if (reduced) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duree + delai,
      curve: Curves.easeOutCubic,
      builder: (context, v, child) {
        // Retarde le démarrage sans bloquer le thread.
        final t = delai.inMilliseconds == 0
            ? v
            : ((v * (duree.inMilliseconds + delai.inMilliseconds) -
                        delai.inMilliseconds) /
                    duree.inMilliseconds)
                .clamp(0.0, 1.0);
        final eased = Curves.easeOutCubic.transform(t);
        return Opacity(
          opacity: eased,
          child: Transform.translate(
            offset: Offset(0, decalage * (1 - eased)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Enveloppe une liste pour un effet cascade léger.
/// `index` pilote le délai (max 6 paliers pour rester fluide).
class MsCascade extends StatelessWidget {
  const MsCascade({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palier = index.clamp(0, 6);
    return MsApparition(
      delai: Duration(milliseconds: palier * 45),
      child: child,
    );
  }
}
