import 'package:flutter/material.dart';

/// Affiche une valeur numérique avec une animation de comptage depuis zéro
/// (ou depuis l'ancienne valeur si elle change). Effet « tableau de bord ».
class CompteurAnime extends StatelessWidget {
  const CompteurAnime({
    super.key,
    required this.valeur,
    required this.style,
    required this.formater,
    this.duree = const Duration(milliseconds: 900),
  });

  final num valeur;
  final TextStyle style;
  final String Function(num) formater;
  final Duration duree;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: valeur.toDouble()),
      duration: duree,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(formater(v), style: style),
    );
  }
}