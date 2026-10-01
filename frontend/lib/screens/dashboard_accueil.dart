import 'package:flutter/material.dart';

import '../models/comparaison.dart';
import '../models/marche.dart';
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
import '../widgets/etats.dart';
import '../widgets/marketscope_header.dart';
import '../widgets/ms_anim.dart';
import '../widgets/ms_badge.dart';
import '../widgets/ms_card.dart';
import '../widgets/produit_icone.dart';
import '../widgets/statut_badge.dart';
import 'comparaison_screen.dart';
import 'marches_screen.dart';

/// Onglet d'accueil : tableau de bord du marché.
///
/// Héros « meilleure économie du moment », chiffres clés de la plateforme,
/// variations récentes, derniers relevés personnels, marchés et produits.
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
    _futur = _DonneesDashboard.charger();
  }

  Future<void> _recharger() async {
    setState(() {
      _futur = _DonneesDashboard.charger(forcer: true);
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
    return Scaffold(
      appBar: const MarketScopeHeader(),
      body: FutureBuilder<_DonneesDashboard>(
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
          final donnees = snapshot.data!;
          return RefreshIndicator(
            color: Theme.of(context).marque,
            onRefresh: _recharger,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(
                  top: AppSpacing.lg, bottom: AppSpacing.xl),
              children: [
                _EnTete(
                  salutation: _salutation(),
                  derniereMaj: donnees.derniereMaj,
                ),
                const SizedBox(height: AppSpacing.md),
                MsApparition(child: _HeroEconomie(donnees: donnees)),
                const SizedBox(height: AppSpacing.md),
                _GrilleChiffres(stats: donnees.stats),
                if (donnees.variations.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  const MarketScopeSectionTitle(
                    titre: 'Variations récentes',
                    icone: Icons.swap_vert_rounded,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _ListeVariations(variations: donnees.variations),
                ],
                ListenableBuilder(
                  listenable: Session.instance,
                  builder: (context, _) {
                    if (!Session.instance.estConnecte) {
                      return const SizedBox.shrink();
                    }
                    return const Padding(
                      padding: EdgeInsets.only(top: AppSpacing.lg),
                      child: _DerniersReleves(),
                    );
                  },
                ),
                if (donnees.marches.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  MarketScopeSectionTitle(
                    titre: 'Marchés suivis',
                    icone: Icons.storefront_rounded,
                    actionLabel: 'Tout voir',
                    onAction: widget.onVoirMarches,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _ListeMarches(marches: donnees.marches),
                ],
                if (donnees.produits.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  MarketScopeSectionTitle(
                    titre: 'Meilleurs prix par produit',
                    icone: Icons.sell_rounded,
                    actionLabel: 'Tout voir',
                    onAction: widget.onVoirProduits,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _ListeProduits(donnees: donnees),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Données
// ---------------------------------------------------------------------------

/// Données agrégées du tableau de bord. Tous les appels partent en
/// parallèle ; seule l'indisponibilité totale de l'API remonte en erreur.
class _DonneesDashboard {
  _DonneesDashboard({
    required this.stats,
    required this.marches,
    required this.produits,
    required this.comparaisons,
    required this.variations,
  });

  final Map<String, dynamic>? stats;
  final List<Marche> marches;
  final List<Produit> produits;

  /// Comparaison par id de produit (produits sans relevé absents).
  final Map<int, Comparaison> comparaisons;
  final List<_VariationProduit> variations;

  DateTime? get derniereMaj {
    final brut = stats?['derniere_mise_a_jour'];
    return brut is String ? DateTime.tryParse(brut) : null;
  }

  /// Produit dont l'écart entre le marché le moins cher et le plus cher
  /// est le plus grand : c'est l'économie la plus parlante à montrer.
  _Economie? get meilleureEconomie {
    _Economie? meilleure;
    for (final c in comparaisons.values) {
      final e = _Economie.depuis(c);
      if (e == null) continue;
      if (meilleure == null || e.pourcentage > meilleure.pourcentage) {
        meilleure = e;
      }
    }
    return meilleure;
  }

  static Future<_DonneesDashboard> charger({bool forcer = false}) async {
    final resultats = await Future.wait<Object?>([
      ApiClient.instance.get('/stats').then<Object?>((s) => s,
          onError: (Object _) => null),
      MarcheService.lister(),
      ProduitService.lister(),
    ]);
    final stats = resultats[0] is Map<String, dynamic>
        ? resultats[0] as Map<String, dynamic>
        : null;
    final marches = resultats[1] as List<Marche>;
    final produits = resultats[2] as List<Produit>;

    final details = await Future.wait(produits.map((p) async {
      final comparaison = await ComparisonService.comparer(p.id,
              forcer: forcer)
          .then<Comparaison?>((c) => c, onError: (Object _) => null);
      final historique = await ComparisonService.historique(p.id)
          .then((h) => h, onError: (Object _) => const []);
      return (produit: p, comparaison: comparaison, historique: historique);
    }));

    final comparaisons = <int, Comparaison>{};
    final variations = <_VariationProduit>[];
    for (final d in details) {
      final c = d.comparaison;
      if (c != null && c.prixParMarche.any((p) => p.dernierPrix != null)) {
        comparaisons[d.produit.id] = c;
      }
      final points = d.historique;
      if (points.length >= 2) {
        final dernier = points.last.valeur;
        final precedent = points[points.length - 2].valeur;
        if (dernier > 0 && precedent > 0) {
          variations.add(_VariationProduit(
            produit: d.produit,
            prix: dernier,
            variationPct: (dernier - precedent) / precedent * 100,
          ));
        }
      }
    }
    variations.sort(
        (a, b) => b.variationPct.abs().compareTo(a.variationPct.abs()));

    return _DonneesDashboard(
      stats: stats,
      marches: marches,
      produits: produits,
      comparaisons: comparaisons,
      variations: variations.take(4).toList(),
    );
  }
}

class _VariationProduit {
  const _VariationProduit({
    required this.produit,
    required this.prix,
    required this.variationPct,
  });

  final Produit produit;
  final double prix;
  final double variationPct;
}

/// Écart de prix d'un produit entre le marché le moins cher et le plus cher.
class _Economie {
  const _Economie({
    required this.produit,
    required this.moinsCher,
    required this.plusCher,
  });

  final Produit produit;
  final PrixParMarche moinsCher;
  final PrixParMarche plusCher;

  double get ecart => plusCher.dernierPrix! - moinsCher.dernierPrix!;
  double get pourcentage => ecart / plusCher.dernierPrix! * 100;

  static _Economie? depuis(Comparaison c) {
    final avecPrix =
        c.prixParMarche.where((p) => p.dernierPrix != null).toList();
    if (avecPrix.length < 2) return null;
    avecPrix.sort((a, b) => a.dernierPrix!.compareTo(b.dernierPrix!));
    if (avecPrix.last.dernierPrix! <= 0) return null;
    return _Economie(
      produit: c.produit,
      moinsCher: avecPrix.first,
      plusCher: avecPrix.last,
    );
  }
}

String _parUnite(Produit p) =>
    p.uniteMesure.isEmpty ? '' : '/${p.uniteMesure}';

void _ouvrirComparaison(BuildContext context, Produit produit) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ComparaisonScreen(produit: produit),
    ),
  );
}

// ---------------------------------------------------------------------------
// En-tête et héros
// ---------------------------------------------------------------------------

class _EnTete extends StatelessWidget {
  const _EnTete({required this.salutation, required this.derniereMaj});

  final String salutation;
  final DateTime? derniereMaj;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            salutation,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Les prix des marchés de Toliara',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          if (derniereMaj != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: theme.marque,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Dernier relevé le ${formaterDate(derniereMaj!)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Héros encre : l'économie la plus importante qu'on peut faire aujourd'hui.
class _HeroEconomie extends StatelessWidget {
  const _HeroEconomie({required this.donnees});

  final _DonneesDashboard donnees;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final e = donnees.meilleureEconomie;

    const clair = Color(0xFFEAF3EE);
    const attenue = Color(0xFF9FB6AE);

    final Widget contenu;
    if (e == null) {
      contenu = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Surtitre('COMPARER POUR ÉCONOMISER'),
          const SizedBox(height: 10),
          Text(
            'Pas encore assez de relevés pour comparer les marchés.',
            style: theme.textTheme.titleMedium?.copyWith(color: clair),
          ),
          const SizedBox(height: 6),
          Text(
            'Les comparaisons apparaîtront dès que deux marchés auront un prix pour le même produit.',
            style: theme.textTheme.bodySmall?.copyWith(color: attenue),
          ),
        ],
      );
    } else {
      final unite = _parUnite(e.produit);
      contenu = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Surtitre('MEILLEURE ÉCONOMIE DU MOMENT'),
          const SizedBox(height: 12),
          Row(
            children: [
              ProduitIcone(
                nom: e.produit.nom,
                categorie: e.produit.categorie,
                taille: 36,
                tailleIcone: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  e.produit.nom,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: clair,
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                formaterPrix(e.ecart),
                style: stylePrix(
                  taille: 30,
                  couleur: AppColors.greenLight,
                  poids: FontWeight.w700,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  'd’économie${e.produit.uniteMesure.isEmpty ? '' : ' par ${e.produit.uniteMesure}'}'
                  ' · ${e.pourcentage.round()} % moins cher',
                  style: theme.textTheme.bodyMedium?.copyWith(color: attenue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _LigneMarcheHero(
            couleur: AppColors.greenLight,
            libelle: nomCourtMarche(e.moinsCher.marche.nom),
            prix: '${formaterPrix(e.moinsCher.dernierPrix!)}$unite',
            fort: true,
          ),
          const SizedBox(height: 6),
          _LigneMarcheHero(
            couleur: AppColors.darkTerracotta,
            libelle: nomCourtMarche(e.plusCher.marche.nom),
            prix: '${formaterPrix(e.plusCher.dernierPrix!)}$unite',
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _ouvrirComparaison(context, e.produit),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.greenLight,
                foregroundColor: AppColors.ink,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.bar_chart_rounded, size: 18),
              label: const Text('Comparer tous les marchés'),
            ),
          ),
        ],
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.ink, AppColors.ink2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.sheet + 4),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
            spreadRadius: -6,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -50,
            child: _Halo(couleur: AppColors.greenLight, taille: 190),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: contenu,
          ),
        ],
      ),
    );
  }
}

class _Surtitre extends StatelessWidget {
  const _Surtitre(this.texte);

  final String texte;

  @override
  Widget build(BuildContext context) {
    return Text(
      texte,
      style: const TextStyle(
        fontFamily: AppFonts.mono,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.1,
        color: Color(0xFF9FB6AE),
      ),
    );
  }
}

class _LigneMarcheHero extends StatelessWidget {
  const _LigneMarcheHero({
    required this.couleur,
    required this.libelle,
    required this.prix,
    this.fort = false,
  });

  final Color couleur;
  final String libelle;
  final String prix;
  final bool fort;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            libelle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppFonts.sans,
              fontSize: 13.5,
              fontWeight: fort ? FontWeight.w600 : FontWeight.w400,
              color: fort ? const Color(0xFFEAF3EE) : const Color(0xFF9FB6AE),
            ),
          ),
        ),
        Text(
          prix,
          style: stylePrix(
            taille: 13,
            couleur: fort ? const Color(0xFFEAF3EE) : const Color(0xFF9FB6AE),
          ),
        ),
      ],
    );
  }
}

