import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../models/marche.dart';
import '../models/produit.dart';
import '../services/api_client.dart';
import '../services/marche_service.dart';
import '../services/produit_service.dart';
import '../theme/app_theme.dart';
import 'carte_marche_screen.dart';
import '../widgets/confirmation_forte.dart';
import '../widgets/etats.dart';
import '../widgets/marketscope_header.dart';
import '../widgets/ms_anim.dart';
import '../widgets/ms_card.dart';
import '../widgets/ms_decor.dart';
import '../widgets/statut_badge.dart';
import '../utils/mise_en_page.dart';

enum AdminGestionType { marches, produits }

enum _ActionAvancee { fusionner, supprimer }

class AdminGestionScreen extends StatefulWidget {
  const AdminGestionScreen({super.key, required this.type});

  final AdminGestionType type;

  @override
  State<AdminGestionScreen> createState() => _AdminGestionScreenState();
}

class _AdminGestionScreenState extends State<AdminGestionScreen> {
  late Future<dynamic> _futur;

  bool get _estMarches => widget.type == AdminGestionType.marches;

  @override
  void initState() {
    super.initState();
    _futur = _charger();
  }

  Future<dynamic> _charger() async {
    if (_estMarches) {
      return MarcheService.lister(tout: true);
    }
    return ProduitService.lister(tout: true);
  }

  Future<void> _recharger() async {
    setState(() {
      _futur = _charger();
    });
    await _futur;
  }

  String _intitule() => _estMarches ? 'Marchés' : 'Produits';

  Future<void> _creer() async {
    if (_estMarches) {
      await _dialogMarche();
    } else {
      await _dialogProduit();
    }
  }

  Future<void> _modifier(dynamic element) async {
    if (_estMarches) {
      await _dialogMarche(existant: element as Marche);
    } else {
      await _dialogProduit(existant: element as Produit);
    }
  }

