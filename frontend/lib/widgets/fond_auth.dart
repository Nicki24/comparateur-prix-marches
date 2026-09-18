import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Teintes du fond encre de la charte, lisibles quel que soit le thème.
const surEncre = Color(0xFFEAF3EE);
const attenueEncre = Color(0xFF9FB6AE);

/// Fond lisse en dégradé (encre → encre foncée) avec halos colorés,
/// utilisé sur les écrans d'authentification.
class FondEncre extends StatelessWidget {
  const FondEncre({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.ink, AppColors.ink2, Color(0xFF0A1F2A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: HaloAuth(couleur: AppColors.greenLight, taille: 260),
          ),
          Positioned(
            bottom: -110,
            left: -80,
            child: HaloAuth(couleur: AppColors.saffron, taille: 230),
          ),
        ],
      ),
    );
  }
}

/// Halo décoratif doux (dégradé radial).
class HaloAuth extends StatelessWidget {
  const HaloAuth({super.key, required this.couleur, required this.taille});

  final Color couleur;
  final double taille;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: taille,
      height: taille,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            couleur.withValues(alpha: 0.14),
            couleur.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}

/// Décoration des champs authentification : fond blanc sur l'encre,
/// focus au vert charte.
InputDecoration decoAuth({
  required IconData icone,
  required String label,
  String? hint,
}) {
  return InputDecoration(
    filled: true,
    fillColor: Colors.white,
    labelText: label,
    hintText: hint,
    prefixIcon: Icon(icone),
    prefixIconColor: AppColors.textMuted,
    labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
    hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.7)),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.green, width: 1.8),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.terracotta),
    ),
  );
}