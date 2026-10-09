import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../services/localisation_service.dart';
import '../theme/app_theme.dart';
import '../widgets/marketscope_header.dart';

/// Carte OpenStreetMap d'un marché.
///
/// * Mode choix (admin) : toucher la carte pose l'épingle ; « Valider »
///   renvoie un [ChoixPosition] via `Navigator.pop`.
/// * Mode [lectureSeule] : affiche simplement l'emplacement du marché.
///
/// OpenStreetMap ne demande ni clé d'API ni facturation, contrairement à
/// Google Maps : rien de secret n'est embarqué dans l'application.
class CarteMarcheScreen extends StatefulWidget {
  const CarteMarcheScreen({
    super.key,
    this.initiale,
    this.nomMarche,
    this.lectureSeule = false,
  });

  final LatLng? initiale;
  final String? nomMarche;
  final bool lectureSeule;

  @override
  State<CarteMarcheScreen> createState() => _CarteMarcheScreenState();
}

class _CarteMarcheScreenState extends State<CarteMarcheScreen> {
  final _carte = MapController();
  LatLng? _point;
  bool _recherchePosition = false;

  static const _zoomInitial = 16.0;

  @override
  void initState() {
    super.initState();
    _point = widget.initiale;
  }

  @override
  void dispose() {
    _carte.dispose();
    super.dispose();
  }

  void _zoomer(double delta) {
    final camera = _carte.camera;
    _carte.move(camera.center, (camera.zoom + delta).clamp(3, 19));
  }

  Future<void> _allerAMaPosition() async {
    setState(() => _recherchePosition = true);
    try {
      final ici = await LocalisationService.positionActuelle();
      if (!mounted) return;
      _carte.move(ici, 17);
      // Pratique sur le terrain : l'admin debout dans le marché le place
      // en un geste.
      if (!widget.lectureSeule) setState(() => _point = ici);
    } on LocalisationException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _recherchePosition = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titre = widget.lectureSeule
        ? (widget.nomMarche ?? 'Emplacement du marché')
        : 'Placer le marché';

    return Scaffold(
      appBar: MarketScopeHeader(
        titre: titre,
        sousTitre: widget.lectureSeule
            ? null
            : 'Touchez la carte à l’endroit du marché',
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _carte,
            options: MapOptions(
              initialCenter: _point ?? LocalisationService.centreParDefaut,
              initialZoom: _point != null ? _zoomInitial : 13,
              onTap: widget.lectureSeule
                  ? null
                  : (_, point) => setState(() => _point = point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.comparateur.comparateur_prix_app',
              ),
              if (_point != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _point!,
                      width: 48,
                      height: 48,
                      // La pointe de l'épingle (en bas) touche le point.
                      alignment: Alignment.topCenter,
                      child: Semantics(
                        label: 'Emplacement du marché',
                        child: Icon(
                          PhosphorIconsFill.mapPin,
                          size: 48,
                          color: theme.colorScheme.primary,
                          shadows: const [
                            Shadow(blurRadius: 6, color: Colors.black38),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              const RichAttributionWidget(
                alignment: AttributionAlignment.bottomLeft,
                attributions: [
                  TextSourceAttribution('Contributeurs OpenStreetMap'),
                ],
              ),
            ],
          ),
          // Boutons de zoom : alternative au pincement / glissement
          // (WCAG 2.5.7) et utilisables au clavier sur le web.
          Positioned(
            right: AppSpacing.md,
            top: AppSpacing.md,
            child: Column(
              children: [
                _BoutonCarte(
                  icone: PhosphorIconsRegular.plus,
                  libelle: 'Zoomer',
                  onPressed: () => _zoomer(1),
                ),
                const SizedBox(height: 8),
                _BoutonCarte(
                  icone: PhosphorIconsRegular.minus,
                  libelle: 'Dézoomer',
                  onPressed: () => _zoomer(-1),
                ),
                const SizedBox(height: 8),
                _BoutonCarte(
                  icone: PhosphorIconsRegular.crosshair,
                  libelle: widget.lectureSeule
                      ? 'Centrer sur ma position'
                      : 'Placer à ma position actuelle',
                  enCours: _recherchePosition,
                  onPressed: _recherchePosition ? null : _allerAMaPosition,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.lectureSeule
          ? null
          : _PanneauValidation(
              point: _point,
              onRetirer: widget.initiale != null || _point != null
                  ? () => Navigator.of(context).pop(const ChoixPosition(null))
                  : null,
              onValider: _point == null
                  ? null
                  : () => Navigator.of(context).pop(ChoixPosition(_point)),
            ),
    );
  }
}

/// Résultat du choix sur la carte. `Navigator.pop` renvoie `null` si
/// l'admin annule, `ChoixPosition(null)` s'il retire l'épingle.
class ChoixPosition {
  const ChoixPosition(this.point);

  final LatLng? point;
}

class _BoutonCarte extends StatelessWidget {
  const _BoutonCarte({
    required this.icone,
    required this.libelle,
    required this.onPressed,
    this.enCours = false,
  });

  final IconData icone;
  final String libelle;
  final VoidCallback? onPressed;
  final bool enCours;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      shape: const CircleBorder(),
      elevation: 3,
      child: IconButton(
        tooltip: libelle,
        onPressed: onPressed,
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        icon: enCours
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icone, color: theme.colorScheme.onSurface),
      ),
    );
  }
}

class _PanneauValidation extends StatelessWidget {
  const _PanneauValidation({
    required this.point,
    required this.onValider,
    required this.onRetirer,
  });

  final LatLng? point;
  final VoidCallback? onValider;
  final VoidCallback? onRetirer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                liveRegion: true,
                child: Text(
                  point == null
                      ? 'Aucun emplacement choisi.'
                      : 'Position : ${formaterCoordonnees(point!)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  if (onRetirer != null) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onRetirer,
                        child: const Text('Retirer la position'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: FilledButton(
                      onPressed: onValider,
                      child: const Text('Valider l’emplacement'),
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

/// « -23.35160, 43.68550 » : 5 décimales ≈ 1 m, assez pour un marché.
String formaterCoordonnees(LatLng point) =>
    '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
