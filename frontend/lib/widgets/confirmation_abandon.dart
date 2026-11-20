import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Alerte affichée quand un formulaire rempli est sur le point d'être fermé
/// sans enregistrement. Renvoie `true` seulement si l'utilisateur confirme
/// qu'il veut bien perdre sa saisie.
Future<bool> confirmerAbandonModifications(
  BuildContext context, {
  String titre = 'Modifications non enregistrées',
  String message =
      'Vous avez commencé à remplir ce formulaire. '
      'Voulez-vous vraiment l’abandonner ? Votre saisie sera perdue.',
}) async {
  final confirme = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: Icon(
        PhosphorIconsRegular.warningCircle,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(titre),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Continuer la saisie'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Abandonner'),
        ),
      ],
    ),
  );
  return confirme ?? false;
}
