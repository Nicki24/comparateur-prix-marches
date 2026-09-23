import 'package:flutter/material.dart';

import '../models/produit.dart';
import '../services/produit_service.dart';
import '../theme/app_theme.dart';
import '../widgets/barre_recherche.dart';
import '../widgets/etats.dart';
import '../widgets/logo.dart';
import '../widgets/ms_anim.dart';
import '../widgets/ms_card.dart';
import '../widgets/ms_decor.dart';
import '../widgets/produit_icone.dart';
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
      body: MsDecorFond(
        densite: 0.6,
        child: Column(
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
                      onChange: (v) =>
                          setState(() => _requete = v.toLowerCase()),
                      hint: 'Nom du produit ou catégorie',
                      autofocus: true,
                    )
                  : const SizedBox.shrink(
                      key: ValueKey('cache-recherche')),
            ),
            Expanded(
              child: FutureBuilder<List<Produit>>(
                future: _futur,
                builder: (context, snapshot) {
                  if (snapshot.connectionState !=
                      ConnectionState.done) {
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
                      message:
                          'Aucun produit n\'est encore suivi.\n'
                          'Revenez bientôt !',
                      icone: Icons.shopping_basket_rounded,
                    );
                  }

                  final filtrees = _requete.isEmpty
                      ? produits
                      : produits.where((p) {
                          final nom = p.nom.toLowerCase();
                          final cat =
                              (p.categorie ?? '').toLowerCase();
                          return nom.contains(_requete) ||
                              cat.contains(_requete);
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

                  final categories =
                      <String, List<Produit>>{};
                  for (final p in filtrees) {
                    final cat = p.categorie ?? 'Autres';
                    categories.putIfAbsent(cat, () => []).add(p);
                  }

                  final allItems = <Object>[];
                  var compteur = 0;
                  for (final entry in categories.entries) {
                    allItems.add(entry.key);
                    allItems.addAll(entry.value);
                  }

                  return RefreshIndicator(
                    color: AppColors.green,
                    onRefresh: _recharger,
                    child: ListView.builder(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.sm,
                          AppSpacing.md,
                          AppSpacing.xl),
                      itemCount: allItems.length,
                      itemBuilder: (context, index) {
                        final item = allItems[index];
                        if (item is String) {
                          return _EnteteCat(
                              categorie: item,
                              compteur: categories[item]
                                      ?.length ??
                                  0);
                        }
                        final produit = item as Produit;
                        final isLast = index ==
                                allItems.length - 1 ||
                            allItems[index + 1] is String;
                        compteur++;
                        return Padding(
                          padding: EdgeInsets.only(
                              bottom: isLast ? 0 : 8),
                          child: MsCascade(
                            index: compteur % 7,
                            child: TapScale(
                              child: _CarteProduit(
                                  produit: produit),
                            ),
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// En-tête de catégorie : label mono + compteur
// ---------------------------------------------------------------------------
class _EnteteCat extends StatelessWidget {
  const _EnteteCat({required this.categorie, this.compteur = 0});
  final String categorie;
  final int compteur;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              categorie.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontFamily: AppFonts.mono,
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '$compteur',
              style: TextStyle(
                fontFamily: AppFonts.mono,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
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
    final style = ProduitStyle.resoudre(
        widget.produit.nom, widget.produit.categorie);

    return MouseRegion(
      onEnter: (_) => setState(() => _survole = true),
      onExit: (_) => setState(() => _survole = false),
      child: MarketScopeCard(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () => _ouvrirComparaison(context),
      child: Row(
        children: [
          ProduitIcone(
            nom: widget.produit.nom,
            categorie: widget.produit.categorie,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.produit.nom,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (widget.produit.categorie != null)
                      Flexible(
                        child: _BadgeCat(
                          texte: widget.produit.categorie!,
                          couleur: style.couleur,
                        ),
                      ),
                    const SizedBox(width: 6),
                    Text(
                      '/ ${widget.produit.uniteMesure}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: AppFonts.mono,
                        color: theme
                            .colorScheme.onSurfaceVariant,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // ── CTA "Comparer" bien visible ──────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _survole
                  ? AppColors.green
                  : AppColors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bar_chart_rounded,
                  size: 15,
                  color:
                      _survole ? Colors.white : AppColors.green,
                ),
                const SizedBox(width: 4),
                Text(
                  'Comparer',
                  style: TextStyle(
                    fontFamily: AppFonts.sans,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _survole
                        ? Colors.white
                        : AppColors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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