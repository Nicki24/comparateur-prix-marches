import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/comparaison.dart';
import '../models/historique_point.dart';
import '../models/produit.dart';
import '../services/comparison_service.dart';
import '../utils/formats.dart';
import '../widgets/etats.dart';

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
        title: Text(widget.produit.nom),
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
    final theme = Theme.of(context);
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
        if (comparaison.prixParMarche.isEmpty) {
          return const ContenuVide(
            message: 'Aucun prix relevé pour ce produit pour le moment.',
            icone: Icons.show_chart,
          );
        }

        return RefreshIndicator(
          onRefresh: _recharger,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _CarteMeilleurPrix(comparaison: comparaison),
              const SizedBox(height: 16),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 24, 16, 8),
                  child: _BarChartPrix(comparaison: comparaison),
                ),
              ),
              const SizedBox(height: 8),
              ...comparaison.prixParMarche.map(
                (p) => _LignePrixMarche(
                  prixParMarche: p,
                  estLeMoinsCher: comparaison.prixMinimum != null &&
                      p.dernierPrix != null &&
                      p.dernierPrix == comparaison.prixMinimum,
                  colorTheme: theme.colorScheme,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Encart « meilleur prix ».
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

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Meilleur prix',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              prixMin != null ? formaterPrix(prixMin) : '—',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Chez ${meilleur.marche.nom}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Graphique en barres des derniers prix par marché.
class _BarChartPrix extends StatelessWidget {
  const _BarChartPrix({required this.comparaison});

  final Comparaison comparaison;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paire = comparaison.prixParMarche
        .where((p) => p.dernierPrix != null)
        .toList();

    final maxPrix = paire
            .map((p) => p.dernierPrix!)
            .reduce((a, b) => a > b ? a : b) *
        1.1;

    return SizedBox(
      height: 220,
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
                    width: 22,
                    color: theme.colorScheme.primary,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
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
                    style: theme.textTheme.bodySmall,
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= paire.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _nomCourt(paire[index].marche.nom),
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: const FlGridData(drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final nom = paire[group.x].marche.nom;
                return BarTooltipItem(
                  '$nom\n${formaterPrix(rod.toY)}',
                  theme.textTheme.bodySmall!.copyWith(
                    color: Colors.white,
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
    final tronque = nom.length > 12 ? nom.substring(0, 12) : nom;
    return tronque;
  }
}

/// Ligne « prix par marché » avec écart en %.
class _LignePrixMarche extends StatelessWidget {
  const _LignePrixMarche({
    required this.prixParMarche,
    required this.estLeMoinsCher,
    required this.colorTheme,
  });

  final PrixParMarche prixParMarche;
  final bool estLeMoinsCher;
  final ColorScheme colorTheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prix = prixParMarche.dernierPrix;
    final ecart = prixParMarche.ecartPourcentage;

    return Card(
      child: ListTile(
        leading: Icon(
          estLeMoinsCher ? Icons.emoji_events : Icons.storefront,
          color: estLeMoinsCher ? Colors.amber[700] : colorTheme.primary,
        ),
        title: Text(prixParMarche.marche.nom),
        subtitle: Text(
          prix != null ? formaterPrix(prix) : 'Aucun relevé récent',
        ),
        trailing: ecart != null && ecart > 0
            ? Text(
                '+${ecart.toStringAsFixed(1)} %',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
              )
            : const Icon(Icons.check_circle, color: Colors.green),
      ),
    );
  }
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
              return RefreshIndicator(
                onRefresh: _recharger,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _LineChartPrix(points: points),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          '${_intituleMode()} des prix relevés : '
                          '${_variation(points)}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
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

  String _variation(List<HistoriquePoint> points) {
    if (points.length < 2) {
      return '${formaterPrix(points.first.valeur)} (début de suivi)';
    }
    final premier = points.first.valeur;
    final dernier = points.last.valeur;
    final variation = dernier - premier;
    final signe = variation >= 0 ? '+' : '';
    final pct = premier != 0 ? (variation / premier * 100).toStringAsFixed(1) : '0';
    return '${formaterPrix(premier)} → ${formaterPrix(dernier)} '
        '($signe$pct %)';
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
              color: theme.colorScheme.primary,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
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
                reservedSize: 44,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}',
                    style: theme.textTheme.bodySmall,
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      formaterDateCourte(points[index].date),
                      style: theme.textTheme.bodySmall,
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
              getTooltipItems: (touchedSpots) {
                return touchedSpots
                    .map(
                      (spot) => LineTooltipItem(
                        '${formaterDate(points[spot.x.toInt()].date)}\n'
                        '${formaterPrix(spot.y)}',
                        theme.textTheme.bodySmall!.copyWith(
                          color: Colors.white,
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