class _Halo extends StatelessWidget {
  const _Halo({required this.couleur, required this.taille});

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
            couleur.withValues(alpha: 0.16),
            couleur.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chiffres clés
// ---------------------------------------------------------------------------

/// Chiffres clés de la plateforme en grille 2 × 2 (hauteurs égales).
class _GrilleChiffres extends StatelessWidget {
  const _GrilleChiffres({required this.stats});

  final Map<String, dynamic>? stats;

  String _valeur(String cle) {
    final v = stats?[cle];
    return v is num ? formaterNombre(v) : '—';
  }

  @override
  Widget build(BuildContext context) {
    final cartes = [
      MarketScopeStatCard(
        icone: Icons.receipt_long_rounded,
        couleur: AppColors.green,
        valeur: _valeur('nb_releves'),
        label: 'Relevés de prix',
      ),
      MarketScopeStatCard(
        icone: Icons.storefront_rounded,
        couleur: AppColors.saffron,
        valeur: _valeur('nb_marches_actifs'),
        label: 'Marchés suivis',
      ),
      MarketScopeStatCard(
        icone: Icons.shopping_basket_rounded,
        couleur: AppColors.terracotta,
        valeur: _valeur('nb_produits_actifs'),
        label: 'Produits suivis',
      ),
      MarketScopeStatCard(
        icone: Icons.groups_rounded,
        couleur: const Color(0xFF1D6FA5),
        valeur: _valeur('nb_contributeurs'),
        label: 'Contributeurs',
      ),
    ];

    Widget ligne(int a, int b) => IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: MsCascade(index: a, child: cartes[a])),
              const SizedBox(width: 12),
              Expanded(child: MsCascade(index: b, child: cartes[b])),
            ],
          ),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: [
          ligne(0, 1),
          const SizedBox(height: 12),
          ligne(2, 3),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Listes
// ---------------------------------------------------------------------------

class _ListeVariations extends StatelessWidget {
  const _ListeVariations({required this.variations});

  final List<_VariationProduit> variations;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: MarketScopeCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (var i = 0; i < variations.length; i++) ...[
              if (i > 0) Divider(height: 1, indent: 64, color: theme.ligne),
              _LigneProduit(
                produit: variations[i].produit,
                sousTitre:
                    'Moyenne ${formaterPrix(variations[i].prix)}${_parUnite(variations[i].produit)}',
                trailing: MarketScopeVariationBadge(
                    variationPct: variations[i].variationPct),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Ligne de liste produit réutilisable (icône, nom, sous-titre, élément droit).
class _LigneProduit extends StatelessWidget {
  const _LigneProduit({
    required this.produit,
    required this.sousTitre,
    required this.trailing,
  });

  final Produit produit;
  final String sousTitre;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => _ouvrirComparaison(context, produit),
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
                  const SizedBox(height: 1),
                  Text(
                    sousTitre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            trailing,
          ],
        ),
      ),
    );
  }
}

