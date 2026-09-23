import 'package:flutter/material.dart';

import '../services/session.dart';
import '../theme/app_theme.dart';
import '../widgets/prix_ticker_banner.dart';
import 'compte_screen.dart';
import 'dashboard_accueil.dart';
import 'marches_screen.dart';
import 'mes_releves_screen.dart';
import 'produits_screen.dart';
import 'saisie_releve_screen.dart';

/// Navigation principale à 5 onglets :
/// Accueil · Marchés · Produits · Relevés · Profil.
///
/// L'onglet actif est identifiable (icône pleine + indicateur vert).
/// Comparaison / Historique restent accessibles depuis Marchés / Produits.
/// L'administration reste accessible depuis Profil pour les admins.
class AccueilScreen extends StatefulWidget {
  const AccueilScreen(
      {super.key, this.onThemeModeChanged, this.currentThemeMode});

  final void Function(ThemeMode)? onThemeModeChanged;
  final ThemeMode? currentThemeMode;

  @override
  State<AccueilScreen> createState() => _AccueilScreenState();
}

class _AccueilScreenState extends State<AccueilScreen> {
  int _index = 0;

  void _allerA(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final ecrans = [
      DashboardAccueil(
        onVoirMarches: () => _allerA(1),
        onVoirProduits: () => _allerA(2),
      ),
      const MarchesScreen(),
      const ProduitsScreen(),
      const _OngletReleves(),
      CompteScreen(
        onThemeModeChanged: widget.onThemeModeChanged,
        currentThemeMode: widget.currentThemeMode,
      ),
    ];

    return Scaffold(
      body: Column(
        children: [
          const SafeArea(bottom: false, child: PrixTickerBanner()),
          Expanded(
            child: IndexedStack(index: _index, children: ecrans),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _allerA,
        backgroundColor: theme.brightness == Brightness.dark
            ? AppColors.darkSurface
            : AppColors.white,
        indicatorColor: (theme.brightness == Brightness.dark
                ? AppColors.darkGreenLight
                : AppColors.green)
            .withValues(alpha: 0.16),
        height: 70,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Accueil',
            tooltip: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Marchés',
            tooltip: 'Marchés',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_basket_outlined),
            selectedIcon: Icon(Icons.shopping_basket),
            label: 'Produits',
            tooltip: 'Produits',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Relevés',
            tooltip: 'Mes relevés',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
            tooltip: 'Profil',
          ),
        ],
      ),
      floatingActionButton: _index == 3 && Session.instance.estConnecte
          ? FloatingActionButton.extended(
              heroTag: 'new-releve',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const SaisieReleveScreen()),
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nouveau'),
            )
          : null,
    );
  }
}

/// Onglet Relevés : liste personnelle si connecté, sinon invitation.
class _OngletReleves extends StatelessWidget {
  const _OngletReleves();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Session.instance,
      builder: (context, _) {
        if (Session.instance.estConnecte) {
          return const MesRelevesScreen();
        }
        return const _InvitationReleves();
      },
    );
  }
}

class _InvitationReleves extends StatelessWidget {
  const _InvitationReleves();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Mes relevés')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary
                      .withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  size: 36,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Suivez vos contributions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Connectez-vous pour voir vos relevés, leur statut et votre progression.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Retrouvez l’onglet « Profil » ci-dessous pour vous connecter.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
