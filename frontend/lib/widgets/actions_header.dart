import 'package:flutter/material.dart';

import '../screens/aide_screen.dart';
import '../services/preferences_app.dart';
import '../theme/app_theme.dart';

/// Bascule clair ↔ sombre depuis le header : le soleil et la lune
/// pivotent l'un dans l'autre. Le réglage « système » reste dans Profil.
class BoutonTheme extends StatelessWidget {
  const BoutonTheme({super.key});

  @override
  Widget build(BuildContext context) {
    final sombre = Theme.of(context).brightness == Brightness.dark;
    final reduit = MediaQuery.disableAnimationsOf(context);
    return IconButton(
      tooltip: sombre ? 'Passer en mode clair' : 'Passer en mode sombre',
      onPressed: () => PreferencesApp.instance
          .basculerTheme(Theme.of(context).brightness),
      icon: AnimatedSwitcher(
        duration: Duration(milliseconds: reduit ? 0 : 450),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => RotationTransition(
          turns: Tween<double>(begin: -0.35, end: 0).animate(animation),
          child: ScaleTransition(
            scale: animation,
            child: FadeTransition(opacity: animation, child: child),
          ),
        ),
        child: sombre
            ? const Icon(
                Icons.dark_mode_rounded,
                key: ValueKey('lune'),
                color: AppColors.darkSaffron,
              )
            : const Icon(
                Icons.light_mode_rounded,
                key: ValueKey('soleil'),
                color: AppColors.saffron,
              ),
      ),
    );
  }
}

/// Ouvre le centre d'aide. Tant que l'aide n'a jamais été ouverte,
/// un point vert pulse sur l'icône pour attirer l'œil des nouveaux.
class BoutonAide extends StatefulWidget {
  const BoutonAide({super.key});

  /// Partagé entre les onglets : le point disparaît partout à la fois.
  static final ValueNotifier<bool> _aideOuverte = ValueNotifier(false);

  @override
  State<BoutonAide> createState() => _BoutonAideState();
}

class _BoutonAideState extends State<BoutonAide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduit = MediaQuery.disableAnimationsOf(context);
    if (reduit || BoutonAide._aideOuverte.value) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _ouvrir() {
    BoutonAide._aideOuverte.value = true;
    _pulse.stop();
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AideScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Aide et guide',
      onPressed: _ouvrir,
      icon: ValueListenableBuilder<bool>(
        valueListenable: BoutonAide._aideOuverte,
        builder: (context, ouverte, icone) {
          if (ouverte) return icone!;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              icone!,
              Positioned(
                top: -1,
                right: -1,
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, _) {
                    final t = _pulse.value;
                    return SizedBox(
                      width: 9,
                      height: 9,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          // Onde qui s'élargit et s'efface.
                          Transform.scale(
                            scale: 1 + t * 1.6,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.greenLight.withValues(
                                  alpha: 0.5 * (1 - t),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.greenLight,
                              border: Border.all(
                                color: AppColors.ink,
                                width: 1.5,
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
        },
        child: const Icon(Icons.help_outline_rounded),
      ),
    );
  }
}
