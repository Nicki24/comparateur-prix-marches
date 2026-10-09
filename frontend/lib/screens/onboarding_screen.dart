import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_theme.dart';
import '../utils/formats.dart';
import '../widgets/fond_auth.dart';
import '../widgets/marketscope_header.dart';
import '../utils/mise_en_page.dart';

/// Une page de la visite guidée.
class _EtapeVisite {
  const _EtapeVisite({
    required this.icone,
    required this.couleur,
    required this.titre,
    required this.texte,
    required this.etiquettes,
  });

  final IconData icone;
  final Color couleur;
  final String titre;
  final String texte;

  /// Pastilles flottantes autour de l'illustration.
  final List<String> etiquettes;
}

final _etapes = [
  _EtapeVisite(
    icone: PhosphorIconsRegular.storefront,
    couleur: AppColors.greenLight,
    titre: 'Bienvenue sur MarketScope',
    texte:
        'Les prix des marchés locaux, relevés sur place par des '
        'contributeurs. Consultation libre, sans compte.',
    etiquettes: ['Marchés', 'Produits', 'Prix réels'],
  ),
  _EtapeVisite(
    icone: PhosphorIconsRegular.arrowsLeftRight,
    couleur: AppColors.saffron,
    titre: 'Comparez en un coup d’œil',
    texte:
        'Choisissez un produit : MarketScope classe les marchés du '
        'moins cher au plus cher et met en avant la meilleure affaire.',
    etiquettes: [formaterPrix(2800), formaterPrix(3150), formaterPrix(3400)],
  ),
  _EtapeVisite(
    icone: PhosphorIconsRegular.chartLine,
    couleur: Color(0xFF5DB4E8),
    titre: 'Suivez l’évolution',
    texte:
        'L’historique montre comment un prix bouge semaine après '
        'semaine : idéal pour acheter au bon moment.',
    etiquettes: [formaterPourcentage(-4.2), formaterPourcentage(1.8), '30 j'],
  ),
  _EtapeVisite(
    icone: PhosphorIconsRegular.notePencil,
    couleur: AppColors.terracotta,
    titre: 'Contribuez à votre tour',
    texte:
        'Créez un compte pour saisir les prix que vous voyez au marché. '
        'Les prix anormaux ou trop anciens sont signalés automatiquement.',
    etiquettes: ['Validé', 'Signalé', 'Obsolète'],
  ),
];

