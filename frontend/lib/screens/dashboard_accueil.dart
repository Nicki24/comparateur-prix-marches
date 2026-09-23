import 'package:flutter/material.dart';

import '../models/produit.dart';
import '../models/releve_prix.dart';
import '../services/api_client.dart';
import '../services/comparison_service.dart';
import '../services/marche_service.dart';
import '../services/produit_service.dart';
import '../services/releve_service.dart';
import '../services/session.dart';
import '../theme/app_theme.dart';
import '../utils/formats.dart';
import '../widgets/ms_anim.dart';
import '../widgets/ms_badge.dart';
import '../widgets/ms_card.dart';
import '../widgets/ms_decor.dart';
import '../widgets/produit_icone.dart';
import '../widgets/statut_badge.dart';
import 'comparaison_screen.dart';
import 'marches_screen.dart';

/// Onglet d'accueil : tableau de bord « Market Overview ».
///
/// Héros avec prix moyen, compteurs de la plateforme, bandeau ticker,
/// variations importantes, marchés et produits populaires.
class DashboardAccueil extends StatefulWidget {
  const DashboardAccueil({
    super.key,
    this.onVoirMarches,
    this.onVoirProduits,
  });

  /// Basculent la barre de navigation sur l'onglet correspondant.
  final VoidCallback? onVoirMarches;
  final VoidCallback? onVoirProduits;

  @override
  State<DashboardAccueil> createState() => _DashboardAccueilState();
}

class _DashboardAccueilState extends State<DashboardAccueil> {
  late Future<_DonneesDashboard> _futur;

  @override
  void initState() {
    super.initState();
    _futur = _charger();
  }

  Future<_DonneesDashboard> _charger() async {
    return _DonneesDashboard.charger();
  }

  Future<void> _recharger() async {
    setState(() {
      _futur = _charger();
    });
    await _futur;
  }

