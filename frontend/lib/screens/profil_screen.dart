import 'package:flutter/material.dart';

import '../models/releve_prix.dart';
import '../services/releve_service.dart';
import '../services/session.dart';
import '../theme/app_theme.dart';
import '../utils/formats.dart';
import '../widgets/compteur_anime.dart';
import '../widgets/logo.dart';
import '../widgets/ms_anim.dart';
import '../widgets/ms_card.dart';
import '../widgets/ms_decor.dart';
import 'admin_gestion_screen.dart';
import 'mes_releves_screen.dart';
import 'saisie_releve_screen.dart';
import 'signalements_screen.dart';

/// Vue de l'utilisateur connecté : profil + actions selon le rôle.
class ProfilScreen extends StatefulWidget {
  const ProfilScreen(
      {super.key, this.onThemeModeChanged, this.currentThemeMode});

  final void Function(ThemeMode)? onThemeModeChanged;
  final ThemeMode? currentThemeMode;

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

    return MsDecorFond(
      densite: 0.7,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const SizedBox(height: 8),
          MsApparition(
            child: MarketScopeCard(
              child: Row(
                children: [
                  const LogoMarque(taille: 64, ombre: true),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontFamily: AppFonts.display,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme
                                .colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (estAdmin
                                    ? AppColors.saffron
                                    : theme.colorScheme.primary)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(
                                AppRadius.pill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                estAdmin
                                    ? Icons.admin_panel_settings_rounded
                                    : Icons.eco_rounded,
                                size: 13,
                                color: estAdmin
                                    ? AppColors.saffron
                                    : theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                estAdmin
                                    ? 'Administrateur'
                                    : 'Contributeur actif',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: estAdmin
                                      ? AppColors.saffron
                                      : theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const MsApparition(
            delai: Duration(milliseconds: 60),
            child: _StatsContributeur(),
          ),
          const SizedBox(height: AppSpacing.lg),
          MsApparition(
            delai: const Duration(milliseconds: 120),
            child: MarketScopeSectionTitle(
              titre: 'Contributions',
              icone: Icons.receipt_long_rounded,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          MsCascade(
            index: 1,
            child: _ActionTile(
              icone: Icons.add_chart_rounded,
              titre: 'Saisir un relevé de prix',
              sousTitre:
                  'Quel produit ? Dans quel marché ? À quel prix ?',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const SaisieReleveScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          MsCascade(
            index: 2,
            child: _ActionTile(
              icone: Icons.history_rounded,
              titre: 'Mes relevés',
              sousTitre: 'Produit · marché · prix · date · statut',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const MesRelevesScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const MsApparition(
            child: MarketScopeSectionTitle(
              titre: 'Préférences',
              icone: Icons.settings_outlined,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          MsApparition(
            child: MarketScopeCard(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: 6),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Theme.of(context).brightness ==
                                  Brightness.dark
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          size: 19,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Apparence',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14),
                            ),
                            Text(
                              'Mode clair / sombre',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: Icon(Icons.light_mode_rounded,
                                size: 16),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: Icon(Icons.dark_mode_rounded,
                                size: 16),
                          ),
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: Icon(Icons.settings_suggest_rounded,
                                size: 16),
                          ),
                        ],
                        selected: {
                          widget.currentThemeMode ?? ThemeMode.system
                        },
                        showSelectedIcon: false,
                        style: SegmentedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        onSelectionChanged: (s) =>
                            widget.onThemeModeChanged
                                ?.call(s.first),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (estAdmin) ...[
            const SizedBox(height: AppSpacing.lg),
            const MarketScopeSectionTitle(
              titre: 'Administration',
              icone: Icons.admin_panel_settings_outlined,
            ),
            const SizedBox(height: AppSpacing.sm),
            MsCascade(
              index: 3,
              child: _ActionTile(
                icone: Icons.report_problem_outlined,
                titre: 'Relevés signalés',
                sousTitre:
                    'Prix anormaux · prix obsolètes · écarts',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) =>
                            const SignalementsScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            MsCascade(
              index: 4,
              child: _ActionTile(
                icone: Icons.storefront_outlined,
                titre: 'Gestion des marchés',
                sousTitre: 'Créer · modifier · désactiver',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AdminGestionScreen(
                          type: AdminGestionType.marches),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            MsCascade(
              index: 5,
              child: _ActionTile(
                icone: Icons.category_outlined,
                titre: 'Gestion des produits',
                sousTitre: 'Créer · modifier · désactiver',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AdminGestionScreen(
                          type: AdminGestionType.produits),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: _enDeconnexion ? null : _deconnecter,
            icon: _enDeconnexion
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child:
                        CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Se déconnecter'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(48, 50),
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(
                  color: theme.colorScheme.error
                      .withValues(alpha: 0.4)),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
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
class _StatsContributeur extends StatefulWidget {
  const _StatsContributeur();

  @override
  State<_StatsContributeur> createState() => _StatsContributeurState();
}

class _StatsContributeurState extends State<_StatsContributeur> {
  // Chargé une fois (et non à chaque reconstruction du profil).
  late final _futur = ReleveService.mesRelevesAvecTotal();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<({List<RelevePrix> releves, int total})>(
      future: _futur,
      builder: (context, snapshot) {
        final releves = snapshot.data?.releves ?? const <RelevePrix>[];
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
                    valeur: snapshot.hasData ? snapshot.data!.total : null,
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
                _JalonContributeur(nbReleves: snapshot.data!.total),
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