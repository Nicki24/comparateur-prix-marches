import 'package:flutter/material.dart';

import '../models/releve_prix.dart';
import '../services/releve_service.dart';
import '../services/session.dart';
import '../theme/app_theme.dart';
import '../utils/formats.dart';
import '../widgets/compteur_anime.dart';
import '../widgets/logo.dart';
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
        const Center(child: LogoMarque(taille: 88, ombre: true)),
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
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
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
        const _StatsContributeur(),
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
    final theme = Theme.of(context);
    return Material(
      color: theme.brightness == Brightness.dark
          ? AppColors.darkSurface
          : AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.brightness == Brightness.dark
                  ? AppColors.darkLine
                  : AppColors.line,
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icone, color: AppColors.green, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titre,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sousTitre,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Statistiques de contribution de l'utilisateur connecté, issues de son
/// historique personnel : relevés soumis, produits et marchés distincts.
class _StatsContributeur extends StatelessWidget {
  const _StatsContributeur();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<RelevePrix>>(
      future: ReleveService.mesReleves(),
      builder: (context, snapshot) {
        final releves = snapshot.data ?? const <RelevePrix>[];
        final produits = releves
            .map((r) => r.produit?.id)
            .whereType<int>()
            .toSet()
            .length;
        final marches = releves
            .map((r) => r.marche?.id)
            .whereType<int>()
            .toSet()
            .length;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: theme.brightness == Brightness.dark
                  ? [AppColors.darkPaper2, AppColors.darkSurface]
                  : [AppColors.paper2, AppColors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.brightness == Brightness.dark
                  ? AppColors.darkLine
                  : AppColors.line,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _TuileStat(
                    icone: Icons.insights_rounded,
                    couleur: AppColors.green,
                    valeur: snapshot.hasData ? releves.length : null,
                    placeholder: '…',
                    label: 'Relevés soumis',
                  ),
                  _TuileStat(
                    icone: Icons.shopping_basket_rounded,
                    couleur: AppColors.saffron,
                    valeur: snapshot.hasData ? produits : null,
                    placeholder: '…',
                    label: 'Produits suivis',
                  ),
                  _TuileStat(
                    icone: Icons.storefront_rounded,
                    couleur: AppColors.terracotta,
                    valeur: snapshot.hasData ? marches : null,
                    placeholder: '…',
                    label: 'Marchés couverts',
                  ),
                ],
              ),
              if (snapshot.hasData) ...[
                const Divider(height: 24),
                _JalonContributeur(nbReleves: releves.length),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Palier de contribution : progression animée vers le prochain jalon.
class _JalonContributeur extends StatelessWidget {
  const _JalonContributeur({required this.nbReleves});

  final int nbReleves;

  static const _seuils = [5, 25, 100];

  String get _palierActuel {
    if (nbReleves >= 100) return 'Contributeur expert';
    if (nbReleves >= 25) return 'Contributeur régulier';
    if (nbReleves >= 5) return 'Contributeur actif';
    return 'Nouveau contributeur';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    int? prochain;
    for (final s in _seuils) {
      if (nbReleves < s) {
        prochain = s;
        break;
      }
    }

    final int palierProchain;
    if (prochain == null) {
      palierProchain = 100;
    } else if (prochain >= 100) {
      palierProchain = 100;
    } else if (prochain >= 25) {
      palierProchain = 25;
    } else {
      palierProchain = 5;
    }

    final String palierNom;
    switch (palierProchain) {
      case 100:
        palierNom = 'Contributeur expert';
      case 25:
        palierNom = 'Contributeur régulier';
      default:
        palierNom = 'Contributeur actif';
    }

    final progression = (nbReleves / palierProchain).clamp(0.0, 1.0);
    final restant = palierProchain - nbReleves;
    final message = prochain != null
        ? 'Plus que $restant relevé${restant > 1 ? 's' : ''} '
            'pour devenir « $palierNom ».'
        : 'Palier maximum atteint : merci pour votre engagement !';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.emoji_events_rounded,
              size: 18,
              color: AppColors.saffron,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _palierActuel,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '$nbReleves/$palierProchain',
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: AppFonts.mono,
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progression),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: 7,
              color: AppColors.green,
              backgroundColor:
                  isDark ? AppColors.darkPaper2 : AppColors.paper2,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

/// Tuile de statistique unique dans le profil (compteur animé).
class _TuileStat extends StatelessWidget {
  const _TuileStat({
    required this.icone,
    required this.couleur,
    required this.valeur,
    required this.label,
    this.placeholder = '—',
  });

  final IconData icone;
  final Color couleur;
  final num? valeur;
  final String label;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 20, color: couleur),
        const SizedBox(height: 6),
        if (valeur != null)
          CompteurAnime(
            valeur: valeur!,
            formater: formaterNombre,
            style: stylePrix(taille: 19, couleur: couleur),
          )
        else
          Text(placeholder, style: stylePrix(taille: 19, couleur: couleur)),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 10.5,
            height: 1.15,
          ),
        ),
      ],
    );
  }
}