  String _salutation() {
    final h = DateTime.now().hour;
    if (h < 5) return 'Bonne nuit';
    if (h < 12) return 'Bonjour';
    if (h < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const _MiniLogo(),
            const SizedBox(width: 10),
            Text(
              'MarketScope',
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.paper,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.paper,
      ),
      body: MsDecorFond(
        child: FutureBuilder<_DonneesDashboard>(
          future: _futur,
          builder: (context, snapshot) {
            final enChargement =
                snapshot.connectionState != ConnectionState.done;
            final donnees = snapshot.data;

            return RefreshIndicator(
              color: AppColors.green,
              onRefresh: _recharger,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.only(bottom: AppSpacing.xl),
                children: [
                  const SizedBox(height: AppSpacing.md),
                  // ── Salutation + vue générale ──────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _salutation(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme
                                .colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Vue générale du marché',
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(
                            fontFamily: AppFonts.display,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (!enChargement && donnees != null) ...[
                    MsApparition(
                        child: _HeroApercuMarche(
                            donnees: donnees)),
                    const SizedBox(height: AppSpacing.md),
                    _GrilleStats(donnees: donnees),
                    const SizedBox(height: AppSpacing.lg),
                    if (donnees.variations.isNotEmpty) ...[
                      MarketScopeSectionTitle(
                        titre: 'Variations importantes',
                        icone: Icons.trending_up_rounded,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _ListeVariations(
                          variations: donnees.variations),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    const MarketScopeSectionTitle(
                      titre: 'Derniers relevés',
                      icone: Icons.history_rounded,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const _DerniersReleves(),
                    const SizedBox(height: AppSpacing.lg),
                    if (donnees.marches.isNotEmpty) ...[
                      MarketScopeSectionTitle(
                        titre: 'Marchés populaires',
                        icone: Icons.storefront_rounded,
                        actionLabel: 'Tout voir',
                        onAction: widget.onVoirMarches,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _ListeMarches(marches: donnees.marches),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    if (donnees.produits.isNotEmpty) ...[
                      MarketScopeSectionTitle(
                        titre: 'Produits populaires',
                        icone: Icons.shopping_basket_rounded,
                        actionLabel: 'Tout voir',
                        onAction: widget.onVoirProduits,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _ListeProduits(
                        produits: donnees.produits,
                        variations: donnees.variations,
                      ),
                    ],
                  ] else if (snapshot.hasError) ...[
                    Padding(
                      padding:
                          const EdgeInsets.all(AppSpacing.lg),
                      child: _ErreurDashboard(
                        message: snapshot.error.toString(),
                        onReessayer: _recharger,
                      ),
                    ),
                  ] else ...[
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: Center(
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Données agrégées du tableau de bord (stats publiques, marchés, produits
/// et variations calculées à partir des historiques récents).
class _DonneesDashboard {
  _DonneesDashboard({
    required this.stats,
    required this.marches,
    required this.produits,
    required this.variations,
  });

  final Map<String, dynamic>? stats;
  final List<dynamic> marches;
  final List<Produit> produits;
  final List<_VariationProduit> variations;

  DateTime? get derniereMaj {
    final brut = stats?['derniere_mise_a_jour'];
    if (brut is String) {
      return DateTime.tryParse(brut);
    }
    return null;
  }

  double? get prixMoyen {
    if (variations.isEmpty) {
      return null;
    }
    return variations.fold<double>(0, (acc, v) => acc + v.prix) /
        variations.length;
  }

  double? get variationMoyenne {
    if (variations.isEmpty) {
      return null;
    }
    return variations.fold<double>(0, (acc, v) => acc + v.variationPct) /
        variations.length;
  }

  static Future<_DonneesDashboard> charger() async {
    Map<String, dynamic>? stats;
    try {
      final s = await ApiClient.instance.get('/stats');
      if (s is Map<String, dynamic>) {
        stats = s;
      }
    } catch (_) {}

    List<dynamic> marches = const [];
    try {
      marches = await MarcheService.lister();
    } catch (_) {}

    List<Produit> produits = const [];
    try {
      produits = await ProduitService.lister();
    } catch (_) {}

    final variations = <_VariationProduit>[];
    for (final produit in produits.take(6)) {
      try {
        final points = await ComparisonService.historique(produit.id);
        if (points.length < 2) {
          continue;
        }
        final dernier = points.last;
        final precedent = points[points.length - 2];
        if (precedent.valeur == 0 || dernier.valeur == 0) {
          continue;
        }
        final pct =
            (dernier.valeur - precedent.valeur) / precedent.valeur * 100;
        variations.add(
          _VariationProduit(
            produit: produit,
            prix: dernier.valeur,
            prixPrecedent: precedent.valeur,
            variationPct: pct,
          ),
        );
      } catch (_) {
        continue;
      }
    }
    variations.sort(
      (a, b) => b.variationPct.abs().compareTo(a.variationPct.abs()),
    );

    return _DonneesDashboard(
      stats: stats,
      marches: marches,
      produits: produits.take(6).toList(),
      variations: variations.take(5).toList(),
    );
  }
}

/// Variation d'un produit entre son dernier relevé et le précédent.
class _VariationProduit {
  _VariationProduit({
    required this.produit,
    required this.prix,
    required this.prixPrecedent,
    required this.variationPct,
  });

  final Produit produit;
  final double prix;
  final double prixPrecedent;
  final double variationPct;

  bool get estBaisse => variationPct < 0;
}

// ---------------------------------------------------------------------------
// Mini logo rond pour l'AppBar (asset réel, sans déformation)
// ---------------------------------------------------------------------------
class _MiniLogo extends StatelessWidget {
  const _MiniLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: ClipOval(
        child: Image.asset(
          'assets/marketscope_logo_round.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.storefront_rounded,
            size: 20,
            color: AppColors.greenLight,
          ),
        ),
      ),
    );
  }
}

/// Grille 2×2 des stats principales : marchés, produits, prix moyen, évolution.
/// Responsive : 2 colonnes sur mobile, marges 16, espacement 12.
class _GrilleStats extends StatelessWidget {
  const _GrilleStats({required this.donnees});

  final _DonneesDashboard donnees;

  int? _nombre(String cle) {
    final v = donnees.stats?[cle];
    return v is num ? v.toInt() : null;
  }

  @override
  Widget build(BuildContext context) {
    final prixMoyen = donnees.prixMoyen;
    final evo = donnees.variationMoyenne;
    final nbMarches = _nombre('nb_marches_actifs');
    final nbProduits = _nombre('nb_produits_actifs');

    Widget evoBadge() {
      if (evo == null) return const SizedBox.shrink();
      return MarketScopeVariationBadge(
          variationPct: evo, compact: true);
    }

    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: LayoutBuilder(
        builder: (context, c) {
          final deuxCol = c.maxWidth > 360;
          final cards = [
            MarketScopeStatCard(
              icone: Icons.storefront_rounded,
              couleur: AppColors.saffron,
              valeur: nbMarches != null
                  ? formaterNombre(nbMarches)
                  : '…',
              label: 'Marchés suivis',
            ),
            MarketScopeStatCard(
              icone: Icons.shopping_basket_rounded,
              couleur: AppColors.green,
              valeur: nbProduits != null
                  ? formaterNombre(nbProduits)
                  : '…',
              label: 'Produits suivis',
            ),
            MarketScopeStatCard(
              icone: Icons.payments_rounded,
              couleur: AppColors.green,
              valeur: prixMoyen != null
                  ? formaterPrix(prixMoyen)
                  : '—',
              label: 'Prix moyen observé',
            ),
            MarketScopeStatCard(
              icone: (evo ?? 0) < 0
                  ? Icons.trending_down_rounded
                  : Icons.trending_up_rounded,
              couleur: (evo ?? 0) < 0
                  ? AppColors.green
                  : AppColors.terracotta,
              valeur: evo != null
                  ? '${evo < 0 ? '−' : '+'}${evo.abs().toStringAsFixed(1)} %'
                  : '—',
              label: 'Évolution globale',
              sousValeur: evoBadge(),
            ),
          ];
          if (!deuxCol) {
            return Column(
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  MsCascade(index: i, child: cards[i]),
                  if (i != cards.length - 1)
                    const SizedBox(height: 12),
                ],
              ],
            );
          }
          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.55,
            children: [
              for (var i = 0; i < cards.length; i++)
                MsCascade(index: i, child: cards[i]),
            ],
          );
        },
      ),
    );
  }
}

/// Derniers relevés : personnels si connecté, sinon message discret.
/// Produit · marché · prix · date · statut (Validé / Signalé).
class _DerniersReleves extends StatelessWidget {
  const _DerniersReleves();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!Session.instance.estConnecte) {
      return Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: MarketScopeCard(
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Connectez-vous pour voir vos derniers relevés ici.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return FutureBuilder<List<RelevePrix>>(
      future: ReleveService.mesReleves(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md),
            child: LinearProgressIndicator(minHeight: 3),
          );
        }
        final releves = (snap.data ?? []).take(3).toList();
        if (releves.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md),
            child: Text(
              'Aucun relevé pour le moment.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md),
          child: Column(
            children: [
              for (var i = 0; i < releves.length; i++) ...[
                MsCascade(
                  index: i,
                  child: MarketScopeCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm),
                    child: Row(
                      children: [
                        ProduitIcone(
                          nom: releves[i].produit?.nom ?? '',
                          categorie:
                              releves[i].produit?.categorie,
                          taille: 38,
                          tailleIcone: 19,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                releves[i].produit?.nom ??
                                    'Produit',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(
                                        fontWeight:
                                            FontWeight.w700),
                              ),
                              Text(
                                '${releves[i].marche?.nom ?? ''} · ${formaterDateCourte(releves[i].dateReleve)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(
                                  color: theme.colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.end,
                          children: [
                            Text(
                              formaterPrix(
                                  releves[i].valeur),
                              style: AppTextStyles.priceSmall
                                  .copyWith(
                                color: theme.colorScheme
                                    .onSurface,
                              ),
                            ),
                            const SizedBox(height: 3),
                            releves[i].estSignale
                                ? const StatutBadge.alerte(
                                    'Signalé')
                                : const StatutBadge.ok(
                                    'Validé'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (i != releves.length - 1)
                  const SizedBox(height: 8),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Héros « Aperçu du marché »
// ---------------------------------------------------------------------------
class _HeroApercuMarche extends StatelessWidget {
  const _HeroApercuMarche({required this.donnees});

  final _DonneesDashboard donnees;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prixMoyen = donnees.prixMoyen;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.ink, AppColors.ink2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.sheet),
        boxShadow: AppShadow.card,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -40,
            child: _HaloDecor(couleur: AppColors.greenLight, taille: 170),
          ),
          Positioned(
            bottom: -60,
            left: -40,
            child: _HaloDecor(couleur: AppColors.saffron, taille: 150),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'APERÇU DU MARCHÉ',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF9FB6AE),
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (donnees.derniereMaj != null)
                      Text(
                        'MàJ ${formaterDateCourte(donnees.derniereMaj!)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF9FB6AE).withValues(alpha: 0.8),
                          fontSize: 10.5,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Prix moyen observé',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFCFE7D8),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        prixMoyen != null ? formaterPrix(prixMoyen) : '—',
                        style: stylePrix(
                          taille: 32,
                          couleur: AppColors.greenLight,
                          poids: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (prixMoyen != null) _PillVariationMoyenne(donnees),
                  ],
                ),
                if (prixMoyen == null)
                  Text(
                    'En attente de relevés de prix',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF9FB6AE),
                    ),
                  )
                else
                  Text(
                    'COLLECTER → ORGANISER → COMPARER → ANALYSER → COMPRENDRE',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF9FB6AE)
                          .withValues(alpha: 0.85),
                      fontSize: 10,
                      letterSpacing: 0.6,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

/// Pilule de variation du prix moyen (sur fond encre).
class _PillVariationMoyenne extends StatelessWidget {
  const _PillVariationMoyenne(this.donnees);

  final _DonneesDashboard donnees;

  @override
  Widget build(BuildContext context) {
    final pct = donnees.variationMoyenne;
    if (pct == null) {
      return const SizedBox.shrink();
    }
    final baisse = pct < 0;
    final couleur = baisse ? AppColors.greenLight : AppColors.darkTerracotta;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Container(
        key: ValueKey('variation-moy-${pct.toStringAsFixed(1)}'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: couleur.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: couleur.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              baisse
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              size: 13,
              color: couleur,
            ),
            const SizedBox(width: 3),
            Text(
              '${baisse ? '−' : '+'}${pct.abs().toStringAsFixed(1)} %',
              style: TextStyle(
                fontFamily: AppFonts.mono,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: couleur,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sections et listes
// ---------------------------------------------------------------------------
/// Cartes des variations importantes.
class _ListeVariations extends StatelessWidget {
  const _ListeVariations({required this.variations});

  final List<_VariationProduit> variations;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: [
          for (var i = 0; i < variations.length; i++) ...[
            MsCascade(
                index: i,
                child: _CarteVariation(variation: variations[i])),
            if (i != variations.length - 1)
              const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _CarteVariation extends StatelessWidget {
  const _CarteVariation({required this.variation});

  final _VariationProduit variation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final v = variation;

    return MarketScopeCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ComparaisonScreen(produit: v.produit),
          ),
        );
      },
      child: Row(
        children: [
          ProduitIcone(
            nom: v.produit.nom,
            categorie: v.produit.categorie,
            taille: 40,
            tailleIcone: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  v.produit.nom,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formaterPrix(v.prix)}${v.produit.uniteMesure.isEmpty ? '' : '/${v.produit.uniteMesure}'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.priceSmall.copyWith(
                    fontSize: 12.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          MarketScopeVariationBadge(
              variationPct: v.variationPct),
        ],
      ),
    );
  }
}

/// Rangée horizontale de cartes marchés compactes.
class _ListeMarches extends StatelessWidget {
  const _ListeMarches({required this.marches});

  final List<dynamic> marches;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: marches.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final m = marches[index] as dynamic;
          return _CarteMarcheCompact(
            nom: m.nom as String,
            localisation: m.localisation as String? ?? '',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MarcheDetailScreen(marche: m as dynamic),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CarteMarcheCompact extends StatelessWidget {
  const _CarteMarcheCompact({
    required this.nom,
    required this.localisation,
    required this.onTap,
  });

  final String nom;
  final String localisation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: isDark ? AppColors.darkSurface : AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Container(
          width: 150,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: isDark ? AppColors.darkLine : AppColors.line,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.storefront_rounded,
                      size: 15,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      nom,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      localisation,
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
      ),
    );
  }
}

/// Liste des produits populaires avec mini-variation.
class _ListeProduits extends StatelessWidget {
  const _ListeProduits({required this.produits, required this.variations});

  final List<Produit> produits;
  final List<_VariationProduit> variations;

  @override
  Widget build(BuildContext context) {
    final map = {for (final v in variations) v.produit.id: v};
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: [
          for (var i = 0; i < produits.length; i++) ...[
            _CarteProduitPopulaire(
              produit: produits[i],
              variation: map[produits[i].id],
            ),
            if (i != produits.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _CarteProduitPopulaire extends StatelessWidget {
  const _CarteProduitPopulaire({required this.produit, this.variation});

  final Produit produit;
  final _VariationProduit? variation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final v = variation;
    final prix = v != null ? formaterPrix(v.prix) : null;

    return MarketScopeCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ComparaisonScreen(produit: produit),
          ),
        );
      },
      child: Row(
        children: [
          ProduitIcone(
            nom: produit.nom,
            categorie: produit.categorie,
            taille: 40,
            tailleIcone: 20,
          ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      produit.nom,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      produit.categorie ?? 'Produit suivi',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (v != null) ...[
                MarketScopeVariationBadge(
                    variationPct: v.variationPct,
                    compact: true),
                const SizedBox(width: AppSpacing.sm),
              ],
              if (prix != null)
                Text(
                  prix,
                  style: AppTextStyles.priceSmall.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
    );
  }
}

/// Halo décoratif circulaire (aplat très faible) sur fond encre.
class _HaloDecor extends StatelessWidget {
  const _HaloDecor({required this.couleur, required this.taille});

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

/// Erreur du tableau de bord (le reste de l'app reste disponible).
class _ErreurDashboard extends StatelessWidget {
  const _ErreurDashboard({required this.message, required this.onReessayer});

  final String message;
  final VoidCallback onReessayer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 40,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: onReessayer,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}