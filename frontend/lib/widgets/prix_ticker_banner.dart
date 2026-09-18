import 'dart:async';
import 'package:flutter/material.dart';

import '../models/produit.dart';
import '../services/comparison_service.dart';
import '../services/produit_service.dart';
import '../theme/app_theme.dart';
import '../utils/formats.dart';

/// Bandeau horizontal défilant affichant les derniers prix par marché,
/// exactement comme dans la charte graphique MarketScope.
///
/// Fond [AppColors.ink] · texte IBM Plex Mono vert tendre · défilement continu.
class PrixTickerBanner extends StatefulWidget {
  const PrixTickerBanner({super.key});

  @override
  State<PrixTickerBanner> createState() => _PrixTickerBannerState();
}

class _PrixTickerBannerState extends State<PrixTickerBanner> {
  List<_TickerItem> _items = [];
  bool _chargement = true;
  bool _enRefresh = false;
  DateTime? _derniereMaj;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _rafraichir() async {
    if (_enRefresh) return;
    setState(() => _enRefresh = true);
    await _charger();
    if (mounted) setState(() => _enRefresh = false);
  }

  Future<void> _charger() async {
    try {
      final produits = await ProduitService.lister();
      if (!mounted) return;

      final items = <_TickerItem>[];

      // On récupère les comparaisons des 5 premiers produits max.
      final cibles = produits.take(5).toList();
      for (final produit in cibles) {
        try {
          final cmp = await ComparisonService.comparer(produit.id);
          for (final ppm in cmp.prixParMarche) {
            if (ppm.dernierPrix != null) {
              items.add(_TickerItem(
                produit: produit,
                marcheNom: ppm.marche.nom,
                prix: ppm.dernierPrix!,
              ));
            }
          }
        } catch (_) {
          // Produit sans relevé → on ignore.
        }
      }

      if (!mounted) return;
      setState(() {
        _items = items.isEmpty ? _itemsDemoFallback() : items;
        _chargement = false;
        if (items.isNotEmpty) _derniereMaj = DateTime.now();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = _itemsDemoFallback();
        _chargement = false;
      });
    }
  }

  /// Données de démonstration si l'API n'est pas disponible.
  List<_TickerItem> _itemsDemoFallback() => [
        _TickerItem(produit: null, marcheNom: 'Marché du Sud', prix: 4200, nomManuel: 'RIZ'),
        _TickerItem(produit: null, marcheNom: 'Bazar Be', prix: 10500, nomManuel: 'HUILE'),
        _TickerItem(produit: null, marcheNom: 'Marché Analakely', prix: 3800, nomManuel: 'SUCRE'),
        _TickerItem(produit: null, marcheNom: 'Marché du Sud', prix: 1200, nomManuel: 'SAVON'),
        _TickerItem(produit: null, marcheNom: 'Bazar Be', prix: 2900, nomManuel: 'FARINE'),
      ];

  @override
  Widget build(BuildContext context) {
    // Hauteur fixe du bandeau.
    const double hauteur = 34;

    if (_chargement || _items.isEmpty) {
      return Container(
        height: hauteur,
        color: AppColors.ink,
      );
    }

    // On duplique les items pour l'effet de boucle seamless.
    final double? reduced = MediaQuery.of(context).accessibleNavigation ? 1 : null;
    final bool animationDesactivee = reduced != null;

    return Container(
      height: hauteur,
      color: AppColors.ink,
      child: Stack(
        children: [
          Positioned.fill(
            child: animationDesactivee
                ? _BandeauStatique(items: _items)
                : _BandeauDefilant(items: _items),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: _PanneauMaj(
              enRefresh: _enRefresh,
              derniereMaj: _derniereMaj,
              onRafraichir: _rafraichir,
            ),
          ),
        ],
      ),
    );
  }
}

/// Coin droit du bandeau : rappel de la dernière mise à jour + bouton
/// de rafraîchissement, sur un dégradé pour rester lisible au-dessus
/// du défilement.
class _PanneauMaj extends StatelessWidget {
  const _PanneauMaj({
    required this.enRefresh,
    required this.derniereMaj,
    required this.onRafraichir,
  });

