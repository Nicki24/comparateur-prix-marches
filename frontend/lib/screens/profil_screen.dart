import 'package:flutter/material.dart';

import '../services/session.dart';
import 'admin_gestion_screen.dart';
import 'mes_releves_screen.dart';
import 'saisie_releve_screen.dart';
import 'signalements_screen.dart';

/// Vue de l'utilisateur connecté : profil + actions selon le rôle.
class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  bool _enDeconnexion = false;

  Future<void> _deconnecter() async {
    setState(() => _enDeconnexion = true);
    await Session.instance.deconnecter();
    if (!mounted) {
      return;
    }
    setState(() => _enDeconnexion = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = Session.instance.user!;
    final estAdmin = Session.instance.user!.estAdmin;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 16),
        Center(
          child: CircleAvatar(
            radius: 40,
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: theme.textTheme.headlineMedium,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            user.name,
            style: theme.textTheme.titleLarge,
          ),
        ),
        Center(
          child: Text(
            user.email,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Chip(
            avatar: Icon(
              estAdmin ? Icons.admin_panel_settings : Icons.person,
              size: 18,
            ),
            label: Text(estAdmin ? 'Administrateur' : 'Contributeur'),
          ),
        ),
        const SizedBox(height: 24),
        if (estAdmin) ...[
          _ActionTile(
            icone: Icons.report_problem_outlined,
            titre: 'Signalements',
            sousTitre: 'Anomalies de prix détectées',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SignalementsScreen()),
              );
            },
          ),
          _ActionTile(
            icone: Icons.storefront_outlined,
            titre: 'Gestion des marchés',
            sousTitre: 'Créer et désactiver des marchés',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AdminGestionScreen(type: AdminGestionType.marches),
                ),
              );
            },
          ),
          _ActionTile(
            icone: Icons.category_outlined,
            titre: 'Gestion des produits',
            sousTitre: 'Créer et désactiver des produits',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AdminGestionScreen(type: AdminGestionType.produits),
                ),
              );
            },
          ),
        ] else ...[
          _ActionTile(
            icone: Icons.add_chart,
            titre: 'Saisir un relevé de prix',
            sousTitre: 'Partagez les prix observés sur un marché',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SaisieReleveScreen()),
              );
            },
          ),
          _ActionTile(
            icone: Icons.history,
            titre: 'Mes relevés',
            sousTitre: 'Consulter l’historique de vos relevés',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const MesRelevesScreen()),
              );
            },
          ),
        ],
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: _enDeconnexion ? null : _deconnecter,
          icon: _enDeconnexion
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.logout),
          label: const Text('Se déconnecter'),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icone,
    required this.titre,
    required this.sousTitre,
    required this.onTap,
  });

  final IconData icone;
  final String titre;
  final String sousTitre;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icone),
        title: Text(titre),
        subtitle: Text(sousTitre),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}