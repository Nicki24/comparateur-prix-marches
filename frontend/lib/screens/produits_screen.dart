import 'package:flutter/material.dart';

import '../models/produit.dart';
import '../services/produit_service.dart';
import '../theme/app_theme.dart';
import '../widgets/barre_recherche.dart';
import '../widgets/etats.dart';
import '../widgets/logo.dart';
import '../widgets/tap_scale.dart';
import 'comparaison_screen.dart';

class ProduitsScreen extends StatefulWidget {
  const ProduitsScreen({super.key});

  @override
  State<ProduitsScreen> createState() => _ProduitsScreenState();
}

class _ProduitsScreenState extends State<ProduitsScreen> {
  late Future<List<Produit>> _futur;
  final _controleurRecherche = TextEditingController();
  bool _rechercheActive = false;
  String _requete = '';

  @override
  void initState() {
    super.initState();
    _futur = ProduitService.lister();
  }

  @override
  void dispose() {
    _controleurRecherche.dispose();
    super.dispose();
  }

  Future<void> _recharger() async {
    setState(() {
      _futur = ProduitService.lister();
    });
    await _futur;
  }

  void _basculerRecherche() {
    setState(() {
      _rechercheActive = !_rechercheActive;
      if (!_rechercheActive) {
        _controleurRecherche.clear();
        _requete = '';
      }
    });
  }

