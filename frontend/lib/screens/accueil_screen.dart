import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../services/session.dart';
import '../theme/app_theme.dart';
import '../utils/mise_en_page.dart';
import '../widgets/assistant_chat.dart';
import '../widgets/marketscope_header.dart';
import '../widgets/navigation_principale.dart';
import '../widgets/prix_ticker_banner.dart';
import 'compte_screen.dart';
import 'dashboard_accueil.dart';
import 'login_screen.dart';
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
  const AccueilScreen({super.key});

  @override
  State<AccueilScreen> createState() => _AccueilScreenState();
}

class _AccueilScreenState extends State<AccueilScreen> {
  int _index = 0;

  /// Onglets déjà ouverts : un onglet n'est construit (et ne charge ses
  /// données) qu'à sa première visite, puis reste en mémoire.
  final _visites = <int>{0};

  void _allerA(int index) => setState(() {
        _index = index;
        _visites.add(index);
      });

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
      const CompteScreen(),
    ];

    final bureau = MiseEnPage.estBureau(context);

    return NavigationPrincipale(
      index: _index,
      onSelection: _allerA,
      child: Scaffold(
      body: Column(
        children: [
          // Barre d'état + bandeau sur fond encre, continus avec le header.
          const ColoredBox(
            color: AppColors.ink,
            child: SafeArea(bottom: false, child: PrixTickerBanner()),
          ),
          Expanded(
            // Le padding haut est déjà consommé par le bandeau : sans ça,
            // chaque AppBar ajouterait une 2e fois la hauteur de la barre
            // d'état (double espace en haut sur téléphone).
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: IndexedStack(
                index: _index,
                children: [
                  for (var i = 0; i < ecrans.length; i++)
                    _visites.contains(i) ? ecrans[i] : const SizedBox.shrink(),
                ],
              ),
            ),
          ),
        ],
      ),
      // Desktop : les onglets sont dans le header (NavigationPrincipale).
      // Téléphone / tablette : barre du bas, dont les onglets restent
      // regroupés au centre sur une fenêtre intermédiaire.
      bottomNavigationBar: bureau
          ? null
          : DecoratedBox(
              decoration: BoxDecoration(
                color: theme.fondCarte,
                border: Border(top: BorderSide(color: theme.ligne)),
              ),
              child: ContenuCentre(
                largeurMax: MiseEnPage.largeurNavigation,
                child: NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: _allerA,
                  backgroundColor: theme.fondCarte,
                  // Pas de teinte d'élévation : même couleur que le fond
                  // pleine largeur.
                  surfaceTintColor: Colors.transparent,
                  indicatorColor: theme.marque.withValues(alpha: 0.14),
                  height: 66,
                  labelBehavior:
                      NavigationDestinationLabelBehavior.alwaysShow,
                  destinations: [
                    for (final d in destinationsPrincipales)
                      NavigationDestination(
                        icon: Icon(d.icone),
                        selectedIcon: Icon(d.iconeActive),
                        label: d.label,
                        tooltip: d.tooltip ?? d.label,
                      ),
                  ],
                ),
              ),
            ),
      // Bulle de l'assistant IA sur tous les onglets ; sur Relevés, elle
      // se place au-dessus du bouton « Nouveau ».
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const BulleAssistant(),
          if (_index == 3 && Session.instance.estConnecte) ...[
            const SizedBox(height: 12),
            FloatingActionButton.extended(
              heroTag: 'new-releve',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const SaisieReleveScreen()),
                );
              },
              icon: const Icon(PhosphorIconsRegular.plus),
              label: const Text('Nouveau'),
            ),
          ],
        ],
      ),
      ),
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
      appBar: const MarketScopeHeader(),
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
                  PhosphorIconsRegular.receipt,
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
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                ),
                icon: const Icon(PhosphorIconsRegular.signIn, size: 18),
                label: const Text('Se connecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
