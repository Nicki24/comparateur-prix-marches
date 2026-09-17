import 'package:flutter/material.dart';

import '../models/marche.dart';
import '../models/produit.dart';
import '../services/marche_service.dart';
import '../services/produit_service.dart';
import '../widgets/etats.dart';

enum AdminGestionType { marches, produits }

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Élément désactivé.')),
      );
      await _recharger();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Élément réactivé.')),
      );
      await _recharger();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))),
      );
    }
  }

  Future<void> _dialogMarche({Marche? existant}) async {
    final estModification = existant != null;
    final nomController = TextEditingController(text: existant?.nom);
    final localisationController =
        TextEditingController(text: existant?.localisation);
    final descriptionController =
        TextEditingController(text: existant?.description);
    final formulaire = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(estModification ? 'Modifier le marché' : 'Nouveau marché'),
        content: Form(
          key: formulaire,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nomController,
                decoration: const InputDecoration(labelText: 'Nom du marché'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nom requis.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: localisationController,
                decoration: const InputDecoration(labelText: 'Localisation'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Localisation requise.'
                    : null,
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
    final localisation = localisationController.text.trim();
    final description = descriptionController.text.trim().isEmpty
        ? null
        : descriptionController.text.trim();

    try {
      if (estModification) {
        await MarcheService.modifier(
          id: existant.id,
          nom: nom,
          localisation: localisation,
          description: description,
        );
      } else {
        await MarcheService.creer(
          nom: nom,
          localisation: localisation,
          description: description,
        );
      }
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(estModification ? 'Marché modifié.' : 'Marché créé.')),
      );
      await _recharger();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))),
      );
    }
  }

  Future<void> _dialogProduit({Produit? existant}) async {
    final estModification = existant != null;
    final nomController = TextEditingController(text: existant?.nom);
    final uniteController = TextEditingController(text: existant?.uniteMesure);
    final categorieController = TextEditingController(text: existant?.categorie);
    final formulaire = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(estModification ? 'Modifier le produit' : 'Nouveau produit'),
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
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Unité requise.'
                    : null,
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
        SnackBar(content: Text(estModification ? 'Produit modifié.' : 'Produit créé.')),
      );
      await _recharger();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestion des ${_intitule().toLowerCase()}'),
        actions: [
          IconButton(
            tooltip: 'Ajouter un ${_estMarches ? 'marché' : 'produit'}',
            icon: const Icon(Icons.add),
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
            onRefresh: _recharger,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
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

                return Card(
                  child: ListTile(
                    leading: Icon(
                      _estMarches ? Icons.storefront : Icons.category,
                      color: actif ? null : Colors.grey,
                    ),
                    title: Text(nom),
                    subtitle: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          actif ? Icons.check_circle_outline : Icons.cancel_outlined,
                          size: 14,
                          color: actif ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          actif ? 'Actif' : 'Inactif',
                          style: TextStyle(
                            color: actif ? Colors.green : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            sousTitre,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Modifier',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _modifier(element),
                        ),
                        TextButton(
                          onPressed: () =>
                              actif ? _desactiver(element) : _reactiver(element),
                          style: TextButton.styleFrom(
                            foregroundColor: actif ? Colors.red : Colors.green,
                          ),
                          child: Text(actif ? 'Désactiver' : 'Réactiver'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}