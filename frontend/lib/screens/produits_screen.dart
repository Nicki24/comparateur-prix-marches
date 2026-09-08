import 'package:flutter/material.dart';

import '../models/produit.dart';
import '../services/produit_service.dart';
import '../widgets/etats.dart';
import 'comparaison_screen.dart';

class ProduitsScreen extends StatefulWidget {
  const ProduitsScreen({super.key});

  @override
  State<ProduitsScreen> createState() => _ProduitsScreenState();
}

class _ProduitsScreenState extends State<ProduitsScreen> {
  late Future<List<Produit>> _futur;

  @override
  void initState() {
    super.initState();
    _futur = ProduitService.lister();
  }

  Future<void> _recharger() async {
    setState(() {
      _futur = ProduitService.lister();
    });
    await _futur;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produits'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: FutureBuilder<List<Produit>>(
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

          final produits = snapshot.data ?? [];
          if (produits.isEmpty) {
            return const ContenuVide(
              message: 'Aucun produit disponible pour le moment.',
              icone: Icons.shopping_basket,
            );
          }

          return RefreshIndicator(
            onRefresh: _recharger,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: produits.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final produit = produits[index];
                final categorie = produit.categorie;
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Icon(
                        Icons.category,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    title: Text(produit.nom),
                    subtitle: Text(
                      categorie != null && categorie.isNotEmpty
                          ? '$categorie · ${produit.uniteMesure}'
                          : produit.uniteMesure,
                    ),
                    trailing: const Icon(Icons.bar_chart),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ComparaisonScreen(produit: produit),
                        ),
                      );
                    },
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