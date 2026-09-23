import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Teintes lisibles sur le fond encre de la charte, quel que soit le thème.
const surEncre = Color(0xFFEAF3EE);
const attenueEncre = Color(0xFF9FB6AE);

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
      borderRadius: BorderRadius.circular(AppRadius.card),
      borderSide: const BorderSide(color: AppColors.line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.card),
      borderSide: const BorderSide(color: AppColors.line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.card),
      borderSide: const BorderSide(color: AppColors.green, width: 1.8),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.card),
      borderSide: const BorderSide(color: AppColors.terracotta),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.card),
      borderSide: BorderSide(color: AppColors.line.withValues(alpha: 0.5)),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}