/// Derniers relevés personnels (visible uniquement si connecté).
class _DerniersReleves extends StatefulWidget {
  const _DerniersReleves();

  @override
  State<_DerniersReleves> createState() => _DerniersRelevesState();
}

class _DerniersRelevesState extends State<_DerniersReleves> {
  // Chargé une seule fois (et non à chaque reconstruction de l'écran).
  late final Future<List<RelevePrix>> _futur = ReleveService.mesReleves();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MarketScopeSectionTitle(
          titre: 'Mes derniers relevés',
          icone: Icons.history_rounded,
        ),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: FutureBuilder<List<RelevePrix>>(
            future: _futur,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const LinearProgressIndicator(minHeight: 2);
              }
              final releves = (snap.data ?? const []).take(3).toList();
              if (releves.isEmpty) {
                return Text(
                  snap.hasError
                      ? 'Impossible de charger vos relevés.'
                      : 'Vous n\'avez pas encore saisi de relevé.',
                  style: theme.textTheme.bodySmall,
                );
              }
              return MarketScopeCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < releves.length; i++) ...[
                      if (i > 0)
                        Divider(height: 1, indent: 64, color: theme.ligne),
                      _LigneReleve(releve: releves[i]),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LigneReleve extends StatelessWidget {
  const _LigneReleve({required this.releve});

  final RelevePrix releve;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
      child: Row(
        children: [
          ProduitIcone(
            nom: releve.produit?.nom ?? '',
            categorie: releve.produit?.categorie,
            taille: 38,
            tailleIcone: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  releve.produit?.nom ?? 'Produit',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  '${nomCourtMarche(releve.marche?.nom ?? '')} · ${formaterDateLisible(releve.dateReleve)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
              const SizedBox(height: 3),
              releve.estSignale
                  ? const StatutBadge.alerte('Signalé')
                  : const StatutBadge.ok('Validé'),
            ],
          ),
        ],
      ),
    );
  }
}

