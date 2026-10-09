import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_theme.dart';

/// Icônes produits cohérentes : style outline, vectoriel simple.
/// Une seule famille (Material Rounded), fond teinté 12 %, coins 12.
///
/// Catégories reconnues : céréales, légumes, fruits, viande, poisson,
/// huiles, produits emballés / hygiène, boissons, épices.
class ProduitIcone extends StatelessWidget {
  const ProduitIcone({
    super.key,
    required this.nom,
    this.categorie,
    this.taille = 44,
    this.tailleIcone = 22,
  });

  final String nom;
  final String? categorie;
  final double taille;
  final double tailleIcone;

  @override
  Widget build(BuildContext context) {
    final res = ProduitStyle.resoudre(nom, categorie);
    return Container(
      width: taille,
      height: taille,
      decoration: BoxDecoration(
        color: res.couleur.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(res.icone, color: res.couleur, size: tailleIcone),
    );
  }
}

class ProduitStyle {
  const ProduitStyle({required this.icone, required this.couleur});

  final IconData icone;
  final Color couleur;

  static ProduitStyle resoudre(String nom, String? categorie) {
    final brut = '${nom.toLowerCase()} ${categorie ?? ''}'.toLowerCase();

    // Riz / céréales.
    if (_contient(brut, ['riz', 'céréale', 'cereale', 'farine', 'blé', 'ble', 'maïs', 'mais'])) {
      return const ProduitStyle(
          icone: PhosphorIconsRegular.grains, couleur: Color(0xFFB7791F));
    }
    // Huiles.
    if (_contient(brut, ['huile', 'huile alimentaire'])) {
      return const ProduitStyle(
          icone: PhosphorIconsRegular.drop, couleur: Color(0xFFC9930A));
    }
    // Légumes : tomate, oignon…
    if (_contient(brut, ['tomate', 'oignon', 'légume', 'legume', 'carotte', 'pomme de terre', 'brède', 'brede', 'chou'])) {
      return const ProduitStyle(
          icone: PhosphorIconsRegular.carrot, couleur: Color(0xFF2DA44E));
    }
    // Fruits.
    if (_contient(brut, ['fruit', 'banane', 'mangue', 'orange', 'pomme', 'ananas'])) {
      return const ProduitStyle(
          icone: PhosphorIconsRegular.orangeSlice, couleur: Color(0xFF2DA44E));
    }
    // Viande.
    if (_contient(brut, ['viande', 'bœuf', 'boeuf', 'porc', 'poulet', 'zébu', 'zebu'])) {
      return const ProduitStyle(
          icone: PhosphorIconsRegular.cookingPot, couleur: AppColors.terracotta);
    }
    // Poisson.
    if (_contient(brut, ['poisson', 'thon', 'carpe', 'tilapia'])) {
      return const ProduitStyle(
          icone: PhosphorIconsRegular.fish, couleur: Color(0xFF1D6FA5));
    }
    // Haricot / sucre.
    if (_contient(brut, ['haricot', 'lentille', 'pois'])) {
      return const ProduitStyle(
          icone: PhosphorIconsRegular.plant, couleur: Color(0xFF2DA44E));
    }
    if (_contient(brut, ['sucre', 'sel'])) {
      return const ProduitStyle(
          icone: PhosphorIconsRegular.hexagon, couleur: Color(0xFF8A6D1B));
    }
    // Hygiène / emballés.
    if (_contient(brut, ['savon', 'hygièn', 'hygien', 'nettoyage', 'emballé', 'emballe'])) {
      return const ProduitStyle(
          icone: PhosphorIconsRegular.sprayBottle, couleur: Color(0xFF6B7C8D));
    }
    // Boissons.
    if (_contient(brut, ['boisson', 'eau', 'jus'])) {
      return const ProduitStyle(
          icone: PhosphorIconsRegular.pintGlass, couleur: Color(0xFF1D6FA5));
    }
    // Épices.
    if (_contient(brut, ['épice', 'epice', 'poivre', 'curry', 'condiment'])) {
      return const ProduitStyle(
          icone: PhosphorIconsRegular.plant, couleur: AppColors.saffron);
    }
    // Défaut alimentaire.
    return const ProduitStyle(
        icone: PhosphorIconsRegular.basket, couleur: AppColors.green);
  }

  static bool _contient(String brut, List<String> mots) {
    for (final m in mots) {
      if (brut.contains(m)) return true;
    }
    return false;
  }
}
