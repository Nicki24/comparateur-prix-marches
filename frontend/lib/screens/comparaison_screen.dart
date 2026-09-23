import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/comparaison.dart';
import '../models/historique_point.dart';
import '../models/produit.dart';
import '../services/comparison_service.dart';
import '../theme/app_theme.dart';
import '../utils/formats.dart';
import '../widgets/etats.dart';
import '../widgets/ms_anim.dart';
import '../widgets/ms_badge.dart';
import '../widgets/ms_card.dart';
import '../widgets/ms_decor.dart';
import '../widgets/produit_icone.dart';

/// Écran de comparaison d'un produit : prix par marché (bar chart)
/// et évolution historique (line chart) avec fl_chart.
class ComparaisonScreen extends StatefulWidget {
  const ComparaisonScreen({super.key, required this.produit});

  final Produit produit;

  @override
  State<ComparaisonScreen> createState() => _ComparaisonScreenState();
}

class _ComparaisonScreenState extends State<ComparaisonScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ProduitIcone(
              nom: widget.produit.nom,
              categorie: widget.produit.categorie,
              taille: 32,
              tailleIcone: 16,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.produit.nom,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.produit.categorie != null)
                    Text(
                      widget.produit.categorie!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF9FB6AE),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Comparaison'),
            Tab(text: 'Historique'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ComparaisonTab(produit: widget.produit),
          _HistoriqueTab(produit: widget.produit),
        ],
      ),
    );
  }
}

/// Onglet « Comparaison » : dernier prix par marché + écarts.
class _ComparaisonTab extends StatefulWidget {
  const _ComparaisonTab({required this.produit});

  final Produit produit;

  @override
  State<_ComparaisonTab> createState() => _ComparaisonTabState();
}

class _ComparaisonTabState extends State<_ComparaisonTab> {
  late Future<Comparaison> _futur;

  @override
  void initState() {
    super.initState();
    _futur = ComparisonService.comparer(widget.produit.id);
  }

