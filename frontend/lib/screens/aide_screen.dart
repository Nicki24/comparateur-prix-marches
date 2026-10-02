import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/fond_auth.dart';
import '../widgets/marketscope_header.dart';
import '../widgets/ms_anim.dart';
import '../widgets/ms_card.dart';
import '../widgets/ms_decor.dart';
import '../widgets/statut_badge.dart';
import 'onboarding_screen.dart';

typedef _Question = ({String question, String reponse});

const List<_Question> _faq = [
  (
    question: 'Faut-il un compte pour consulter les prix ?',
    reponse:
        'Non. Marchés, produits, comparaisons et historiques sont en accès '
        'libre. Un compte est seulement nécessaire pour saisir des relevés.',
  ),
  (
    question: 'D’où viennent les prix affichés ?',
    reponse:
        'Chaque prix est relevé sur place par un contributeur, au marché. '
        'La comparaison utilise le dernier relevé connu dans chaque marché.',
  ),
  (
    question: 'Comment trouver le marché le moins cher ?',
    reponse:
        'Onglet Produits → choisissez un produit. L’écran Comparaison classe '
        'les marchés du moins cher au plus cher et signale la meilleure '
        'affaire.',
  ),
  (
    question: 'Pourquoi un relevé est-il « Signalé » ?',
    reponse:
        'Un prix qui s’écarte de plus de 40 % de la moyenne des 14 derniers '
        'jours pour le même produit est signalé automatiquement, puis '
        'vérifié par un administrateur.',
  ),
  (
    question: 'Que veut dire « Obsolète » ?',
    reponse:
        'Le relevé date de plus de 14 jours : il reste visible dans '
        'l’historique, mais il n’est plus représentatif du prix actuel.',
  ),
  (
    question: 'Comment ajouter un prix ?',
    reponse:
        'Connectez-vous, ouvrez l’onglet Relevés puis touchez « Nouveau ». '
        'Choisissez le produit, le marché, indiquez le prix et envoyez.',
  ),
  (
    question: 'Mes données sont-elles à jour ?',
    reponse:
        'Tirez l’écran vers le bas pour actualiser. Le bandeau en haut '
        'défile en continu avec les derniers prix relevés.',
  ),
  (
    question: 'Comment passer en mode sombre ?',
    reponse:
        'Touchez le soleil (ou la lune) en haut à droite. Dans Profil → '
        'Préférences, vous pouvez aussi suivre le réglage du téléphone.',
  ),
];

/// Centre d'aide : visite guidée, premiers pas, lecture des badges, FAQ.
///
/// Ouvert depuis le bouton « ? » du header, sur tous les onglets.
class AideScreen extends StatefulWidget {
  const AideScreen({super.key});

  @override
  State<AideScreen> createState() => _AideScreenState();
}

class _AideScreenState extends State<AideScreen> {
  final _recherche = TextEditingController();
  String _filtre = '';

  @override
  void dispose() {
    _recherche.dispose();
    super.dispose();
  }

  static String _normaliser(String s) {
    const accents = {
      'à': 'a', 'â': 'a', 'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
      'î': 'i', 'ï': 'i', 'ô': 'o', 'ù': 'u', 'û': 'u', 'ç': 'c',
    };
    final bas = s.toLowerCase();
    return bas.split('').map((c) => accents[c] ?? c).join();
  }

  List<_Question> get _questionsFiltrees {
    if (_filtre.isEmpty) return _faq;
    final f = _normaliser(_filtre);
    return _faq
        .where((q) =>
            _normaliser(q.question).contains(f) ||
            _normaliser(q.reponse).contains(f))
        .toList();
  }

