import 'package:flutter/material.dart';

import '../models/marche.dart';
import '../services/marche_service.dart';
import '../theme/app_theme.dart';
import '../widgets/barre_recherche.dart';
import '../widgets/etats.dart';
import '../widgets/logo.dart';
import '../widgets/tap_scale.dart';
import 'produits_screen.dart';

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
      appBar: AppBar(
        title: const MarqueHeader(titre: 'Marchés'),
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
                    onChange: (v) => setState(() => _requete = v.toLowerCase()),
                    hint: 'Nom du marché ou localisation',
                    autofocus: true,
                  )
                : const SizedBox.shrink(key: ValueKey('cache-recherche')),
          ),
          Expanded(
            child: FutureBuilder<List<Marche>>(
              future: _futur,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
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
                    message: 'Aucun marché n\'est encore disponible.\n'
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

                // Filtre texte + ville.
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
                    message: 'Aucun marché ne correspond à '
                        '« ${_controleurRecherche.text} ».',
                    icone: Icons.search_off_rounded,
                    cta: 'Effacer la recherche',
                    onCta: _effacerFiltres,
                  );
                }

                // Tri par nom ou par ville.
                if (_tri == 'ville') {
                  filtrees.sort((a, b) => a.localisation.compareTo(b.localisation));
                } else {
                  filtrees.sort(
                    (a, b) => a.nom.toLowerCase().compareTo(b.nom.toLowerCase()),
                  );
                }

                return Column(
                  children: [
                    _FiltresMarche(
                      tri: _tri,
                      villes: villes,
                      villeFiltre: _villeFiltre,
                      onTri: (tri) => setState(() => _tri = tri),
                      onVille: (ville) =>
                          setState(() => _villeFiltre = ville),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        color: AppColors.green,
                        onRefresh: _recharger,
                        child: GridView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 340,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            mainAxisExtent: 158,
                          ),
                          itemCount: filtrees.length,
                          itemBuilder: (context, index) => TapScale(
                            child: _CarteMarche(marche: filtrees[index]),
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
              ? AppColors.green.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected
                ? AppColors.green.withValues(alpha: 0.5)
                : (theme.brightness == Brightness.dark
                    ? AppColors.darkLine
                    : AppColors.line),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.sans,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.green : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Carte Marché (grille) avec animation au toucher et à l'effleurement
// ---------------------------------------------------------------------------
class _CarteMarche extends StatefulWidget {
  const _CarteMarche({required this.marche});
  final Marche marche;

  @override
  State<_CarteMarche> createState() => _CarteMarcheState();
}

class _CarteMarcheState extends State<_CarteMarche> {
  bool _survole = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, _survole ? -2 : 0, 0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _survole
              ? AppColors.greenLight.withValues(alpha: 0.5)
              : (isDark ? AppColors.darkLine : AppColors.line),
        ),
        boxShadow: _survole
            ? [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: isDark ? 0.4 : 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: -4,
                )
              ]
            : [],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _ouvrirMarche(context),
          onHover: (val) => setState(() => _survole = val),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // ── Avatar localisation ──────────────────────────────
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: AppColors.green,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // ── Nom ──────────────────────────────────────────────
                    Expanded(
                      child: Text(
                        widget.marche.nom,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontFamily: AppFonts.display,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // ── Localisation ─────────────────────────────────────────
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        widget.marche.localisation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                // ── Description ──────────────────────────────────────────
                if (widget.marche.description != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    widget.marche.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.7),
                      fontSize: 11.5,
                    ),
                  ),
                ],
                const Spacer(),
                // ── Indication de navigation ─────────────────────────────
                Row(
                  children: [
                    Icon(
                      Icons.compare_arrows_rounded,
                      size: 14,
                      color: _survole
                          ? AppColors.green
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Comparer les produits',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _survole
                            ? AppColors.green
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _ouvrirMarche(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MarcheDetailScreen(marche: widget.marche),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fiche détaillée d'un marché
// ---------------------------------------------------------------------------
class MarcheDetailScreen extends StatelessWidget {
  const MarcheDetailScreen({super.key, required this.marche});
  final Marche marche;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(marche.nom)),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ─── Hero header ──────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.ink, AppColors.ink2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: AppColors.greenLight,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            marche.nom,
                            style: const TextStyle(
                              fontFamily: AppFonts.display,
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                              color: Color(0xFFEAF3EE),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                size: 14,
                                color: Color(0xFF9FB6AE),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  marche.localisation,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF9FB6AE),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (marche.description != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    marche.description!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFCFE7D8),
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ─── Contenu ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 4),
                // Carte "voir les prix"
                _CarteActionDetail(
                  icone: Icons.shopping_basket_rounded,
                  couleurIcone: AppColors.green,
                  titre: 'Comparer les prix des produits',
                  sousTitre: 'Consultez les relevés disponibles sur ce marché',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ProduitsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                // Info badge actif
                _CarteActionDetail(
                  icone: marche.actif
                      ? Icons.check_circle_rounded
                      : Icons.pause_circle_rounded,
                  couleurIcone: marche.actif ? AppColors.okFg : AppColors.staleFg,
                  titre: marche.actif ? 'Marché actif' : 'Marché inactif',
                  sousTitre: marche.actif
                      ? 'Les relevés de prix sont acceptés sur ce marché'
                      : 'Les relevés ne sont pas acceptés actuellement',
                  couleurFond: marche.actif ? AppColors.okBg : AppColors.staleBg,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tuile d'action dans le détail d'un marché.
class _CarteActionDetail extends StatelessWidget {
  const _CarteActionDetail({
    required this.icone,
    required this.couleurIcone,
    required this.titre,
    required this.sousTitre,
    this.onTap,
    this.couleurFond,
  });

  final IconData icone;
  final Color couleurIcone;
  final String titre;
  final String sousTitre;
  final VoidCallback? onTap;
  final Color? couleurFond;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: couleurFond ?? (isDark ? AppColors.darkSurface : AppColors.white),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.darkLine : AppColors.line,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: couleurIcone.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icone, color: couleurIcone, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titre,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sousTitre,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}