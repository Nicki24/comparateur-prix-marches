import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../models/comparaison.dart';
import '../services/comparison_service.dart';
import '../services/produit_service.dart';
import '../theme/app_theme.dart';
import '../utils/formats.dart';
import '../utils/mise_en_page.dart';

/// Bandeau « meilleurs prix du moment » : pour chaque produit, le prix le
/// plus bas relevé et le marché où il a été observé.
///
/// Uniquement des données réelles : si l'API ne répond pas ou qu'aucun
/// relevé n'existe, le bandeau affiche un message neutre (jamais de prix
/// fictifs). Défilement continu, figé si l'utilisateur a demandé la
/// réduction des animations.
class PrixTickerBanner extends StatefulWidget {
  const PrixTickerBanner({super.key});

  static const double hauteur = 32;

  /// Hauteur en plein écran (textes agrandis de 15 %).
  static const double hauteurLarge = 38;

  @override
  State<PrixTickerBanner> createState() => _PrixTickerBannerState();
}

class _PrixTickerBannerState extends State<PrixTickerBanner> {
  List<_TickerItem> _items = const [];
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger({bool forcer = false}) async {
    setState(() => _chargement = true);
    List<_TickerItem> items = const [];
    try {
      final produits = await ProduitService.lister();
      final comparaisons = await Future.wait(
        produits.map((p) => ComparisonService.comparer(p.id, forcer: forcer)
            .then<Comparaison?>((c) => c)
            .catchError((Object _) => null)),
      );
      items = [
        for (final c in comparaisons)
          if (c != null) ?_meilleur(c),
      ];
    } catch (_) {
      items = const [];
    }
    if (!mounted) return;
    setState(() {
      _items = items;
      _chargement = false;
    });
  }

  _TickerItem? _meilleur(Comparaison c) {
    PrixParMarche? min;
    for (final p in c.prixParMarche) {
      if (p.dernierPrix == null) continue;
      if (min == null || p.dernierPrix! < min.dernierPrix!) min = p;
    }
    if (min == null) return null;
    return _TickerItem(
      produit: nomCourtProduit(c.produit.nom),
      unite: c.produit.uniteMesure,
      marche: nomCourtMarche(min.marche.nom),
      prix: min.dernierPrix!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget contenu;
    if (_chargement) {
      contenu = const SizedBox.shrink();
    } else if (_items.isEmpty) {
      contenu = const Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.only(left: 12),
          child: Text(
            'Prix du jour indisponibles pour le moment',
            style: TextStyle(
              fontFamily: AppFonts.sans,
              fontSize: 11.5,
              color: Color(0xFF8DB5A0),
            ),
          ),
        ),
      );
    } else if (MediaQuery.disableAnimationsOf(context)) {
      contenu = ListView(
        scrollDirection: Axis.horizontal,
        children: [for (final i in _items) _TuileTicker(item: i)],
      );
    } else {
      contenu = _BandeauDefilant(items: _items);
    }

    final large = MiseEnPage.estLarge(context);
    return SizedBox(
      height: large ? PrixTickerBanner.hauteurLarge : PrixTickerBanner.hauteur,
      // En plein écran, textes un peu plus grands pour rester lisibles.
      child: MediaQuery.withClampedTextScaling(
        minScaleFactor: large ? 1.15 : 1.0,
        child: Row(
        children: [
          const _EtiquetteTicker(),
          Expanded(
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (rect) => const LinearGradient(
                colors: [
                  Color(0x00000000),
                  Color(0xFF000000),
                  Color(0xFF000000),
                  Color(0x00000000),
                ],
                stops: [0, 0.04, 0.94, 1],
              ).createShader(rect),
              child: contenu,
            ),
          ),
          SizedBox(
            width: 36,
            child: _chargement
                ? const Center(
                    child: SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.6,
                        color: AppColors.greenLight,
                      ),
                    ),
                  )
                : IconButton(
                    tooltip: 'Actualiser les prix',
                    padding: EdgeInsets.zero,
                    iconSize: 16,
                    icon: const Icon(
                      PhosphorIconsRegular.arrowClockwise,
                      color: AppColors.greenLight,
                    ),
                    onPressed: () => _charger(forcer: true),
                  ),
          ),
        ],
      ),
      ),
    );
  }
}

/// Pastille fixe à gauche : « MEILLEURS PRIX ».
class _EtiquetteTicker extends StatelessWidget {
  const _EtiquetteTicker();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 12, right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.greenLight.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIconsRegular.arrowDown, size: 11, color: AppColors.greenLight),
          SizedBox(width: 3),
          Text(
            'MEILLEURS PRIX',
            style: TextStyle(
              fontFamily: AppFonts.mono,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: AppColors.greenLight,
            ),
          ),
        ],
      ),
    );
  }
}

/// Défilement continu et sans à-coup, piloté par un [Ticker] (60 fps) :
/// la liste est dupliquée et la position boucle sur la largeur d'une copie.
class _BandeauDefilant extends StatefulWidget {
  const _BandeauDefilant({required this.items});

  final List<_TickerItem> items;

  @override
  State<_BandeauDefilant> createState() => _BandeauDefilantState();
}

class _BandeauDefilantState extends State<_BandeauDefilant>
    with SingleTickerProviderStateMixin {
  static const _vitesse = 28.0; // pixels / seconde

  final _ctrl = ScrollController();
  final _cleCopie = GlobalKey();
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_avancer)..start();
  }

  void _avancer(Duration ecoule) {
    final copie = _cleCopie.currentContext?.size?.width;
    if (!_ctrl.hasClients || copie == null || copie <= 0) return;
    final distance = ecoule.inMicroseconds / 1e6 * _vitesse;
    _ctrl.jumpTo(distance % copie);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget copie({Key? key}) => Row(
          key: key,
          mainAxisSize: MainAxisSize.min,
          children: [for (final i in widget.items) _TuileTicker(item: i)],
        );
    return SingleChildScrollView(
      controller: _ctrl,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Row(
        children: [copie(key: _cleCopie), copie(), copie()],
      ),
    );
  }
}

/// Tuile : PRODUIT · prix/unité · marché.
class _TuileTicker extends StatelessWidget {
  const _TuileTicker({required this.item});

  final _TickerItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.produit.toUpperCase(),
            style: const TextStyle(
              fontFamily: AppFonts.mono,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: Color(0xFFD6ECDD),
            ),
          ),
          const SizedBox(width: 7),
          Text(
            item.unite.isEmpty
                ? formaterPrix(item.prix)
                : '${formaterPrix(item.prix)}/${item.unite}',
            style: const TextStyle(
              fontFamily: AppFonts.mono,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGreenLight,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            item.marche,
            style: const TextStyle(
              fontFamily: AppFonts.sans,
              fontSize: 11,
              color: Color(0xFF8DB5A0),
            ),
          ),
        ],
      ),
    );
  }
}

class _TickerItem {
  const _TickerItem({
    required this.produit,
    required this.unite,
    required this.marche,
    required this.prix,
  });

  final String produit;
  final String unite;
  final String marche;
  final double prix;
}
