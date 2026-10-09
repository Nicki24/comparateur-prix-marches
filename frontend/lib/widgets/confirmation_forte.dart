import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_theme.dart';

/// Élément proposé comme destination d'une fusion.
class CibleFusion {
  const CibleFusion({required this.id, required this.nom, this.detail});

  final int id;
  final String nom;
  final String? detail;
}

/// Dialogue de suppression définitive : l'admin doit retaper le nom de
/// l'élément avant que le bouton « Supprimer » ne s'active.
///
/// Renvoie `true` si la suppression est confirmée.
class SuppressionDefinitiveDialog extends StatefulWidget {
  const SuppressionDefinitiveDialog({
    super.key,
    required this.article,
    required this.nom,
  });

  /// « le marché » ou « le produit ».
  final String article;
  final String nom;

  static Future<bool> afficher(
    BuildContext context, {
    required String article,
    required String nom,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => SuppressionDefinitiveDialog(article: article, nom: nom),
    );
    return ok ?? false;
  }

  @override
  State<SuppressionDefinitiveDialog> createState() =>
      _SuppressionDefinitiveDialogState();
}

class _SuppressionDefinitiveDialogState
    extends State<SuppressionDefinitiveDialog> {
  bool _nomConfirme = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(
        PhosphorIconsRegular.trash,
        color: Theme.of(context).colorScheme.error,
      ),
      title: const Text('Supprimer définitivement ?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Supprimer ${widget.article} « ${widget.nom} » ? '
              'Cette action est irréversible. Elle n’est possible que si '
              'aucun relevé de prix n’y est rattaché.',
            ),
            const SizedBox(height: AppSpacing.md),
            ChampRetaperNom(
              nom: widget.nom,
              onChanged: (ok) => setState(() => _nomConfirme = ok),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        _BoutonDestructif(
          libelle: 'Supprimer',
          onPressed: _nomConfirme
              ? () => Navigator.of(context).pop(true)
              : null,
        ),
      ],
    );
  }
}

/// Dialogue de fusion : choix de l'élément conservé, puis nom du doublon
/// à retaper. Renvoie l'identifiant de la cible, ou `null` si annulé.
class FusionDialog extends StatefulWidget {
  const FusionDialog({
    super.key,
    required this.article,
    required this.nom,
    required this.cibles,
  });

  /// « le marché » ou « le produit ».
  final String article;

  /// Nom du doublon qui sera supprimé.
  final String nom;
  final List<CibleFusion> cibles;

  static Future<int?> afficher(
    BuildContext context, {
    required String article,
    required String nom,
    required List<CibleFusion> cibles,
  }) {
    return showDialog<int>(
      context: context,
      builder: (_) => FusionDialog(article: article, nom: nom, cibles: cibles),
    );
  }

  @override
  State<FusionDialog> createState() => _FusionDialogState();
}

class _FusionDialogState extends State<FusionDialog> {
  int? _cibleId;
  bool _nomConfirme = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pret = _cibleId != null && _nomConfirme;

    return AlertDialog(
      icon: Icon(
        PhosphorIconsRegular.gitMerge,
        color: theme.colorScheme.primary,
      ),
      title: const Text('Fusionner un doublon'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tous les relevés de « ${widget.nom} » seront déplacés vers '
              '${widget.article} choisi ci-dessous, puis « ${widget.nom} » '
              'sera supprimé. L’historique des prix est conservé.',
            ),
            const SizedBox(height: AppSpacing.md),
            if (widget.cibles.isEmpty)
              Text(
                'Aucun autre élément disponible pour la fusion.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              DropdownButtonFormField<int>(
                value: _cibleId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Élément à conserver',
                ),
                items: [
                  for (final c in widget.cibles)
                    DropdownMenuItem(
                      value: c.id,
                      child: Text(
                        c.detail == null ? c.nom : '${c.nom} · ${c.detail}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (v) => setState(() => _cibleId = v),
              ),
            const SizedBox(height: AppSpacing.md),
            ChampRetaperNom(
              nom: widget.nom,
              onChanged: (ok) => setState(() => _nomConfirme = ok),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        _BoutonDestructif(
          libelle: 'Fusionner',
          onPressed: pret ? () => Navigator.of(context).pop(_cibleId) : null,
        ),
      ],
    );
  }
}

/// Champ « retapez le nom pour confirmer ». Signale à chaque frappe si le
/// texte saisi correspond exactement au nom (espaces de bord ignorés).
class ChampRetaperNom extends StatefulWidget {
  const ChampRetaperNom({
    super.key,
    required this.nom,
    required this.onChanged,
  });

  final String nom;
  final ValueChanged<bool> onChanged;

  @override
  State<ChampRetaperNom> createState() => _ChampRetaperNomState();
}

class _ChampRetaperNomState extends State<ChampRetaperNom> {
  final _controleur = TextEditingController();

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controleur,
      autocorrect: false,
      enableSuggestions: false,
      decoration: InputDecoration(
        labelText: 'Retapez « ${widget.nom} » pour confirmer',
        hintText: widget.nom,
      ),
      onChanged: (texte) => widget.onChanged(texte.trim() == widget.nom.trim()),
    );
  }
}

/// Bouton plein aux couleurs d'erreur. En thème sombre, le terracotta clair
/// impose un texte foncé pour garder un contraste AA (≥ 4,5:1).
class _BoutonDestructif extends StatelessWidget {
  const _BoutonDestructif({required this.libelle, required this.onPressed});

  final String libelle;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sombre = theme.brightness == Brightness.dark;
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: theme.colorScheme.error,
        foregroundColor: sombre ? AppColors.ink : AppColors.white,
      ),
      child: Text(libelle),
    );
  }
}
