import 'package:flutter/material.dart';

import '../models/comparaison.dart';
import '../models/produit.dart';
import '../services/comparison_service.dart';
import '../services/produit_service.dart';
import '../theme/app_theme.dart';
import '../utils/formats.dart';
import '../widgets/barre_recherche.dart';
import '../widgets/etats.dart';
import '../widgets/ms_anim.dart';
import '../widgets/ms_card.dart';
import '../widgets/produit_icone.dart';
import '../widgets/marketscope_header.dart';
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

  /// Meilleur prix actuel par produit (chargé en parallèle, facultatif).
  Map<int, PrixParMarche> _meilleurs = const {};

  @override
  void initState() {
    super.initState();
    _futur = _charger();
  }

  Future<List<Produit>> _charger({bool forcer = false}) async {
    final produits = await ProduitService.lister();
    _chargerMeilleursPrix(produits, forcer: forcer);
    return produits;
  }

  Future<void> _chargerMeilleursPrix(List<Produit> produits,
      {bool forcer = false}) async {
    final comparaisons = await Future.wait(produits.map((p) =>
        ComparisonService.comparer(p.id, forcer: forcer)
            .then<Comparaison?>((c) => c, onError: (Object _) => null)));
    final meilleurs = <int, PrixParMarche>{};
    for (var i = 0; i < produits.length; i++) {
      for (final ppm in comparaisons[i]?.prixParMarche ?? const <PrixParMarche>[]) {
        if (ppm.dernierPrix == null) continue;
        final actuel = meilleurs[produits[i].id];
        if (actuel == null || ppm.dernierPrix! < actuel.dernierPrix!) {
          meilleurs[produits[i].id] = ppm;
        }
      }
    }
    if (mounted) setState(() => _meilleurs = meilleurs);
  }

  @override
  void dispose() {
    _controleurRecherche.dispose();
    super.dispose();
  }

  Future<void> _recharger() async {
    setState(() {
      _futur = _charger(forcer: true);
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
      appBar: MarketScopeHeader(
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
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.sm),
              child: MarketScopeSectionTitle(titre: 'Produits'),
            ),
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
                    color: Theme.of(context).marque,
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
                            child: _CarteProduit(
                              produit: produit,
                              meilleur: _meilleurs[produit.id],
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      ComparaisonScreen(produit: produit),
                                ),
                              ),
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
// Carte Produit : nom, meilleur prix actuel et marché correspondant
// ---------------------------------------------------------------------------
class _CarteProduit extends StatelessWidget {
  const _CarteProduit({
    required this.produit,
    required this.meilleur,
    required this.onTap,
  });

  final Produit produit;
  final PrixParMarche? meilleur;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final m = meilleur;
    return MarketScopeCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          ProduitIcone(nom: produit.nom, categorie: produit.categorie),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  produit.nom,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  m == null
                      ? 'Vendu au ${produit.uniteMesure}'
                      : 'Chez ${nomCourtMarche(m.marche.nom)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (m != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'dès',
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                ),
                Text(
                  formaterPrix(m.dernierPrix!),
                  style: AppTextStyles.priceSmall.copyWith(
                    color: theme.marque,
                  ),
                ),
                if (produit.uniteMesure.isNotEmpty)
                  Text(
                    'par ${produit.uniteMesure}',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                  ),
              ],
            ),
          const SizedBox(width: 2),
          Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
