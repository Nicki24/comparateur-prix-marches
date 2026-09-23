import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Arrière-plan décoratif subtil pour les écrans clairs/sombres.
///
/// Formes générées en code (CustomPainter) : grands arcs, cercles
/// partiellement visibles, lignes courbes. Opacité 8–15 %, derrière
/// le contenu, ne gêne jamais la lecture.
class MsDecorFond extends StatelessWidget {
  const MsDecorFond({super.key, this.child, this.densite = 1.0});

  final Widget? child;
  final double densite;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _DecorPainter(
                isDark: isDark,
                densite: densite,
              ),
            ),
          ),
        ),
        if (child != null) Positioned.fill(child: child!),
      ],
    );
  }
}

/// Peintre : 2 cercles partiels + 1 arc + lignes fines, très faible opacité.
class _DecorPainter extends CustomPainter {
  _DecorPainter({required this.isDark, this.densite = 1.0});

  final bool isDark;
  final double densite;

  @override
  void paint(Canvas canvas, Size size) {
    final base = isDark ? AppColors.darkGreenLight : AppColors.green;
    final navy = isDark ? AppColors.darkTextMuted : AppColors.ink;

    // Cercle haut-droit partiellement visible (8 %).
    final p1 = Paint()
      ..color = base.withValues(alpha: 0.08 * densite)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 1.02, -size.height * 0.06),
      size.width * 0.42,
      p1,
    );

    // Anneau fin autour du cercle (12 %).
    final p2 = Paint()
      ..color = base.withValues(alpha: 0.12 * densite)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(
      Offset(size.width * 1.02, -size.height * 0.06),
      size.width * 0.52,
      p2,
    );

    // Cercle bas-gauche (6 %).
    final p3 = Paint()
      ..color = navy.withValues(alpha: isDark ? 0.10 : 0.06)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(-size.width * 0.18, size.height * 0.92),
      size.width * 0.36,
      p3,
    );

    // Arc organique fin traversant le fond.
    final p4 = Paint()
      ..color = base.withValues(alpha: 0.10 * densite)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final path = Path()
      ..moveTo(-20, size.height * 0.22)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.16,
        size.width * 0.62,
        size.height * 0.26,
      );
    canvas.drawPath(path, p4);

    // Petite pastille décorative (saffron 10 %).
    final p5 = Paint()
      ..color = (isDark ? AppColors.darkSaffron : AppColors.saffron)
          .withValues(alpha: 0.10 * densite)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.12, size.height * 0.34),
      5,
      p5,
    );
  }

  @override
  bool shouldRepaint(covariant _DecorPainter old) =>
      old.isDark != isDark || old.densite != densite;
}

/// Décor discret pour les headers navy : halos + arc fin.
class MsHeaderDecor extends StatelessWidget {
  const MsHeaderDecor({super.key});

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        Positioned(
          top: -70,
          right: -50,
          child: _Halo(couleur: AppColors.greenLight, taille: 180, opacite: 0.13),
        ),
        Positioned(
          bottom: -90,
          left: -40,
          child: _Halo(couleur: AppColors.saffron, taille: 150, opacite: 0.09),
        ),
      ],
    );
  }
}

class _Halo extends StatelessWidget {
  const _Halo({required this.couleur, required this.taille, required this.opacite});

  final Color couleur;
  final double taille;
  final double opacite;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: taille,
      height: taille,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            couleur.withValues(alpha: opacite),
            couleur.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}