  void _effacerRecherche() {
    _controleurRecherche.clear();
    setState(() => _requete = '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const MarqueHeader(titre: 'Produits'),
        actions: [
          IconButton(
            tooltip: _rechercheActive
                ? 'Fermer la recherche'
                : 'Rechercher un produit',
            icon: Icon(
              _rechercheActive ? Icons.close_rounded : Icons.search_rounded,
            ),
            onPressed: _basculerRecherche,
          ),
        ],
      ),
      body: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) => SizeTransition(
              sizeFactor: anim,
              axisAlignment: -1,
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: _rechercheActive
                ? BarreRecherche(
                    key: const ValueKey('recherche-produits'),
                    controleur: _controleurRecherche,
                    onChange: (v) => setState(() => _requete = v.toLowerCase()),
                    hint: 'Nom du produit ou catégorie',
                    autofocus: true,
                  )
                : const SizedBox.shrink(key: ValueKey('cache-recherche')),
          ),
          Expanded(
            child: FutureBuilder<List<Produit>>(
              future: _futur,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Chargement(nombreCartes: 6);
                }
                if (snapshot.hasError) {
                  return ErreurMessage(
                    message: snapshot.error.toString(),
                    onReessayer: _recharger,
                  );
                }

                final produits = snapshot.data ?? [];
                if (produits.isEmpty) {
                  return const ContenuVide(
                    titre: 'Aucun produit',
                    message: 'Aucun produit n\'est encore suivi.\n'
                        'Revenez bientôt !',
                    icone: Icons.shopping_basket_rounded,
                  );
                }

                // Filtre client : nom du produit ou catégorie.
                final filtrees = _requete.isEmpty
                    ? produits
                    : produits.where((p) {
                        final nom = p.nom.toLowerCase();
                        final cat = (p.categorie ?? '').toLowerCase();
                        return nom.contains(_requete) || cat.contains(_requete);
                      }).toList();

                if (filtrees.isEmpty) {
                  return ContenuVide(
                    titre: 'Aucun résultat',
                    message: 'Aucun produit ne correspond à '
                        '« ${_controleurRecherche.text} ».',
                    icone: Icons.search_off_rounded,
                    cta: 'Effacer la recherche',
                    onCta: _effacerRecherche,
                  );
                }

                // Groupement par catégorie pour un affichage plus riche.
                final categories = <String, List<Produit>>{};
                for (final p in filtrees) {
                  final cat = p.categorie ?? 'Autres';
                  categories.putIfAbsent(cat, () => []).add(p);
                }

                // Aplatissement des sections (en-tête + produits) une seule fois.
                final allItems = <Object>[];
                for (final entry in categories.entries) {
                  allItems.add(entry.key); // en-tête catégorie
                  allItems.addAll(entry.value); // produits
                }

                return RefreshIndicator(
                  color: AppColors.green,
                  onRefresh: _recharger,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
                    itemCount: allItems.length,
                    itemBuilder: (context, index) {
                      final item = allItems[index];
                      if (item is String) {
                        return _EnteteCat(categorie: item);
                      }
                      final produit = item as Produit;
                      final isLast =
                          index == allItems.length - 1 ||
                          allItems[index + 1] is String;
                      return Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
                        child: TapScale(
                          child: _CarteProduit(produit: produit),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// En-tête de catégorie
// ---------------------------------------------------------------------------
class _EnteteCat extends StatelessWidget {
  const _EnteteCat({required this.categorie});
  final String categorie;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        categorie.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          fontFamily: AppFonts.mono,
          color: AppColors.textMuted,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Carte Produit enrichie
// ---------------------------------------------------------------------------
class _CarteProduit extends StatefulWidget {
  const _CarteProduit({required this.produit});
  final Produit produit;

  @override
  State<_CarteProduit> createState() => _CarteProduitState();
}

class _CarteProduitState extends State<_CarteProduit> {
  bool _survole = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final couleurIcone = _couleurCategorie(widget.produit.categorie);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, _survole ? -2 : 0, 0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _survole
              ? AppColors.green.withValues(alpha: 0.4)
              : (isDark ? AppColors.darkLine : AppColors.line),
        ),
        boxShadow: _survole
            ? [
                BoxShadow(
                  color: AppColors.green.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                  spreadRadius: -2,
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _ouvrirComparaison(context),
          onHover: (val) => setState(() => _survole = val),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // ── Icône catégorie colorée ──────────────────────────────
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: couleurIcone.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _iconeCategorie(widget.produit.categorie),
                    color: couleurIcone,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                // ── Nom + détails ────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.produit.nom,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontFamily: AppFonts.display,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (widget.produit.categorie != null) ...[
                            _BadgeCat(
                              texte: widget.produit.categorie!,
                              couleur: couleurIcone,
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            '/ ${widget.produit.uniteMesure}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: AppFonts.mono,
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // ── CTA "Comparer" ───────────────────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _survole
                        ? AppColors.green.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bar_chart_rounded,
                        size: 16,
                        color: _survole ? AppColors.green : AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Comparer',
                        style: TextStyle(
                          fontFamily: AppFonts.sans,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _survole ? AppColors.green : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _ouvrirComparaison(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ComparaisonScreen(produit: widget.produit),
      ),
    );
  }

  /// Couleur associée à la catégorie du produit.
  Color _couleurCategorie(String? categorie) {
    if (categorie == null) return AppColors.textMuted;
    final cat = categorie.toLowerCase();
    if (cat.contains('alimentaire') || cat.contains('aliment') || cat.contains('épicerie')) {
      return AppColors.green;
    }
    if (cat.contains('hygièn') || cat.contains('nettoyage') || cat.contains('savon')) {
      return AppColors.saffron;
    }
    if (cat.contains('légume') || cat.contains('fruit') || cat.contains('produit frais')) {
      return const Color(0xFF2DA44E);
    }
    if (cat.contains('céréale') || cat.contains('riz') || cat.contains('farine')) {
      return AppColors.saffron;
    }
    if (cat.contains('viande') || cat.contains('poisson')) {
      return AppColors.terracotta;
    }
    return AppColors.green;
  }

  /// Icône associée à la catégorie.
  IconData _iconeCategorie(String? categorie) {
    if (categorie == null) return Icons.inventory_2_rounded;
    final cat = categorie.toLowerCase();
    if (cat.contains('légume') || cat.contains('fruit')) return Icons.eco_rounded;
    if (cat.contains('viande') || cat.contains('poisson')) return Icons.set_meal_rounded;
    if (cat.contains('céréale') || cat.contains('riz') || cat.contains('farine')) {
      return Icons.grain_rounded;
    }
    if (cat.contains('hygièn') || cat.contains('savon') || cat.contains('nettoyage')) {
      return Icons.soap_rounded;
    }
    if (cat.contains('boisson') || cat.contains('eau')) return Icons.local_drink_rounded;
    if (cat.contains('épice') || cat.contains('condiment')) return Icons.spa_rounded;
    return Icons.shopping_basket_rounded;
  }
}

/// Badge de catégorie inline.
class _BadgeCat extends StatelessWidget {
  const _BadgeCat({required this.texte, required this.couleur});
  final String texte;
  final Color couleur;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        texte,
        style: TextStyle(
          fontFamily: AppFonts.sans,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: couleur,
        ),
      ),
    );
  }
}