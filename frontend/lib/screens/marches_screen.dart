import 'package:flutter/material.dart';

import '../models/marche.dart';
import '../services/marche_service.dart';
import '../widgets/etats.dart';

class MarchesScreen extends StatefulWidget {
  const MarchesScreen({super.key});

  @override
  State<MarchesScreen> createState() => _MarchesScreenState();
}

class _MarchesScreenState extends State<MarchesScreen> {
  late Future<List<Marche>> _futur;

  @override
  void initState() {
    super.initState();
    _futur = MarcheService.lister();
  }

  Future<void> _recharger() async {
    setState(() {
      _futur = MarcheService.lister();
    });
    await _futur;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marchés'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: FutureBuilder<List<Marche>>(
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

          final marches = snapshot.data ?? [];
          if (marches.isEmpty) {
            return const ContenuVide(
              message: 'Aucun marché disponible pour le moment.',
              icone: Icons.storefront,
            );
          }

          return RefreshIndicator(
            onRefresh: _recharger,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: marches.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final marche = marches[index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Icon(Icons.storefront, color: Theme.of(context).colorScheme.primary),
                    ),
                    title: Text(marche.nom),
                    subtitle: Text(
                      marche.description ?? marche.localisation,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _ouvrirMarche(context, marche),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _ouvrirMarche(BuildContext context, Marche marche) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MarcheDetailScreen(marche: marche),
      ),
    );
  }
}

/// Fiche détaillée d'un marché.
class MarcheDetailScreen extends StatelessWidget {
  const MarcheDetailScreen({super.key, required this.marche});

  final Marche marche;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(marche.nom)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(marche.localisation)),
                    ],
                  ),
                  if (marche.description != null) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text(
                      marche.description!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.shopping_basket),
              title: const Text('Voir les prix des produits'),
              subtitle: const Text('Comparator les prix disponibles sur ce marché'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ProduitsMarchePlaceholder(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ProduitsMarchePlaceholder extends StatelessWidget {
  const ProduitsMarchePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Produits du marché')),
      body: const ContenuVide(
        message:
            'Sélectionnez un produit dans l’onglet « Produits » puis choisissez ce marché pour comparer les prix.',
        icone: Icons.shopping_basket,
      ),
    );
  }
}