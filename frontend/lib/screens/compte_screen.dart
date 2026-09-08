import 'package:flutter/material.dart';

import '../services/session.dart';
import 'login_screen.dart';
import 'profil_screen.dart';
import 'register_screen.dart';

class CompteScreen extends StatelessWidget {
  const CompteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon compte'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: ListenableBuilder(
        listenable: Session.instance,
        builder: (context, _) {
          if (Session.instance.estConnecte) {
            return const ProfilScreen();
          }
          return const _DeconnecteView();
        },
      ),
    );
  }
}

/// Vue pour les visiteurs non connectés.
class _DeconnecteView extends StatelessWidget {
  const _DeconnecteView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        Icon(
          Icons.account_circle,
          size: 72,
          color: theme.colorScheme.primary.withValues(alpha: 0.7),
        ),
        const SizedBox(height: 16),
        Text(
          'Contribuez aux relevés de prix',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Créez un compte pour saisir les prix observés sur les marchés '
          'de Toliara. La consultation reste libre et gratuite.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
            );
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Se connecter'),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const RegisterScreen()),
            );
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Créer un compte'),
          ),
        ),
      ],
    );
  }
}