  Future<void> _recharger() async {
    setState(() {
      _futur = ComparisonService.comparer(widget.produit.id);
    });
    await _futur;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Comparaison>(
      future: _futur,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Chargement();
        }
        if (snapshot.hasError) {
          return ErreurMessage(
            message: snapshot.error.toString(),
            onReessayer: _recharger,
          );
        }

        final comparaison = snapshot.data!;
        final paire = comparaison.prixParMarche
            .where((p) => p.dernierPrix != null)
            .toList()
            ..sort((a, b) => a.dernierPrix!.compareTo(b.dernierPrix!));

        if (paire.isEmpty) {
          return const ContenuVide(
            message: 'Aucun prix relevé pour ce produit pour le moment.',
            icone: Icons.show_chart,
          );
        }

        // Synthèse min / moyenne / max.
        final prix = paire.map((p) => p.dernierPrix!).toList();
        final min = prix.reduce((a, b) => a < b ? a : b);
        final max = prix.reduce((a, b) => a > b ? a : b);
        final moy =
            prix.fold<double>(0, (a, b) => a + b) / prix.length;

        return RefreshIndicator(
          color: AppColors.green,
          onRefresh: _recharger,
          child: MsDecorFond(
            densite: 0.5,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                MsApparition(
                    child: _CarteMeilleurPrix(
                        comparaison: comparaison)),
                const SizedBox(height: 12),
                MsApparition(
                  delai: const Duration(milliseconds: 60),
                  child: Row(
                    children: [
                      Expanded(
                          child: _MiniStat(
                              label: 'Minimum',
                              valeur: formaterPrix(min),
                              couleur: AppColors.green)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _MiniStat(
                              label: 'Moyenne',
                              valeur: formaterPrix(moy),
                              couleur: AppColors.saffron)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _MiniStat(
                              label: 'Maximum',
                              valeur: formaterPrix(max),
                              couleur: AppColors.terracotta)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                MsApparition(
                  child: MarketScopeChartCard(
                    titre: 'Prix par marché',
                    sousTitre:
                        'Dernier relevé observé · du moins cher au plus cher',
                    child: Column(
                      children: [
                        _BarChartPrix(paire: paire),
                        const SizedBox(height: 14),
                        const _LegendeBar(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                MsApparition(
                  delai: const Duration(milliseconds: 80),
                  child: MarketScopeCard(
                    padding: const EdgeInsets.symmetric(
                        vertical: 4, horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                              12, 10, 12, 4),
                          child: Text(
                            'Où trouver ce produit au meilleur prix ?',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontFamily: AppFonts.display,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        for (var i = 0; i < paire.length; i++)
                          MsCascade(
                            index: i,
                            child: _RangPrixMarche(
                              prixParMarche: paire[i],
                              rang: i,
                              total: paire.length,
                              prixMax:
                                  paire.last.dernierPrix!,
                              prixMin:
                                  paire.first.dernierPrix!,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Encart « meilleur prix » sur fond encre, prix en vert tendre.
class _CarteMeilleurPrix extends StatelessWidget {
  const _CarteMeilleurPrix({required this.comparaison});

  final Comparaison comparaison;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prixMin = comparaison.prixMinimum;
    final meilleur = comparaison.prixParMarche
        .where((p) => p.dernierPrix != null)
        .reduce((a, b) => (a.dernierPrix! <= b.dernierPrix!) ? a : b);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.ink, AppColors.ink2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'MEILLEUR PRIX',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: const Color(0xFFBFE3CC),
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const _BadgeMeilleureAffaire(),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            prixMin != null ? formaterPrix(prixMin) : '—',
            style: stylePrix(
              taille: 34,
              couleur: AppColors.greenLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Chez ${meilleur.marche.nom}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFFCFE7D8),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mini-stat min / moyenne / max (cartes légères, responsive).
class _MiniStat extends StatelessWidget {
  const _MiniStat(
      {required this.label, required this.valeur, required this.couleur});

  final String label;
  final String valeur;
  final Color couleur;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MarketScopeCard(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                      color: couleur, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontFamily: AppFonts.mono,
                    fontSize: 10,
                    letterSpacing: 0.8,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            valeur,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.priceSmall.copyWith(
              fontSize: 13,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge animé « Meilleure affaire » (apparition en échelle).
class _BadgeMeilleureAffaire extends StatelessWidget {
  const _BadgeMeilleureAffaire();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutBack,
      builder: (context, v, child) => Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.8 + 0.2 * v, child: child),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.greenLight, AppColors.green],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(99),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.whatshot_rounded, size: 13, color: Colors.white),
            SizedBox(width: 4),
            Text(
              'Meilleure affaire',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Graphique en barres des derniers prix par marché, classés du moins cher
/// au plus cher (vert tendre → safran → terracotta).
class _BarChartPrix extends StatelessWidget {
  const _BarChartPrix({required this.paire});

  final List<PrixParMarche> paire;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxPrix = paire.last.dernierPrix! * 1.12;
    // Évite les labels qui se chevauchent : 1 sur 2 si > 6 marchés,
    // inclinaison à 45° pour les noms longs, taille adaptative.
    final dense = paire.length > 6;
    final hauteur = paire.length > 4 ? 240.0 : 220.0;

    return SizedBox(
      height: hauteur,
      child: BarChart(
        BarChartData(
          maxY: maxPrix > 0 ? maxPrix : 1,
          barGroups: [
            for (var i = 0; i < paire.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: paire[i].dernierPrix!,
                    width: paire.length > 6 ? 14 : 22,
                    color: _couleurBar(i, paire.length),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(5),
                    ),
                  ),
                ],
              ),
          ],
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: AppFonts.mono,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 54,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= paire.length) {
                    return const SizedBox.shrink();
                  }
                  // Réduit le nombre de labels si dense.
                  if (dense && index % 2 == 1) {
                    return const SizedBox.shrink();
                  }
                  final nom =
                      _nomCourt(paire[index].marche.nom);
                  final long = nom.length > 7;
                  final txt = Text(
                    nom,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                    ),
                  );
                  if (!long) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: txt,
                    );
                  }
                  // Incline les labels longs pour rester lisible.
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Transform.rotate(
                      angle: -0.5,
                      child: SizedBox(width: 52, child: txt),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: theme.dividerColor.withValues(alpha: 0.6),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.ink,
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final nom = paire[group.x].marche.nom;
                return BarTooltipItem(
                  '$nom\n${formaterPrix(rod.toY)}',
                  theme.textTheme.bodySmall!.copyWith(
                    color: Colors.white,
                    fontFamily: AppFonts.sans,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  String _nomCourt(String nom) {
    final t = nom.trim();
    if (t.length <= 12) return t;
    return t.substring(0, 11).trimRight();
  }
}

/// Ligne comparative : marché · prix (mono) · écart % · date MàJ.
/// Marchés classés du moins cher au plus cher, badges min/max.
class _RangPrixMarche extends StatelessWidget {
  const _RangPrixMarche({
    required this.prixParMarche,
    required this.rang,
    required this.total,
    required this.prixMax,
    required this.prixMin,
  });

  final PrixParMarche prixParMarche;
  final int rang;
  final int total;
  final double prixMax;
  final double prixMin;

  String _dateMaj() {
    final brut = prixParMarche.dateDernierReleve;
    if (brut == null || brut.isEmpty) return '';
    final d = DateTime.tryParse(brut);
    if (d == null) return brut;
    return 'MàJ ${formaterDateCourte(d)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prix = prixParMarche.dernierPrix!;
    final ecart = prixParMarche.ecartPourcentage;
    final estLeMoinsCher = rang == 0;
    final estLePlusCher = rang == total - 1 && total > 1;
    final couleur = _couleurBar(rang, total);
    final largeurBarre = (prix / prixMax).clamp(0.08, 1.0);
    final dateTxt = _dateMaj();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: couleur,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  prixParMarche.marche.nom,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5),
                ),
              ),
              if (estLeMoinsCher)
                const MarketScopeRangBadge.meilleur()
              else if (estLePlusCher)
                const MarketScopeRangBadge.cher()
              else if (ecart != null && ecart.abs() >= 0.05)
                Text(
                  '${ecart > 0 ? '+' : '−'}${ecart.abs().toStringAsFixed(1)} %',
                  style: TextStyle(
                    fontFamily: AppFonts.mono,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: ecart > 0
                        ? theme.alertFg
                        : theme.okFg,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 7,
                  decoration: BoxDecoration(
                    color: theme
                        .colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: largeurBarre,
                    child: Container(
                      decoration: BoxDecoration(
                        color: couleur,
                        borderRadius:
                            BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formaterPrix(prix),
                    style: AppTextStyles.priceSmall.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (dateTxt.isNotEmpty)
                    Text(
                      dateTxt,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(
                        fontSize: 10.5,
                        color: theme
                            .colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (prixParMarche.nbReleves > 0)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                '${prixParMarche.nbReleves} relevé${prixParMarche.nbReleves > 1 ? 's' : ''}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10.5,
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.75),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Couleur de barre selon le rang : moins cher (vert tendre), plus cher
/// (terracotta), intermédiaires (safran).
Color _couleurBar(int rang, int total) {
  if (total <= 1) {
    return AppColors.green;
  }
  if (rang == 0) {
    return AppColors.greenLight;
  }
  if (rang == total - 1) {
    return AppColors.terracotta;
  }
  return AppColors.saffron;
}

/// Onglet « Historique » : évolution du prix avec un line chart.
class _HistoriqueTab extends StatefulWidget {
  const _HistoriqueTab({required this.produit});

  final Produit produit;

  @override
  State<_HistoriqueTab> createState() => _HistoriqueTabState();
}

class _HistoriqueTabState extends State<_HistoriqueTab>
    with AutomaticKeepAliveClientMixin {
  String _mode = 'moyenne';
  late Future<List<HistoriquePoint>> _futur;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _futur = _charger();
  }

  Future<List<HistoriquePoint>> _charger() {
    return ComparisonService.historique(
      widget.produit.id,
      mode: _mode,
    );
  }

  void _changerMode(String mode) {
    setState(() {
      _mode = mode;
      _futur = _charger();
    });
  }

  Future<void> _recharger() async {
    setState(() {
      _futur = _charger();
    });
    await _futur;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TitreGraphique(
                titre: 'Évolution du prix',
                sousTitre: '${_intituleMode()} sur la période',
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'moyenne', label: Text('Moyenne')),
                    ButtonSegment(value: 'min', label: Text('Min')),
                    ButtonSegment(value: 'max', label: Text('Max')),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (selection) => _changerMode(selection.first),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<HistoriquePoint>>(
            future: _futur,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Chargement();
              }
              if (snapshot.hasError) {
                return ErreurMessage(
                  message: snapshot.error.toString(),
                  onReessayer: _recharger,
                );
              }
              final points = snapshot.data ?? [];
              if (points.isEmpty) {
                return const ContenuVide(
                  message: 'Pas de données d’historique.',
                  icone: Icons.timeline,
                );
              }
              // Synthèse période : min / max / moyenne / variation.
              final vals =
                  points.map((p) => p.valeur).toList();
              final vMin = vals.reduce((a, b) => a < b ? a : b);
              final vMax = vals.reduce((a, b) => a > b ? a : b);
              final vMoy =
                  vals.fold<double>(0, (a, b) => a + b) /
                      vals.length;
              final periode =
                  '${formaterDateCourte(points.first.date)} → ${formaterDateCourte(points.last.date)}';

              return RefreshIndicator(
                color: AppColors.green,
                onRefresh: _recharger,
                child: MsDecorFond(
                  densite: 0.5,
                  child: ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      AnimatedSwitcher(
                        duration:
                            const Duration(milliseconds: 400),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: Column(
                          key: ValueKey(_mode),
                          crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                          children: [
                            MarketScopeCard(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Synthèse · $periode',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                fontFamily:
                                                    AppFonts.mono,
                                                letterSpacing: 0.6,
                                                color: Theme.of(
                                                        context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                          child: _HistoStat(
                                              label: 'Min',
                                              valeur: formaterPrix(
                                                  vMin))),
                                      Expanded(
                                          child: _HistoStat(
                                              label: 'Moyenne',
                                              valeur: formaterPrix(
                                                  vMoy))),
                                      Expanded(
                                          child: _HistoStat(
                                              label: 'Max',
                                              valeur: formaterPrix(
                                                  vMax))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            MarketScopeChartCard(
                              titre: 'Évolution du prix',
                              sousTitre:
                                  '${_intituleMode()} · $periode · ${points.length} points',
                              child: _LineChartPrix(
                                  points: points),
                            ),
                            const SizedBox(height: 12),
                            MarketScopeCard(
                              padding: const EdgeInsets.all(12),
                              child: _VariationPanel(
                                  points: points),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _intituleMode() {
    switch (_mode) {
      case 'min':
        return 'Minimum';
      case 'max':
        return 'Maximum';
      default:
        return 'Moyenne';
    }
  }
}

/// Graphique en ligne de l'évolution des prix.
class _LineChartPrix extends StatelessWidget {
  const _LineChartPrix({required this.points});

  final List<HistoriquePoint> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final spots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].valeur),
    ];
    final valeurs = points.map((p) => p.valeur).toList();
    final minY = valeurs.reduce((a, b) => a < b ? a : b);
    final maxY = valeurs.reduce((a, b) => a > b ? a : b);
    final marge = ((maxY - minY) * 0.15).clamp(10, double.infinity);

    return SizedBox(
      height: 240,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (points.length - 1).toDouble().clamp(0, double.infinity),
          minY: (minY - marge).clamp(0, double.infinity),
          maxY: maxY + marge,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.green,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.green.withValues(alpha: 0.14),
              ),
            ),
          ],
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: AppFonts.mono,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                // Une date sur 3–5 si beaucoup de points (pas de chevauchement).
                interval: points.length > 18
                    ? (points.length / 6).ceilToDouble()
                    : (points.length > 10 ? 2 : 1),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  final pas = points.length > 18
                      ? (points.length / 6).ceil()
                      : (points.length > 10 ? 2 : 1);
                  if (index % pas != 0 &&
                      index != points.length - 1) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      formaterDateCourte(points[index].date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: const FlGridData(drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.ink,
              getTooltipItems: (touchedSpots) {
                return touchedSpots
                    .map(
                      (spot) => LineTooltipItem(
                        '${formaterDate(points[spot.x.toInt()].date)}\n'
                        '${formaterPrix(spot.y)}',
                        theme.textTheme.bodySmall!.copyWith(
                          color: Colors.white,
                          fontFamily: AppFonts.sans,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                    .toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Stat compacte pour la synthèse historique.
class _HistoStat extends StatelessWidget {
  const _HistoStat({required this.label, required this.valeur});

  final String label;
  final String valeur;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          valeur,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.priceSmall.copyWith(
            fontSize: 13,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

/// Panneau de synthèse de la variation de prix sur la période suivie.
class _VariationPanel extends StatelessWidget {
  const _VariationPanel({required this.points});

  final List<HistoriquePoint> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (points.length < 2) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          '${formaterPrix(points.first.valeur)} — début de suivi',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final premier = points.first.valeur;
    final dernier = points.last.valeur;
    final variation = dernier - premier;
    final baisse = variation < 0;
    final pct = premier != 0
        ? (variation / premier * 100).toStringAsFixed(1)
        : '0';
    final couleur = baisse ? AppColors.okFg : AppColors.alertFg;
    final fondCouleur = baisse ? AppColors.okBg : AppColors.alertBg;
    final affichage = '${baisse ? '−' : '+'}${pct.replaceFirst('-', '')} %';

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: fondCouleur,
              shape: BoxShape.circle,
            ),
            child: Icon(
              baisse ? Icons.trending_down_rounded : Icons.trending_up_rounded,
              color: couleur,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  baisse ? 'Le prix a baissé depuis le début du suivi' : 'Le prix a évolué depuis le début du suivi',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formaterPrix(premier)} → ${formaterPrix(dernier)}',
                  style: stylePrix(taille: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            affichage,
            style: TextStyle(
              fontFamily: AppFonts.mono,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: couleur,
            ),
          ),
        ],
      ),
    );
  }
}

/// Titre d'un graphique façon tableau de bord : barre d'accent + titre
/// (Space Grotesk) + sous-titre (muted).
class _TitreGraphique extends StatelessWidget {
  const _TitreGraphique({required this.titre, required this.sousTitre});

  final String titre;
  final String sousTitre;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 4,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.green,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titre,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
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
      ],
    );
  }
}

/// Légende du graphique en barres : moins cher → plus cher.
class _LegendeBar extends StatelessWidget {
  const _LegendeBar();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: const [
        _ItemLegende(couleur: AppColors.greenLight, libelle: 'Moins cher'),
        _ItemLegende(couleur: AppColors.saffron, libelle: 'Intermédiaire'),
        _ItemLegende(couleur: AppColors.terracotta, libelle: 'Plus cher'),
      ],
    );
  }
}

class _ItemLegende extends StatelessWidget {
  const _ItemLegende({required this.couleur, required this.libelle});

  final Color couleur;
  final String libelle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: couleur,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          libelle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 11.5,
          ),
        ),
      ],
    );
  }
}