  void _revoirVisite() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (ctx) => OnboardingScreen(
          onTermine: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enRecherche = _filtre.isNotEmpty;
    final questions = _questionsFiltrees;

    return Scaffold(
      appBar: const MarketScopeHeader(
        titre: 'Aide',
        sousTitre: 'Guide et questions fréquentes',
      ),
      body: MsDecorFond(
        densite: 0.6,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            MsApparition(child: _HeroAide(onRevoirVisite: _revoirVisite)),
            const SizedBox(height: AppSpacing.md),
            MsApparition(
              delai: const Duration(milliseconds: 60),
              child: TextField(
                controller: _recherche,
                onChanged: (v) => setState(() => _filtre = v.trim()),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Rechercher une question…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: enRecherche
                      ? IconButton(
                          tooltip: 'Effacer',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _recherche.clear();
                            setState(() => _filtre = '');
                          },
                        )
                      : null,
                ),
              ),
            ),
            if (!enRecherche) ...[
              const SizedBox(height: AppSpacing.lg),
              const MarketScopeSectionTitle(
                titre: 'Premiers pas',
                icone: Icons.flag_outlined,
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: AppSpacing.sm),
              const _PremiersPas(),
              const SizedBox(height: AppSpacing.lg),
              const MarketScopeSectionTitle(
                titre: 'Lire les badges',
                icone: Icons.sell_outlined,
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: AppSpacing.sm),
              const _LegendeBadges(),
            ],
            const SizedBox(height: AppSpacing.lg),
            MarketScopeSectionTitle(
              titre: enRecherche
                  ? '${questions.length} résultat${questions.length > 1 ? 's' : ''}'
                  : 'Questions fréquentes',
              icone: Icons.forum_outlined,
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (questions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Text(
                  'Aucune question ne correspond à « $_filtre ».',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              for (var i = 0; i < questions.length; i++)
                MsCascade(
                  key: ValueKey(questions[i].question),
                  index: i,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _CarteQuestion(
                      question: questions[i],
                      ouverte: enRecherche && questions.length <= 2,
                    ),
                  ),
                ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _HeroAide extends StatelessWidget {
  const _HeroAide({required this.onRevoirVisite});

  final VoidCallback onRevoirVisite;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.ink, AppColors.ink2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: -60,
            right: -40,
            child: HaloAuth(couleur: AppColors.greenLight, taille: 180),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nouveau sur MarketScope ?',
                        style: AppTextStyles.headlineSmall.copyWith(
                          color: surEncre,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Faites le tour de l’application en 30 secondes.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: attenueEncre,
                        ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: onRevoirVisite,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.green,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, size: 20),
                        label: const Text('Visite guidée'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.greenLight.withValues(alpha: 0.15),
                    border: Border.all(
                      color: AppColors.greenLight.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline_rounded,
                    color: AppColors.greenLight,
                    size: 30,
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

/// Parcours en 4 étapes, reliées par une ligne verticale (frise).
class _PremiersPas extends StatelessWidget {
  const _PremiersPas();

  static const _etapes = [
    (
      icone: Icons.storefront_rounded,
      titre: 'Explorez les marchés',
      detail: 'Onglet Marchés : liste, recherche par nom ou par ville.',
    ),
    (
      icone: Icons.compare_arrows_rounded,
      titre: 'Comparez un produit',
      detail: 'Onglet Produits → un produit : prix par marché, du moins cher '
          'au plus cher.',
    ),
    (
      icone: Icons.show_chart_rounded,
      titre: 'Regardez l’historique',
      detail: 'Dans la comparaison, l’onglet Historique trace l’évolution '
          'du prix.',
    ),
    (
      icone: Icons.add_chart_rounded,
      titre: 'Contribuez',
      detail: 'Créez un compte, puis Relevés → Nouveau pour partager un prix.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MarketScopeCard(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 4),
      child: Column(
        children: [
          for (var i = 0; i < _etapes.length; i++)
            MsCascade(
              index: i,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.marque.withValues(alpha: 0.12),
                            border: Border.all(
                              color: theme.marque.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: stylePrix(
                                taille: 14,
                                couleur: theme.marque,
                                poids: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        if (i < _etapes.length - 1)
                          Expanded(
                            child: Container(
                              width: 2,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              color: theme.marque.withValues(alpha: 0.25),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6, bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _etapes[i].icone,
                                  size: 16,
                                  color: theme.marque,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _etapes[i].titre,
                                    style: theme.textTheme.titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _etapes[i].detail,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LegendeBadges extends StatelessWidget {
  const _LegendeBadges();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget ligne(Widget badge, String texte) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 92, child: Align(
                alignment: Alignment.centerLeft,
                child: badge,
              )),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(texte, style: theme.textTheme.bodySmall),
                ),
              ),
            ],
          ),
        );

    return MarketScopeCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Column(
        children: [
          ligne(
            const StatutBadge.ok('Validé'),
            'Prix cohérent avec les autres relevés récents.',
          ),
          Divider(color: theme.ligne),
          ligne(
            const StatutBadge.alerte('Signalé'),
            'Écart de plus de 40 % avec la moyenne des 14 derniers jours.',
          ),
          Divider(color: theme.ligne),
          ligne(
            const StatutBadge.obsolete('Obsolète'),
            'Relevé de plus de 14 jours : à prendre avec prudence.',
          ),
        ],
      ),
    );
  }
}

class _CarteQuestion extends StatelessWidget {
  const _CarteQuestion({required this.question, this.ouverte = false});

  final _Question question;
  final bool ouverte;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MarketScopeCard(
      padding: EdgeInsets.zero,
      sansOmbre: true,
      child: Theme(
        // Retire les traits ajoutés par défaut autour de l'ExpansionTile.
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: ouverte,
          shape: const RoundedRectangleBorder(),
          collapsedShape: const RoundedRectangleBorder(),
          iconColor: theme.marque,
          collapsedIconColor: theme.colorScheme.onSurfaceVariant,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          title: Text(
            question.question,
            style: theme.textTheme.titleSmall,
          ),
          children: [
            Text(
              question.reponse,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