/// Visite guidée affichée au premier lancement, et rejouable depuis l'aide.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onTermine});

  /// Appelé quand l'utilisateur termine ou passe la visite.
  final VoidCallback onTermine;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _controleur = PageController();

  /// Flottement continu des illustrations.
  late final AnimationController _flottement = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  int _page = 0;

  bool get _derniere => _page == _etapes.length - 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _flottement.stop();
    } else if (!_flottement.isAnimating) {
      _flottement.repeat();
    }
  }

  @override
  void dispose() {
    _controleur.dispose();
    _flottement.dispose();
    super.dispose();
  }

  void _suivant() {
    if (_derniere) {
      widget.onTermine();
      return;
    }
    _controleur.nextPage(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final couleur = _etapes[_page].couleur;
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Stack(
        children: [
          const Positioned.fill(child: FondEncre()),
          // Halo qui prend la couleur de l'étape courante.
          AnimatedPositioned(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            top: 60,
            left: _page.isEven ? -120 : null,
            right: _page.isOdd ? -120 : null,
            child: TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: couleur),
              duration: const Duration(milliseconds: 600),
              builder: (context, c, _) =>
                  HaloAuth(couleur: c ?? couleur, taille: 380),
            ),
          ),
          SafeArea(
            // Sur grand écran, la visite reste au format d'un téléphone
            // au lieu de s'étirer (bouton et textes sur toute la largeur).
            child: ContenuCentre(
              largeurMax: 600,
              child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
                  child: Row(
                    children: [
                      const MarketScopeBadge(taille: 28),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: MarketScopeWordmark(taille: 18),
                        ),
                      ),
                      AnimatedOpacity(
                        opacity: _derniere ? 0 : 1,
                        duration: const Duration(milliseconds: 200),
                        child: TextButton(
                          onPressed: _derniere ? null : widget.onTermine,
                          style: TextButton.styleFrom(
                            foregroundColor: attenueEncre,
                          ),
                          child: const Text('Passer'),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controleur,
                    itemCount: _etapes.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, i) => AnimatedBuilder(
                      animation: _controleur,
                      builder: (context, _) {
                        // Distance signée de la page à l'écran (-1 … 1).
                        final position = _controleur.hasClients &&
                                _controleur.position.haveDimensions
                            ? _controleur.page! - i
                            : (i - _page).toDouble() * -1;
                        return _PageVisite(
                          etape: _etapes[i],
                          decalage: position.clamp(-1.0, 1.0),
                          flottement: _flottement,
                        );
                      },
                    ),
                  ),
                ),
                _Indicateur(total: _etapes.length, actif: _page),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _suivant,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Row(
                          key: ValueKey(_derniere),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_derniere ? 'C’est parti !' : 'Suivant'),
                            const SizedBox(width: 8),
                            Icon(
                              _derniere
                                  ? PhosphorIconsRegular.rocketLaunch
                                  : PhosphorIconsRegular.arrowRight,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Contenu d'une étape, avec parallaxe : l'illustration glisse plus
/// vite que le texte quand on fait défiler.
class _PageVisite extends StatelessWidget {
  const _PageVisite({
    required this.etape,
    required this.decalage,
    required this.flottement,
  });

  final _EtapeVisite etape;
  final double decalage;
  final Animation<double> flottement;

  @override
  Widget build(BuildContext context) {
    final largeur = MediaQuery.sizeOf(context).width;
    final visibilite = 1 - decalage.abs();
    return LayoutBuilder(
      builder: (context, contraintes) {
        // Sur petit écran, l'illustration rétrécit plutôt que déborder.
        final hauteurIllus = math.min(
          _Illustration._taille,
          contraintes.maxHeight * 0.5,
        );
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: contraintes.maxHeight),
            child: _contenu(largeur, visibilite, hauteurIllus),
          ),
        );
      },
    );
  }

  Widget _contenu(double largeur, double visibilite, double hauteurIllus) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.translate(
            offset: Offset(decalage * largeur * 0.35, 0),
            child: Opacity(
              opacity: visibilite.clamp(0.0, 1.0),
              child: SizedBox(
                height: hauteurIllus,
                child: FittedBox(
                  child: _Illustration(etape: etape, flottement: flottement),
                ),
              ),
            ),
          ),
          SizedBox(height: hauteurIllus < 180 ? 20 : 40),
          Transform.translate(
            offset: Offset(decalage * largeur * 0.12, 0),
            child: Opacity(
              opacity: visibilite.clamp(0.0, 1.0),
              child: Column(
                children: [
                  Text(
                    etape.titre,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.displaySmall.copyWith(
                      color: surEncre,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    etape.texte,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: attenueEncre,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Grand médaillon coloré + pastilles qui flottent en orbite.
class _Illustration extends StatelessWidget {
  const _Illustration({required this.etape, required this.flottement});

  final _EtapeVisite etape;
  final Animation<double> flottement;

  static const _taille = 230.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _taille,
      height: _taille,
      child: AnimatedBuilder(
        animation: flottement,
        builder: (context, _) {
          final t = flottement.value * 2 * math.pi;
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Anneau pointillé qui tourne lentement.
              Transform.rotate(
                angle: t / 4,
                child: CustomPaint(
                  size: const Size.square(_taille),
                  painter: _AnneauPointille(etape.couleur),
                ),
              ),
              // Médaillon principal, respiration légère.
              Transform.translate(
                offset: Offset(0, math.sin(t) * 5),
                child: Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        etape.couleur,
                        Color.lerp(etape.couleur, AppColors.ink, 0.45)!,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: etape.couleur.withValues(alpha: 0.45),
                        blurRadius: 40,
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: Icon(etape.icone, size: 56, color: Colors.white),
                ),
              ),
              for (var i = 0; i < etape.etiquettes.length; i++)
                _pastille(i, t),
            ],
          );
        },
      ),
    );
  }

  Widget _pastille(int i, double t) {
    // Trois positions fixes autour du médaillon, chacune avec sa phase.
    const ancres = [
      Alignment(-1.05, -0.62),
      Alignment(1.08, -0.15),
      Alignment(-0.55, 1.0),
    ];
    final phase = t + i * 2.1;
    return Align(
      alignment: ancres[i % ancres.length],
      child: Transform.translate(
        offset: Offset(math.cos(phase) * 4, math.sin(phase) * 7),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.ink2.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: etape.couleur.withValues(alpha: 0.5)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            etape.etiquettes[i],
            style: AppTextStyles.labelSmall.copyWith(
              color: surEncre,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

class _AnneauPointille extends CustomPainter {
  _AnneauPointille(this.couleur);

  final Color couleur;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final rayon = size.width / 2 - 14;
    final pinceau = Paint()..color = couleur.withValues(alpha: 0.35);
    const points = 36;
    for (var i = 0; i < points; i++) {
      final a = i * 2 * math.pi / points;
      canvas.drawCircle(
        centre + Offset(math.cos(a), math.sin(a)) * rayon,
        i.isEven ? 2.2 : 1.2,
        pinceau,
      );
    }
  }

  @override
  bool shouldRepaint(_AnneauPointille old) => old.couleur != couleur;
}

/// Points de pagination : le point actif s'étire en pilule.
class _Indicateur extends StatelessWidget {
  const _Indicateur({required this.total, required this.actif});

  final int total;
  final int actif;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Étape ${actif + 1} sur $total',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < total; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == actif ? 26 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == actif
                    ? AppColors.greenLight
                    : surEncre.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
        ],
      ),
    );
  }
}
