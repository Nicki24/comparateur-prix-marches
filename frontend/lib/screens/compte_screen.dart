import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/session.dart';
import '../theme/app_theme.dart';
import '../utils/formats.dart';
import '../widgets/compteur_anime.dart';
import '../widgets/fond_auth.dart';
import '../widgets/logo.dart';
import 'login_screen.dart';
import 'profil_screen.dart';
import 'register_screen.dart';

class CompteScreen extends StatelessWidget {
  const CompteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const MarqueHeader(titre: 'Mon compte'),
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

/// Vue d'invitation pour les visiteurs non connectés : hero en dégradé
/// avec marque, CTA et statistiques publiques de la plateforme.
class _DeconnecteView extends StatefulWidget {
  const _DeconnecteView();

  @override
  State<_DeconnecteView> createState() => _DeconnecteViewState();
}

class _DeconnecteViewState extends State<_DeconnecteView> {
  int _versionStats = 0;

  Future<void> _recharger() async {
    setState(() => _versionStats++);
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.green,
      onRefresh: _recharger,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          _HeroInvitation(),
          const SizedBox(height: 20),
          _BlocStatsPublic(cle: _versionStats),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Pilier(
                  icone: Icons.remove_red_eye_outlined,
                  titre: 'Consultation libre',
                  detail: 'Comparez les prix sans créer de compte.',
                  couleur: AppColors.green,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Pilier(
                  icone: Icons.handshake_outlined,
                  titre: 'Avec vous',
                  detail: 'Chaque relevé provient d\'un contributeur local.',
                  couleur: AppColors.saffron,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Pilier(
                  icone: Icons.insights_rounded,
                  titre: 'Évolutif',
                  detail: 'Historiques et alertes de prix anormaux.',
                  couleur: AppColors.terracotta,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Hero d'invitation : marque, tagline et actions de connexion.
class _HeroInvitation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.ink, AppColors.ink2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -50,
            child: HaloAuth(couleur: AppColors.greenLight, taille: 190),
          ),
          Positioned(
            bottom: -70,
            left: -50,
            child: HaloAuth(couleur: AppColors.saffron, taille: 170),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
            child: Column(
              children: [
                const MarqueComplete(
                  tailleLogo: 72,
                  couleurTexte: surEncre,
                  couleurSousTitre: attenueEncre,
                  sousTitre: 'Comparez · Suivez · Comprenez\nles prix des marchés locaux',
                ),
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text('Se connecter'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const RegisterScreen(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: surEncre,
                      side: BorderSide(color: surEncre.withValues(alpha: 0.6)),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text('Créer un compte'),
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

/// Statistiques publiques de la plateforme (endpoint public `/stats`).
class _BlocStatsPublic extends StatelessWidget {
  const _BlocStatsPublic({this.cle = 0});

  /// Invalide le FutureBuilder pour recharger les stats (pull-to-refresh).
  final int cle;

  static const _stats = [
    (cle: 'nb_releves', label: 'Relevés', icone: Icons.insights_rounded, couleur: AppColors.green),
    (cle: 'nb_marches_actifs', label: 'Marchés actifs', icone: Icons.storefront_rounded, couleur: AppColors.saffron),
    (cle: 'nb_produits_actifs', label: 'Produits suivis', icone: Icons.shopping_basket_rounded, couleur: AppColors.terracotta),
    (cle: 'nb_contributeurs', label: 'Contributeurs', icone: Icons.group_rounded, couleur: AppColors.ink),
  ];

  /// Charge les stats publiques en silence (aucune erreur remontée).
  static Future<Map<String, dynamic>?> _chargerStats() async {
    try {
      final data = await ApiClient.instance.get('/stats');
      return data is Map<String, dynamic> ? data : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FutureBuilder<Map<String, dynamic>?>(
          key: ValueKey('stats-$cle'),
          future: _chargerStats(),
          builder: (context, snapshot) {
            final data = snapshot.data;
            final attente = snapshot.connectionState != ConnectionState.done;
            final derniereMaj = data?['derniere_mise_a_jour'] is String
                ? DateTime.tryParse(data!['derniere_mise_a_jour'] as String)
                : null;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Row(
                    children: [
                      Text(
                        'LA PLATEFORME EN CHIFFRES',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontFamily: AppFonts.mono,
                          color: theme.colorScheme.onSurfaceVariant,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (derniereMaj != null)
                        Text(
                          'MàJ ${formaterHeure(derniereMaj)}'
                          ' · ${formaterDateCourte(derniereMaj)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontFamily: AppFonts.mono,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                            fontSize: 10.5,
                            letterSpacing: 0.4,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark
                        ? AppColors.darkSurface
                        : AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.brightness == Brightness.dark
                          ? AppColors.darkLine
                          : AppColors.line,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (var i = 0; i < _stats.length; i++)
                        Expanded(
                          child: _StatTile(
                            icone: _stats[i].icone,
                            couleur: _stats[i].couleur,
                            valeur: data != null
                                ? (data[_stats[i].cle] as num?)
                                : null,
                            placeholder: attente ? '…' : '—',
                            label: _stats[i].label,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Tuile de statistique unique avec compteur animé.
class _StatTile extends StatelessWidget {
  const _StatTile({
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
          maxLines: 2,
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

/// Pillier de valeur (consultation libre, contribution locale, suivi).
class _Pilier extends StatelessWidget {
  const _Pilier({
    required this.icone,
    required this.titre,
    required this.detail,
    required this.couleur,
  });

  final IconData icone;
  final String titre;
  final String detail;
  final Color couleur;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? AppColors.darkSurface
            : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? AppColors.darkLine
              : AppColors.line,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 22, color: couleur),
          const SizedBox(height: 8),
          Text(
            titre,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            detail,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}