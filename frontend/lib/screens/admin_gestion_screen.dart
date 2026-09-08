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
      await _dialogAjoutMarche();
    } else {
      await _dialogAjoutProduit();
    }
  }

  Future<void> _desactiver(dynamic element) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Désactiver'),
        content: Text(
          _estMarches
              ? 'Désactiver le marché « ${(element as Marche).nom} » ?'
              : 'Désactiver le produit « ${(element as Produit).nom} » ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Désactiver'),
          ),
        ],
      ),
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

  Future<void> _dialogAjoutMarche() async {
    final nomController = TextEditingController();
    final localisationController = TextEditingController();
    final descriptionController = TextEditingController();
    final formulaire = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouveau marché'),
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
            child: const Text('Créer'),
          ),
        ],
      ),
    );

    if (ok != true) {
      return;
    }
    try {
      await MarcheService.creer(
        nom: nomController.text.trim(),
        localisation: localisationController.text.trim(),
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marché créé.')),
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

  Future<void> _dialogAjoutProduit() async {
    final nomController = TextEditingController();
    final uniteController = TextEditingController();
    final categorieController = TextEditingController();
    final formulaire = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouveau produit'),
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
            child: const Text('Créer'),
          ),
        ],
      ),
    );

    if (ok != true) {
      return;
    }
    try {
      await ProduitService.creer(
        nom: nomController.text.trim(),
        uniteMesure: uniteController.text.trim(),
        categorie: categorieController.text.trim().isEmpty
            ? null
            : categorieController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produit créé.')),
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
                    ),
                    title: Text(nom),
                    subtitle: Text(sousTitre),
                    trailing: actif
                        ? TextButton(
                            onPressed: () => _desactiver(element),
                            child: const Text(
                              'Désactiver',
                              style: TextStyle(color: Colors.red),
                            ),
                          )
                        : const Chip(
                            label: Text('Inactif'),
                            backgroundColor: Colors.grey,
                            labelStyle: TextStyle(color: Colors.white),
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