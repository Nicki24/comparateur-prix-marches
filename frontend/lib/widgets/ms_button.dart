import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_theme.dart';

/// Bouton principal MarketScope : vert, texte contrasté, radius pilule,
/// hauteur confortable (48 dp min), états default / pressed / disabled / loading.
///
/// Léger feedback d'échelle au toucher, sans animation excessive.
class MarketScopeButton extends StatefulWidget {
  const MarketScopeButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icone,
    this.enChargement = false,
    this.estSecondaire = false,
    this.estDanger = false,
    this.largeurMax = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icone;
  final bool enChargement;
  final bool estSecondaire;
  final bool estDanger;
  final bool largeurMax;

  @override
  State<MarketScopeButton> createState() => _MarketScopeButtonState();
}

class _MarketScopeButtonState extends State<MarketScopeButton> {
  bool _enfonce = false;

  bool get _desactive => widget.onPressed == null || widget.enChargement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color fond;
    Color texte;
    BorderSide? bord;
    if (widget.estDanger) {
      fond = theme.colorScheme.error;
      texte = theme.colorScheme.onError;
      bord = null;
    } else if (widget.estSecondaire) {
      fond = Colors.transparent;
      texte = theme.colorScheme.onSurface;
      bord = BorderSide(color: theme.dividerColor);
    } else {
      fond = isDark ? AppColors.darkGreenLight : AppColors.green;
      texte = isDark ? AppColors.darkPaper : AppColors.white;
      bord = null;
    }

    final contenu = AnimatedScale(
      scale: _enfonce && !_desactive ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Listener(
        onPointerDown: (_) => setState(() => _enfonce = true),
        onPointerUp: (_) => setState(() => _enfonce = false),
        onPointerCancel: (_) => setState(() => _enfonce = false),
        child: AnimatedOpacity(
          opacity: _desactive && !widget.enChargement ? 0.5 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Container(
            constraints: const BoxConstraints(minHeight: 50),
            decoration: BoxDecoration(
              color: _desactive && !widget.enChargement
                  ? fond.withValues(alpha: 0.55)
                  : fond,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: bord != null ? Border.fromBorderSide(bord) : null,
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            child: Center(
              child: widget.enChargement
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: texte,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icone != null) ...[
                          Icon(widget.icone, size: 18, color: texte),
                          const SizedBox(width: 10),
                        ],
                        Flexible(
                          child: Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppFonts.sans,
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                              color: texte,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );

    final bouton = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: _desactive ? null : widget.onPressed,
        child: contenu,
      ),
    );

    if (widget.largeurMax) {
      return SizedBox(width: double.infinity, child: bouton);
    }
    return bouton;
  }
}

/// Bouton d'erreur inline (formulaires auth) : fond alerte, icône, message.
class MarketScopeErrorBanner extends StatelessWidget {
  const MarketScopeErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.alertBg,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: theme.alertFg.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(PhosphorIconsRegular.warningCircle,
              size: 20, color: theme.alertFg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: theme.alertFg,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