  final bool enRefresh;
  final DateTime? derniereMaj;
  final VoidCallback onRafraichir;

  @override
  Widget build(BuildContext context) {
    final maj = derniereMaj;
    return Container(
      padding: const EdgeInsets.only(left: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.ink.withValues(alpha: 0),
            AppColors.ink,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          stops: const [0, 0.55],
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (maj != null) ...[
            Text(
              'MAJ ${formaterHeure(maj)}',
              style: const TextStyle(
                fontFamily: AppFonts.mono,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Color(0xFF8DB5A0),
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Tooltip(
            message: 'Rafraîchir les prix',
            child: SizedBox(
              width: 30,
              height: 30,
              child: enRefresh
                  ? const Padding(
                      padding: EdgeInsets.all(7),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.greenLight,
                      ),
                    )
                  : IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 16,
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: AppColors.greenLight,
                      ),
                      onPressed: onRafraichir,
                    ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bandeau défilant (animation)
// ---------------------------------------------------------------------------
class _BandeauDefilant extends StatefulWidget {
  const _BandeauDefilant({required this.items});
  final List<_TickerItem> items;

  @override
  State<_BandeauDefilant> createState() => _BandeauDefilantState();
}

class _BandeauDefilantState extends State<_BandeauDefilant>
    with SingleTickerProviderStateMixin {
  late final ScrollController _ctrl;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _ctrl = ScrollController();
    // On lance le défilement après le premier frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _demarrerDefilement());
  }

  void _demarrerDefilement() {
    _timer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      if (!mounted || !_ctrl.hasClients) return;
      final max = _ctrl.position.maxScrollExtent;
      final pos = _ctrl.offset;
      if (pos >= max) {
        // Retour au début sans animation pour l'effet boucle.
        _ctrl.jumpTo(0);
      } else {
        _ctrl.jumpTo(pos + 1.2);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Triplage des items pour le scrolling infini seamless.
    final tous = [...widget.items, ...widget.items, ...widget.items];
    return ListView.separated(
      controller: _ctrl,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: tous.length,
      separatorBuilder: (_, __) => const _SeparateurTicker(),
      itemBuilder: (context, i) => _TuileTicker(item: tous[i]),
    );
  }
}

// ---------------------------------------------------------------------------
// Bandeau statique (mode accessibilité reduced-motion)
// ---------------------------------------------------------------------------
class _BandeauStatique extends StatelessWidget {
  const _BandeauStatique({required this.items});
  final List<_TickerItem> items;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const _SeparateurTicker(),
      itemBuilder: (context, i) => _TuileTicker(item: items[i]),
    );
  }
}

// ---------------------------------------------------------------------------
// Tuile individuelle : PRODUIT · prix Ar · Marché
// ---------------------------------------------------------------------------
class _TuileTicker extends StatelessWidget {
  const _TuileTicker({required this.item});
  final _TickerItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.35),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: Text(
              item.nom.toUpperCase(),
              key: ValueKey('nom-${item.nom}'),
              style: const TextStyle(
                fontFamily: AppFonts.mono,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFD6ECDD),
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.35),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: Text(
              formaterPrix(item.prix),
              key: ValueKey('prix-${item.prix}'),
              style: const TextStyle(
                fontFamily: AppFonts.mono,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6FD98C), // vert lumineux
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '· ${item.marcheNom}',
            style: const TextStyle(
              fontFamily: AppFonts.sans,
              fontSize: 11.5,
              color: Color(0xFF8DB5A0),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeparateurTicker extends StatelessWidget {
  const _SeparateurTicker();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        '·',
        style: TextStyle(
          color: Color(0xFF4A6E60),
          fontSize: 14,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Modèle interne du ticker
// ---------------------------------------------------------------------------
class _TickerItem {
  _TickerItem({
    required this.produit,
    required this.marcheNom,
    required this.prix,
    this.nomManuel,
  });

  final Produit? produit;
  final String marcheNom;
  final double prix;
  final String? nomManuel;

  String get nom => nomManuel ?? produit?.nom ?? '—';
}