  Future<bool?> _confirmer(String titre, String message, String action) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titre),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
  }

  Future<void> _desactiver(dynamic element) async {
    final nom = _estMarches
        ? (element as Marche).nom
        : (element as Produit).nom;
    final confirme = await _confirmer(
      'Désactiver',
      'Désactiver ${_estMarches ? 'le marché' : 'le produit'} « $nom » ? '
          'Il ne sera plus visible dans la consultation publique.',
      'Désactiver',
    );
    if (confirme != true) {
      return;
    }

    try {
      if (_estMarches) {
        await MarcheService.desactiver((element as Marche).id);
      } else {
        await ProduitService.desactiver((element as Produit).id);
      }
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Élément désactivé.')));
      await _recharger();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('ApiException: ', '')),
        ),
      );
    }
  }

  Future<void> _reactiver(dynamic element) async {
    final nom = _estMarches
        ? (element as Marche).nom
        : (element as Produit).nom;
    final confirme = await _confirmer(
      'Réactiver',
      'Réactiver ${_estMarches ? 'le marché' : 'le produit'} « $nom » ? '
          'Il redeviendra visible dans la consultation publique.',
      'Réactiver',
    );
    if (confirme != true) {
      return;
    }

    try {
      if (_estMarches) {
        await MarcheService.reactiver((element as Marche).id);
      } else {
        await ProduitService.reactiver((element as Produit).id);
      }
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Élément réactivé.')));
      await _recharger();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('ApiException: ', '')),
        ),
      );
    }
  }

  String _article() => _estMarches ? 'le marché' : 'le produit';

  int _idDe(dynamic element) =>
      _estMarches ? (element as Marche).id : (element as Produit).id;

  String _nomDe(dynamic element) =>
      _estMarches ? (element as Marche).nom : (element as Produit).nom;

  void _informer(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _supprimer(dynamic element, List<dynamic> elements) async {
    final nom = _nomDe(element);
    final confirme = await SuppressionDefinitiveDialog.afficher(
      context,
      article: _article(),
      nom: nom,
    );
    if (!confirme || !mounted) {
      return;
    }

    try {
      final message = _estMarches
          ? await MarcheService.supprimerDefinitivement(_idDe(element))
          : await ProduitService.supprimerDefinitivement(_idDe(element));
      if (!mounted) {
        return;
      }
      _informer(message);
      await _recharger();
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      if (e.statusCode == 409) {
        await _proposerAlternative(element, elements, e.message);
      } else {
        _informer(e.message);
      }
    }
  }

  /// Suppression refusée (historique présent) : on propose de désactiver
  /// ou de fusionner à la place.
  Future<void> _proposerAlternative(
    dynamic element,
    List<dynamic> elements,
    String message,
  ) async {
    final actif = _estMarches
        ? (element as Marche).actif
        : (element as Produit).actif;
    final choix = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suppression impossible'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('fusionner'),
            child: const Text('Fusionner…'),
          ),
          if (actif)
            FilledButton(
              onPressed: () => Navigator.of(context).pop('desactiver'),
              child: const Text('Désactiver'),
            ),
        ],
      ),
    );
    if (!mounted) {
      return;
    }
    if (choix == 'desactiver') {
      await _desactiver(element);
    } else if (choix == 'fusionner') {
      await _fusionner(element, elements);
    }
  }

  Future<void> _fusionner(dynamic element, List<dynamic> elements) async {
    final id = _idDe(element);
    final cibles = [
      for (final e in elements)
        if (_idDe(e) != id)
          _estMarches
              ? CibleFusion(
                  id: (e as Marche).id,
                  nom: e.nom,
                  detail: e.actif ? e.localisation : 'inactif',
                )
              : CibleFusion(
                  id: (e as Produit).id,
                  nom: e.nom,
                  detail: e.actif ? e.uniteMesure : 'inactif',
                ),
    ];
    final cibleId = await FusionDialog.afficher(
      context,
      article: _article(),
      nom: _nomDe(element),
      cibles: cibles,
    );
    if (cibleId == null || !mounted) {
      return;
    }

    try {
      final message = _estMarches
          ? await MarcheService.fusionner(id, cibleId: cibleId)
          : await ProduitService.fusionner(id, cibleId: cibleId);
      if (!mounted) {
        return;
      }
      _informer(message);
      await _recharger();
    } on ApiException catch (e) {
      if (mounted) {
        _informer(e.message);
      }
    }
  }

  Future<void> _dialogMarche({Marche? existant}) async {
    final estModification = existant != null;
    final nomController = TextEditingController(text: existant?.nom);
    final localisationController = TextEditingController(
      text: existant?.localisation,
    );
    final quartierController = TextEditingController(text: existant?.quartier);
    final descriptionController = TextEditingController(
      text: existant?.description,
    );
    final formulaire = GlobalKey<FormState>();
    LatLng? position = existant?.position;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            estModification ? 'Modifier le marché' : 'Nouveau marché',
          ),
          content: Form(
            key: formulaire,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nomController,
                    decoration: const InputDecoration(
                      labelText: 'Nom du marché',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Nom requis.' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: localisationController,
                    decoration: const InputDecoration(
                      labelText: 'Ville',
                      hintText: 'Ex. Toliara',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Ville requise.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: quartierController,
                    decoration: const InputDecoration(
                      labelText: 'Quartier (facultatif)',
                      hintText: 'Ex. Andranomena',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ChampPosition(
                    position: position,
                    onChoisir: () async {
                      final choix = await Navigator.of(context)
                          .push<ChoixPosition>(
                            MaterialPageRoute(
                              builder: (_) => CarteMarcheScreen(
                                initiale: position,
                                nomMarche: nomController.text.trim(),
                              ),
                            ),
                          );
                      if (choix != null) {
                        setDialogState(() => position = choix.point);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (facultatif)',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                if (formulaire.currentState?.validate() ?? false) {
                  Navigator.of(context).pop(true);
                }
              },
              child: Text(estModification ? 'Enregistrer' : 'Créer'),
            ),
          ],
        ),
      ),
    );

    if (ok != true) {
      return;
    }

    final nom = nomController.text.trim();
    final localisation = localisationController.text.trim();
    final quartier = quartierController.text.trim().isEmpty
        ? null
        : quartierController.text.trim();
    final description = descriptionController.text.trim().isEmpty
        ? null
        : descriptionController.text.trim();

    try {
      if (estModification) {
        await MarcheService.modifier(
          id: existant.id,
          nom: nom,
          localisation: localisation,
          quartier: quartier,
          position: position,
          description: description,
        );
      } else {
        await MarcheService.creer(
          nom: nom,
          localisation: localisation,
          quartier: quartier,
          position: position,
          description: description,
        );
      }
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(estModification ? 'Marché modifié.' : 'Marché créé.'),
        ),
      );
      await _recharger();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('ApiException: ', '')),
        ),
      );
    }
  }

  Future<void> _dialogProduit({Produit? existant}) async {
    final estModification = existant != null;
    final nomController = TextEditingController(text: existant?.nom);
    final uniteController = TextEditingController(text: existant?.uniteMesure);
    final categorieController = TextEditingController(
      text: existant?.categorie,
    );
    final formulaire = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          estModification ? 'Modifier le produit' : 'Nouveau produit',
        ),
        content: Form(
          key: formulaire,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nomController,
                decoration: const InputDecoration(labelText: 'Nom du produit'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nom requis.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: uniteController,
                decoration: const InputDecoration(
                  labelText: 'Unité de mesure',
                  hintText: 'kilo, litre, unité…',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Unité requise.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: categorieController,
                decoration: const InputDecoration(
                  labelText: 'Catégorie (facultatif)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (formulaire.currentState?.validate() ?? false) {
                Navigator.of(context).pop(true);
              }
            },
            child: Text(estModification ? 'Enregistrer' : 'Créer'),
          ),
        ],
      ),
    );

    if (ok != true) {
      return;
    }

    final nom = nomController.text.trim();
    final uniteMesure = uniteController.text.trim();
    final categorie = categorieController.text.trim().isEmpty
        ? null
        : categorieController.text.trim();

    try {
      if (estModification) {
        await ProduitService.modifier(
          id: existant.id,
          nom: nom,
          uniteMesure: uniteMesure,
          categorie: categorie,
        );
      } else {
        await ProduitService.creer(
          nom: nom,
          uniteMesure: uniteMesure,
          categorie: categorie,
        );
      }
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(estModification ? 'Produit modifié.' : 'Produit créé.'),
        ),
      );
      await _recharger();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('ApiException: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MarketScopeHeader(
        titre: 'Gestion des ${_intitule().toLowerCase()}',
        sousTitre: 'Administration',
        actions: [
          IconButton(
            tooltip: 'Ajouter un ${_estMarches ? 'marché' : 'produit'}',
            icon: const Icon(PhosphorIconsRegular.plus),
            onPressed: _creer,
          ),
        ],
      ),
      body: FutureBuilder<dynamic>(
        future: _futur,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Chargement();
          }
          if (snapshot.hasError) {
            return ErreurMessage(
              message: snapshot.error.toString(),
              onReessayer: _recharger,
            );
          }

          final elements = snapshot.data as List<dynamic>;
          if (elements.isEmpty) {
            return const ContenuVide(message: 'Aucun élément.');
          }

          return RefreshIndicator(
            color: Theme.of(context).marque,
            onRefresh: _recharger,
            child: MsDecorFond(
              densite: 0.5,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: MiseEnPage.padding(
                  context,
                  const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.xl,
                  ),
                ),
                itemCount: elements.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final element = elements[index];
                  final actif = _estMarches
                      ? (element as Marche).actif
                      : (element as Produit).actif;
                  final nom = _estMarches
                      ? (element as Marche).nom
                      : (element as Produit).nom;
                  final sousTitre = _estMarches
                      ? (element as Marche).localisation
                      : (element as Produit).uniteMesure;
                  final theme = Theme.of(context);

                  return MsCascade(
                    index: (index - 1) % 7,
                    child: MarketScopeCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color:
                                  (actif
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurfaceVariant)
                                      .withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _estMarches
                                  ? PhosphorIconsRegular.storefront
                                  : PhosphorIconsRegular.squaresFour,
                              size: 20,
                              color: actif
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nom,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                    color: actif
                                        ? null
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    actif
                                        ? const StatutBadge.ok('Actif')
                                        : const StatutBadge.neutre('Inactif'),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        sousTitre,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Modifier',
                            icon: const Icon(
                              PhosphorIconsRegular.pencilSimple,
                              size: 19,
                            ),
                            onPressed: () => _modifier(element),
                          ),
                          TextButton(
                            onPressed: () => actif
                                ? _desactiver(element)
                                : _reactiver(element),
                            style: TextButton.styleFrom(
                              foregroundColor: actif
                                  ? theme.colorScheme.error
                                  : AppColors.green,
                              visualDensity: VisualDensity.compact,
                            ),
                            child: Text(actif ? 'Désactiver' : 'Réactiver'),
                          ),
                          PopupMenuButton<_ActionAvancee>(
                            tooltip: 'Plus d’actions pour « $nom »',
                            icon: const Icon(
                              PhosphorIconsRegular.dotsThreeVertical,
                              size: 20,
                            ),
                            onSelected: (action) => switch (action) {
                              _ActionAvancee.fusionner => _fusionner(
                                element,
                                elements,
                              ),
                              _ActionAvancee.supprimer => _supprimer(
                                element,
                                elements,
                              ),
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: _ActionAvancee.fusionner,
                                child: ListTile(
                                  leading: Icon(PhosphorIconsRegular.gitMerge),
                                  title: Text('Fusionner avec…'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              PopupMenuItem(
                                value: _ActionAvancee.supprimer,
                                child: ListTile(
                                  leading: Icon(
                                    PhosphorIconsRegular.trash,
                                    color: theme.colorScheme.error,
                                  ),
                                  title: const Text(
                                    'Supprimer définitivement…',
                                  ),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Ligne « Emplacement sur la carte » du formulaire marché.
class _ChampPosition extends StatelessWidget {
  const _ChampPosition({required this.position, required this.onChoisir});

  final LatLng? position;
  final VoidCallback onChoisir;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final place = position != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              place ? PhosphorIconsFill.mapPin : PhosphorIconsRegular.mapPin,
              size: 20,
              color: place
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                place
                    ? 'Placé sur la carte (${formaterCoordonnees(position!)})'
                    : 'Pas encore placé sur la carte : il n’apparaîtra pas '
                          'dans les recherches « près de moi ».',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onChoisir,
          icon: const Icon(PhosphorIconsRegular.mapTrifold, size: 18),
          label: Text(place ? 'Modifier l’emplacement' : 'Placer sur la carte'),
        ),
      ],
    );
  }
}
