import 'package:flutter/material.dart';

import '../models/marche.dart';
import '../models/releve_prix.dart';
import '../services/marche_service.dart';
import '../services/releve_service.dart';
import '../theme/app_theme.dart';
import '../utils/formats.dart';
import '../widgets/barre_recherche.dart';
import '../widgets/etats.dart';
import '../widgets/marketscope_header.dart';
import '../widgets/ms_anim.dart';
import '../widgets/ms_card.dart';
import '../widgets/produit_icone.dart';
import 'comparaison_screen.dart';

class MarchesScreen extends StatefulWidget {
  const MarchesScreen({super.key});

  @override
  State<MarchesScreen> createState() => _MarchesScreenState();
}

class _MarchesScreenState extends State<MarchesScreen> {
  late Future<List<Marche>> _futur;
  final _controleurRecherche = TextEditingController();
  bool _rechercheActive = false;
  String _requete = '';
  String _tri = 'nom';
  String? _villeFiltre;

  @override
  void initState() {
    super.initState();
    _futur = MarcheService.lister();
  }

  @override
  void dispose() {
    _controleurRecherche.dispose();
    super.dispose();
  }

  Future<void> _recharger() async {
    setState(() {
      _futur = MarcheService.lister();
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

  void _effacerFiltres() {
    _controleurRecherche.clear();
    setState(() {
      _requete = '';
      _villeFiltre = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MarketScopeHeader(
        actions: [
          IconButton(
            tooltip: _rechercheActive
                ? 'Fermer la recherche'
                : 'Rechercher un marché',
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
              child: MarketScopeSectionTitle(titre: 'Marchés'),
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
                      key: const ValueKey('recherche-marches'),
                      controleur: _controleurRecherche,
                      onChange: (v) =>
                          setState(() => _requete = v.toLowerCase()),
                      hint: 'Nom du marché ou localisation',
                      autofocus: true,
                    )
                  : const SizedBox.shrink(
                      key: ValueKey('cache-recherche')),
            ),
            Expanded(
              child: FutureBuilder<List<Marche>>(
                future: _futur,
                builder: (context, snapshot) {
                  if (snapshot.connectionState !=
                      ConnectionState.done) {
                    return const Chargement(nombreCartes: 5);
                  }
                  if (snapshot.hasError) {
                    return ErreurMessage(
                      message: snapshot.error.toString(),
                      onReessayer: _recharger,
                    );
                  }

                  final marches = snapshot.data ?? [];
                  if (marches.isEmpty) {
                    return const ContenuVide(
                      titre: 'Aucun marché',
                      message:
                          'Aucun marché n\'est encore disponible.\n'
                          'Revenez bientôt !',
                      icone: Icons.storefront_rounded,
                    );
                  }

                  final villes = marches
                      .map((m) => m.localisation)
                      .where((v) => v.isNotEmpty)
                      .toSet()
                      .toList()
                    ..sort();

                  final filtrees = marches.where((m) {
                    final okVille = _villeFiltre == null ||
                        m.localisation == _villeFiltre;
                    final nom = m.nom.toLowerCase();
                    final loc = m.localisation.toLowerCase();
                    final okTexte = _requete.isEmpty ||
                        nom.contains(_requete) ||
                        loc.contains(_requete);
                    return okVille && okTexte;
                  }).toList();

                  if (filtrees.isEmpty) {
                    return ContenuVide(
                      titre: 'Aucun résultat',
                      message: _requete.isEmpty
                          ? 'Aucun marché pour ce filtre.'
                          : 'Aucun marché ne correspond à '
                              '« ${_controleurRecherche.text} ».',
                      icone: Icons.search_off_rounded,
                      cta: 'Effacer les filtres',
                      onCta: _effacerFiltres,
                    );
                  }

                  if (_tri == 'ville') {
                    filtrees.sort((a, b) =>
                        a.localisation.compareTo(b.localisation));
                  } else {
                    filtrees.sort((a, b) => a.nom
                        .toLowerCase()
                        .compareTo(b.nom.toLowerCase()));
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.sm,
                            AppSpacing.md,
                            2),
                        child: Text(
                          '${filtrees.length} marché${filtrees.length > 1 ? 's' : ''} suivi${filtrees.length > 1 ? 's' : ''}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ),
                      _FiltresMarche(
                        tri: _tri,
                        villes: villes,
                        villeFiltre: _villeFiltre,
                        onTri: (tri) =>
                            setState(() => _tri = tri),
                        onVille: (ville) => setState(
                            () => _villeFiltre = ville),
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          color: Theme.of(context).marque,
                          onRefresh: _recharger,
                          child: GridView.builder(
                            physics:
                                const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(
                                16, 12, 16, 24),
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 520,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 12,
                              mainAxisExtent: 80,
                            ),
                            itemCount: filtrees.length,
                            itemBuilder: (context, index) =>
                                MsCascade(
                              index: index,
                              child: _CarteMarche(
                                marche: filtrees[index],
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => MarcheDetailScreen(
                                        marche: filtrees[index]),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
    );
  }
}

/// Rangée de filtres : tri (nom / ville) + sous-catégories par localisation.
class _FiltresMarche extends StatelessWidget {
  const _FiltresMarche({
    required this.tri,
    required this.villes,
    required this.villeFiltre,
    required this.onTri,
    required this.onVille,
  });

  final String tri;
  final List<String> villes;
  final String? villeFiltre;
  final ValueChanged<String> onTri;
  final ValueChanged<String?> onVille;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        children: [
          Text(
            'TRI',
            style: theme.textTheme.labelSmall?.copyWith(
              fontFamily: AppFonts.mono,
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          _ChipFiltre(
            label: 'Nom',
            selected: tri == 'nom',
            onSelected: () => onTri('nom'),
          ),
          const SizedBox(width: 6),
          _ChipFiltre(
            label: 'Ville',
            selected: tri == 'ville',
            onSelected: () => onTri('ville'),
          ),
          const SizedBox(width: 14),
          _ChipFiltre(
            label: 'Toutes',
            selected: villeFiltre == null,
            onSelected: () => onVille(null),
          ),
          for (final ville in villes) ...[
            const SizedBox(width: 6),
            _ChipFiltre(
              label: ville,
              selected: villeFiltre == ville,
              onSelected: () => onVille(ville),
            ),
          ],
        ],
      ),
    );
  }
}

/// Chip de filtre compact.
class _ChipFiltre extends StatelessWidget {
  const _ChipFiltre({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(99),
      onTap: onSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? theme.marque.withValues(alpha: 0.14)
              : theme.fondCarte,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected
                ? theme.marque.withValues(alpha: 0.5)
                : theme.ligne,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.sans,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? theme.marque : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Carte Marché (grille) avec animation au toucher et à l'effleurement
// ---------------------------------------------------------------------------
class _CarteMarche extends StatelessWidget {
  const _CarteMarche({required this.marche, required this.onTap});
  final Marche marche;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MarketScopeCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.saffron.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: AppColors.saffron,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  marche.nom,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        marche.localisation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fiche détaillée d'un marché : derniers prix relevés sur place
// ---------------------------------------------------------------------------
class MarcheDetailScreen extends StatefulWidget {
  const MarcheDetailScreen({super.key, required this.marche});

  final Marche marche;

  @override
  State<MarcheDetailScreen> createState() => _MarcheDetailScreenState();
}

class _MarcheDetailScreenState extends State<MarcheDetailScreen> {
  late Future<List<RelevePrix>> _futur;

  @override
  void initState() {
    super.initState();
    _futur = _charger();
  }

  /// Dernier relevé de chaque produit sur ce marché (l'API renvoie les
  /// relevés du plus récent au plus ancien).
  Future<List<RelevePrix>> _charger() async {
    final releves = await ReleveService.lister(marcheId: widget.marche.id);
    final parProduit = <int, RelevePrix>{};
    for (final r in releves) {
      final produit = r.produit;
      if (produit == null) continue;
      parProduit.putIfAbsent(produit.id, () => r);
    }
    return parProduit.values.toList()
      ..sort((a, b) => a.produit!.nom.compareTo(b.produit!.nom));
  }

  Future<void> _recharger() async {
    setState(() => _futur = _charger());
    await _futur;
  }

  @override
  Widget build(BuildContext context) {
    final marche = widget.marche;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: MarketScopeHeader(
        titre: marche.nom,
        sousTitre: marche.localisation,
      ),
      body: RefreshIndicator(
        color: theme.marque,
        onRefresh: _recharger,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xl),
          children: [
            _HeroMarche(marche: marche),
            const SizedBox(height: AppSpacing.lg),
            const MarketScopeSectionTitle(
              titre: 'Derniers prix relevés ici',
              icone: Icons.sell_rounded,
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: AppSpacing.sm),
            FutureBuilder<List<RelevePrix>>(
              future: _futur,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: ChargementCentre(),
                  );
                }
                if (snapshot.hasError) {
                  return ErreurMessage(
                    message: snapshot.error.toString(),
                    onReessayer: _recharger,
                  );
                }
                final releves = snapshot.data ?? const [];
                if (releves.isEmpty) {
                  return const ContenuVide(
                    titre: 'Aucun prix pour l’instant',
                    message:
                        'Aucun relevé n’a encore été saisi sur ce marché.',
                    icone: Icons.receipt_long_rounded,
                  );
                }
                return Column(
                  children: [
                    MarketScopeCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (var i = 0; i < releves.length; i++) ...[
                            if (i > 0)
                              Divider(
                                  height: 1, indent: 64, color: theme.ligne),
                            _LignePrixMarche(releve: releves[i]),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Touchez un produit pour le comparer avec les autres marchés.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroMarche extends StatelessWidget {
  const _HeroMarche({required this.marche});

  final Marche marche;

  @override
  Widget build(BuildContext context) {
    final actif = marche.actif;
    final couleurStatut = actif ? AppColors.greenLight : AppColors.darkSaffron;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.ink, AppColors.ink2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.sheet + 4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.saffron.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: AppColors.darkSaffron,
                  size: 24,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: couleurStatut.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      actif
                          ? Icons.check_circle_rounded
                          : Icons.pause_circle_rounded,
                      size: 14,
                      color: couleurStatut,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      actif ? 'Relevés ouverts' : 'Relevés suspendus',
                      style: TextStyle(
                        fontFamily: AppFonts.sans,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: couleurStatut,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            marche.nom,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w700,
              fontSize: 22,
              height: 1.2,
              color: Color(0xFFEAF3EE),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 15, color: Color(0xFF9FB6AE)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  marche.localisation,
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF9FB6AE)),
                ),
              ),
            ],
          ),
          if (marche.description != null &&
              marche.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              marche.description!,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFFCFE7D8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LignePrixMarche extends StatelessWidget {
  const _LignePrixMarche({required this.releve});

  final RelevePrix releve;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final produit = releve.produit!;
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ComparaisonScreen(produit: produit),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 12),
        child: Row(
          children: [
            ProduitIcone(
              nom: produit.nom,
              categorie: produit.categorie,
              taille: 38,
              tailleIcone: 19,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    produit.nom,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  Text(
                    'Relevé le ${formaterDateLisible(releve.dateReleve)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formaterPrix(releve.valeur),
                  style: AppTextStyles.priceSmall.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (produit.uniteMesure.isNotEmpty)
                  Text(
                    'par ${produit.uniteMesure}',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                  ),
              ],
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
