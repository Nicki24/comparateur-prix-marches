import 'package:flutter/material.dart';

import '../models/marche.dart';
import '../models/produit.dart';
import '../models/releve_prix.dart';
import '../services/marche_service.dart';
import '../services/produit_service.dart';
import '../services/releve_service.dart';
import '../utils/formats.dart';
import '../widgets/etats.dart';

/// Formulaire de saisie d'un relevé de prix (contributeur).
class SaisieReleveScreen extends StatefulWidget {
  const SaisieReleveScreen({super.key});

  @override
  State<SaisieReleveScreen> createState() => _SaisieReleveScreenState();
}

class _SaisieReleveScreenState extends State<SaisieReleveScreen> {
  final _formulaire = GlobalKey<FormState>();
  final _prixController = TextEditingController();
  final _commentaireController = TextEditingController();

  late Future<List<Produit>> _futurProduits;
  late Future<List<Marche>> _futurMarches;

  Produit? _produitChoisi;
  Marche? _marcheChoisi;
  DateTime _date = DateTime.now();

  bool _enChargement = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _futurProduits = ProduitService.lister();
    _futurMarches = MarcheService.lister();
  }

  @override
  void dispose() {
    _prixController.dispose();
    _commentaireController.dispose();
    super.dispose();
  }

  Future<void> _choisirDate() async {
    final choix = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      helpText: 'Date du relevé',
    );
    if (choix != null) {
      setState(() => _date = choix);
    }
  }

  Future<void> _soumettre() async {
    if (!(_formulaire.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _enChargement = true;
      _erreur = null;
    });

    try {
      final releve = await ReleveService.creer(
        produitId: _produitChoisi!.id,
        marcheId: _marcheChoisi!.id,
        valeur: double.parse(_prixController.text.trim().replaceAll(',', '.')),
        dateReleve: _date,
        commentaire: _commentaireController.text.trim().isEmpty
            ? null
            : _commentaireController.text.trim(),
      );

      if (!mounted) {
        return;
      }
      await _confirmerEnvoi(releve);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _erreur = e.toString().replaceFirst('ApiException: ', '');
        _enChargement = false;
      });
    }
  }

  Future<void> _confirmerEnvoi(RelevePrix releve) async {
    final message = releve.estSignale
        ? 'Relevé enregistré, mais un prix anormal a été détecté. '
            'Il sera vérifié par un administrateur.'
        : 'Relevé de ${formaterPrix(releve.valeur)} enregistré. '
            'Merci pour votre contribution !';

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          releve.estSignale ? Icons.warning : Icons.check_circle,
          color: releve.estSignale ? Colors.orange : Colors.green,
        ),
        title: Text(releve.estSignale ? 'Prix signalé' : 'Relevé enregistré'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Saisir un relevé')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Un relevé par produit, marché et jour'),
                subtitle: const Text(
                  'Vous pouvez soumettre au maximum un prix par produit, '
                  'par marché et par jour.',
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Form(
            key: _formulaire,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ChampProduit(
                  futurProduits: _futurProduits,
                  produit: _produitChoisi,
                  onChanged: (p) => setState(() => _produitChoisi = p),
                ),
                const SizedBox(height: 16),
                _ChampMarche(
                  futurMarches: _futurMarches,
                  marche: _marcheChoisi,
                  onChanged: (m) => setState(() => _marcheChoisi = m),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _prixController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Prix observé (Ariary)',
                    hintText: 'Ex. 3200',
                    prefixIcon: const Icon(Icons.payments_outlined),
                    border: const OutlineInputBorder(),
                    suffixText: _produitChoisi?.uniteMesure,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Veuillez saisir le prix.';
                    }
                    final prix = double.tryParse(v.trim().replaceAll(',', '.'));
                    if (prix == null || prix <= 0) {
                      return 'Le prix doit être supérieur à 0.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event),
                  title: const Text('Date du relevé'),
                  subtitle: Text(formaterDate(_date)),
                  trailing: TextButton(
                    onPressed: _choisirDate,
                    child: const Text('Modifier'),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _commentaireController,
                  decoration: const InputDecoration(
                    labelText: 'Commentaire (facultatif)',
                    hintText: 'État du produit, précisions…',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                if (_erreur != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _erreur!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _enChargement ? null : _soumettre,
                  icon: _enChargement
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Envoyer le relevé'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChampProduit extends StatelessWidget {
  const _ChampProduit({
    required this.futurProduits,
    required this.produit,
    required this.onChanged,
  });

  final Future<List<Produit>> futurProduits;
  final Produit? produit;
  final ValueChanged<Produit?> onChanged;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Produit>>(
      future: futurProduits,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LinearProgressIndicator();
        }
        if (snapshot.hasError || (snapshot.data ?? []).isEmpty) {
          return const ContenuVide(
            message: 'Aucun produit disponible.',
            icone: Icons.category,
          );
        }
        final produits = snapshot.data!;
        return DropdownButtonFormField<Produit>(
          value: produit,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Produit',
            prefixIcon: Icon(Icons.category_outlined),
            border: OutlineInputBorder(),
          ),
          items: [
            for (final p in produits)
              DropdownMenuItem(value: p, child: Text(p.nom)),
          ],
          onChanged: onChanged,
          validator: (v) => v == null ? 'Choisissez un produit.' : null,
        );
      },
    );
  }
}

class _ChampMarche extends StatelessWidget {
  const _ChampMarche({
    required this.futurMarches,
    required this.marche,
    required this.onChanged,
  });

  final Future<List<Marche>> futurMarches;
  final Marche? marche;
  final ValueChanged<Marche?> onChanged;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Marche>>(
      future: futurMarches,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LinearProgressIndicator();
        }
        if (snapshot.hasError || (snapshot.data ?? []).isEmpty) {
          return const ContenuVide(
            message: 'Aucun marché disponible.',
            icone: Icons.storefront,
          );
        }
        final marches = snapshot.data!;
        return DropdownButtonFormField<Marche>(
          value: marche,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Marché',
            prefixIcon: Icon(Icons.storefront_outlined),
            border: OutlineInputBorder(),
          ),
          items: [
            for (final m in marches)
              DropdownMenuItem(value: m, child: Text(m.nom)),
          ],
          onChanged: onChanged,
          validator: (v) => v == null ? 'Choisissez un marché.' : null,
        );
      },
    );
  }
}