/// Rangée horizontale de cartes marchés.
class _ListeMarches extends StatelessWidget {
  const _ListeMarches({required this.marches});

  final List<Marche> marches;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: marches.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final m = marches[index];
          return SizedBox(
            width: 168,
            child: MarketScopeCard(
              sansOmbre: true,
              padding: const EdgeInsets.all(12),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MarcheDetailScreen(marche: m),
                ),
              ),
              child: _ContenuCarteMarche(marche: m),
            ),
          );
        },
      ),
    );
  }
}

class _ContenuCarteMarche extends StatelessWidget {
  const _ContenuCarteMarche({required this.marche});

  final Marche marche;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.saffron.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.storefront_rounded,
                size: 15,
                color: AppColors.saffron,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                nomCourtMarche(marche.nom),
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
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 3),
            Expanded(
              child: Text(
                marche.localisation,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Produits avec leur meilleur prix actuel et le marché correspondant.
class _ListeProduits extends StatelessWidget {
  const _ListeProduits({required this.donnees});

  final _DonneesDashboard donnees;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final produits = donnees.produits.take(6).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: MarketScopeCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (var i = 0; i < produits.length; i++) ...[
              if (i > 0) Divider(height: 1, indent: 64, color: theme.ligne),
              _ligne(context, produits[i]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _ligne(BuildContext context, Produit produit) {
    final theme = Theme.of(context);
    final c = donnees.comparaisons[produit.id];
    PrixParMarche? meilleur;
    if (c != null) {
      for (final p in c.prixParMarche) {
        if (p.dernierPrix == null) continue;
        if (meilleur == null || p.dernierPrix! < meilleur.dernierPrix!) {
          meilleur = p;
        }
      }
    }
    return _LigneProduit(
      produit: produit,
      sousTitre: meilleur != null
          ? 'Chez ${nomCourtMarche(meilleur.marche.nom)}'
          : 'Aucun prix relevé',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (meilleur != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formaterPrix(meilleur.dernierPrix!),
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
    );
  }
}
