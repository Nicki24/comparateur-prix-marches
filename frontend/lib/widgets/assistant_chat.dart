import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../services/assistant_service.dart';
import '../theme/app_theme.dart';

/// Suggestion qui active d'abord le partage de position.
const _suggestionProximite = 'Le riz le moins cher près de moi ?';

/// Questions proposées quand la conversation est vide.
const _suggestions = [
  'Où acheter le riz le moins cher ?',
  _suggestionProximite,
  'Le prix de l’huile augmente-t-il ?',
  'Quels marchés à Toliara ?',
  'Comment ajouter un prix ?',
];

/// Bulle flottante de l'assistant IA : un halo « respire » autour
/// pour signaler qu'elle est interactive.
class BulleAssistant extends StatefulWidget {
  const BulleAssistant({super.key});

  @override
  State<BulleAssistant> createState() => _BulleAssistantState();
}

class _BulleAssistantState extends State<BulleAssistant>
    with SingleTickerProviderStateMixin {
  late final AnimationController _halo = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _halo.stop();
    } else if (!_halo.isAnimating) {
      _halo.repeat();
    }
  }

  @override
  void dispose() {
    _halo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Ouvrir l’assistant MarketScope',
      child: Tooltip(
        message: 'Assistant MarketScope',
        child: SizedBox(
          width: 64,
          height: 64,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _halo,
                builder: (context, _) {
                  final t = _halo.value;
                  return Container(
                    width: 56 + t * 16,
                    height: 56 + t * 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.greenLight.withValues(
                        alpha: 0.28 * (1 - t),
                      ),
                    ),
                  );
                },
              ),
              Material(
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                elevation: 6,
                shadowColor: AppColors.ink.withValues(alpha: 0.4),
                child: InkWell(
                  onTap: () => ouvrirAssistant(context),
                  child: const _AvatarAssistant(taille: 56, icone: 26),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ouvre la fenêtre de discussion en feuille glissante.
Future<void> ouvrirAssistant(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _FeuilleAssistant(),
  );
}

class _AvatarAssistant extends StatelessWidget {
  const _AvatarAssistant({required this.taille, required this.icone});

  final double taille;
  final double icone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: taille,
      height: taille,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.greenLight, AppColors.green, AppColors.ink2],
          stops: [0, 0.55, 1],
        ),
      ),
      child: Icon(
        PhosphorIconsRegular.sparkle,
        color: Colors.white,
        size: icone,
      ),
    );
  }
}

class _FeuilleAssistant extends StatefulWidget {
  const _FeuilleAssistant();

  @override
  State<_FeuilleAssistant> createState() => _FeuilleAssistantState();
}

class _FeuilleAssistantState extends State<_FeuilleAssistant> {
  final _saisie = TextEditingController();
  final _defilement = ScrollController();
  final _conversation = ConversationAssistant.instance;

  @override
  void initState() {
    super.initState();
    _conversation.addListener(_descendre);
    _saisie.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _conversation.removeListener(_descendre);
    _saisie.dispose();
    _defilement.dispose();
    super.dispose();
  }

  /// Fait défiler jusqu'au dernier message après chaque changement.
  void _descendre() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_defilement.hasClients) return;
      _defilement.animateTo(
        _defilement.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _envoyer([String? texte]) async {
    final question = (texte ?? _saisie.text).trim();
    if (question.isEmpty || _conversation.enAttente) return;
    _saisie.clear();
    if (question == _suggestionProximite && !_conversation.partagePosition) {
      await _basculerPosition();
    }
    await _conversation.envoyer(question);
  }

  Future<void> _basculerPosition() async {
    final erreur = await _conversation.basculerPartagePosition();
    if (!mounted) return;
    final message =
        erreur ??
        (_conversation.partagePosition
            ? 'Position partagée avec l’assistant pour vos questions.'
            : 'Position non partagée.');
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clavier = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: clavier),
      child: DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 1,
        expand: false,
        builder: (context, controleurFeuille) => Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          clipBehavior: Clip.antiAlias,
          child: ListenableBuilder(
            listenable: _conversation,
            builder: (context, _) {
              final messages = _conversation.messages;
              return Column(
                children: [
                  _EnTete(
                    controleur: controleurFeuille,
                    peutReinitialiser:
                        messages.isNotEmpty && !_conversation.enAttente,
                    onReinitialiser: _conversation.reinitialiser,
                  ),
                  Expanded(
                    child: messages.isEmpty
                        ? _Accueil(onSuggestion: _envoyer)
                        : ListView.builder(
                            controller: _defilement,
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            itemCount:
                                messages.length +
                                (_conversation.enAttente ? 1 : 0),
                            itemBuilder: (context, i) {
                              if (i == messages.length) {
                                return const _IndicateurFrappe();
                              }
                              final m = messages[i];
                              return _Bulle(
                                key: ObjectKey(m),
                                message: m,
                                onReessayer:
                                    i == messages.length - 1 && m.erreur
                                    ? _conversation.reessayer
                                    : null,
                              );
                            },
                          ),
                  ),
                  _ZoneSaisie(
                    controleur: _saisie,
                    actif: !_conversation.enAttente,
                    onEnvoyer: _envoyer,
                    positionPartagee: _conversation.partagePosition,
                    localisationEnCours: _conversation.localisationEnCours,
                    onBasculerPosition: _basculerPosition,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EnTete extends StatelessWidget {
  const _EnTete({
    required this.controleur,
    required this.peutReinitialiser,
    required this.onReinitialiser,
  });

  final ScrollController controleur;
  final bool peutReinitialiser;
  final VoidCallback onReinitialiser;

  @override
  Widget build(BuildContext context) {
    // Le SingleChildScrollView relie l'en-tête au glissement de la feuille.
    return SingleChildScrollView(
      controller: controleur,
      physics: const ClampingScrollPhysics(),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [AppColors.ink, AppColors.ink2]),
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 14),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.paper.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const _AvatarAssistant(taille: 40, icone: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assistant MarketScope',
                        style: AppTextStyles.titleLarge.copyWith(
                          color: AppColors.paper,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppColors.greenLight,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'IA · répond à partir des relevés réels',
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.paper.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Nouvelle conversation',
                  onPressed: peutReinitialiser ? onReinitialiser : null,
                  color: AppColors.paper,
                  disabledColor: AppColors.paper.withValues(alpha: 0.3),
                  icon: const Icon(PhosphorIconsRegular.arrowClockwise),
                ),
                IconButton(
                  tooltip: 'Fermer',
                  onPressed: () => Navigator.of(context).pop(),
                  color: AppColors.paper,
                  icon: const Icon(PhosphorIconsRegular.x),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Accueil extends StatelessWidget {
  const _Accueil({required this.onSuggestion});

  final ValueChanged<String> onSuggestion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 12),
        const Center(child: _AvatarAssistant(taille: 72, icone: 34)),
        const SizedBox(height: 16),
        Text(
          'Bonjour ! 👋',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          'Posez-moi vos questions sur les prix des marchés : où acheter moins '
          'cher, comment évoluent les prix, ou comment utiliser l’application.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < _suggestions.length; i++)
              _Apparition(
                delai: Duration(milliseconds: 80 * i),
                child: ActionChip(
                  avatar: Icon(
                    PhosphorIconsRegular.lightning,
                    size: 16,
                    color: theme.marque,
                  ),
                  label: Text(_suggestions[i]),
                  onPressed: () => onSuggestion(_suggestions[i]),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Bulle extends StatelessWidget {
  const _Bulle({super.key, required this.message, this.onReessayer});

  final MessageAssistant message;
  final VoidCallback? onReessayer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final moi = message.auteur == AuteurMessage.utilisateur;

    final Color fond;
    final Color texte;
    if (moi) {
      fond = theme.marque;
      texte = theme.estSombre ? AppColors.darkPaper : Colors.white;
    } else if (message.erreur) {
      fond = theme.alertBg;
      texte = theme.alertFg;
    } else {
      fond = theme.fondCarte;
      texte = theme.colorScheme.onSurface;
    }

    final bulle = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.78,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: fond,
        border: moi || message.erreur ? null : Border.all(color: theme.ligne),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(moi ? 18 : 4),
          bottomRight: Radius.circular(moi ? 4 : 18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SelectableText.rich(
            TextSpan(
              children: _texteEnrichi(message.texte),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: texte,
                height: 1.45,
              ),
            ),
          ),
          if (onReessayer != null) ...[
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: onReessayer,
              style: TextButton.styleFrom(
                foregroundColor: texte,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
              icon: const Icon(PhosphorIconsRegular.arrowClockwise, size: 16),
              label: const Text('Réessayer'),
            ),
          ],
        ],
      ),
    );

    return _Apparition(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment: moi
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!moi) ...[
              const _AvatarAssistant(taille: 28, icone: 14),
              const SizedBox(width: 8),
            ],
            Flexible(child: bulle),
          ],
        ),
      ),
    );
  }
}

/// Transforme le **gras** markdown en TextSpan (seul formatage demandé à l'IA).
List<TextSpan> _texteEnrichi(String texte) {
  final spans = <TextSpan>[];
  final motif = RegExp(r'\*\*(.+?)\*\*');
  var debut = 0;
  for (final m in motif.allMatches(texte)) {
    if (m.start > debut) {
      spans.add(TextSpan(text: texte.substring(debut, m.start)));
    }
    spans.add(
      TextSpan(
        text: m.group(1),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
    debut = m.end;
  }
  if (debut < texte.length) spans.add(TextSpan(text: texte.substring(debut)));
  // Les puces « * » en début de ligne deviennent des « • ».
  return spans
      .map(
        (s) => s.style == null
            ? TextSpan(
                text: s.text?.replaceAll(
                  RegExp(r'^[ \t]*[\*\-] ', multiLine: true),
                  '• ',
                ),
              )
            : s,
      )
      .toList();
}

/// Trois points qui rebondissent pendant que l'IA réfléchit.
class _IndicateurFrappe extends StatefulWidget {
  const _IndicateurFrappe();

  @override
  State<_IndicateurFrappe> createState() => _IndicateurFrappeState();
}

class _IndicateurFrappeState extends State<_IndicateurFrappe>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'L’assistant écrit',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const _AvatarAssistant(taille: 28, icone: 14),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: theme.fondCarte,
                border: Border.all(color: theme.ligne),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                  bottomLeft: Radius.circular(4),
                ),
              ),
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Transform.translate(
                        offset: Offset(
                          0,
                          -4 *
                              math.max(
                                0,
                                math.sin((_c.value - i * 0.18) * 2 * math.pi),
                              ),
                        ),
                        child: Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.symmetric(horizontal: 2.5),
                          decoration: BoxDecoration(
                            color: theme.marque.withValues(alpha: 0.75),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoneSaisie extends StatelessWidget {
  const _ZoneSaisie({
    required this.controleur,
    required this.actif,
    required this.onEnvoyer,
    required this.positionPartagee,
    required this.localisationEnCours,
    required this.onBasculerPosition,
  });

  final TextEditingController controleur;
  final bool actif;
  final VoidCallback onEnvoyer;
  final bool positionPartagee;
  final bool localisationEnCours;
  final VoidCallback onBasculerPosition;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final peutEnvoyer = actif && controleur.text.trim().isNotEmpty;
    // Bordure de champ à 3:1 minimum (WCAG 1.4.11), comme dans le thème.
    final bordure = theme.brightness == Brightness.dark
        ? AppColors.darkLineStrong
        : AppColors.lineStrong;
    return Container(
      decoration: BoxDecoration(
        color: theme.fondCarte,
        border: Border(top: BorderSide(color: theme.ligne)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // État du partage porté par l'icône pleine/vide ET le libellé,
                // pas seulement la couleur (WCAG 1.4.1).
                IconButton(
                  tooltip: positionPartagee
                      ? 'Arrêter de partager ma position'
                      : 'Partager ma position avec l’assistant',
                  isSelected: positionPartagee,
                  onPressed: localisationEnCours ? null : onBasculerPosition,
                  icon: localisationEnCours
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(PhosphorIconsRegular.mapPin),
                  selectedIcon: Icon(
                    PhosphorIconsFill.mapPin,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    controller: controleur,
                    enabled: actif,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 500,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onEnvoyer(),
                    decoration: InputDecoration(
                      hintText: actif
                          ? 'Votre question…'
                          : 'L’assistant réfléchit…',
                      counterText: '',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        borderSide: BorderSide(color: bordure),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        borderSide: BorderSide(color: bordure),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        borderSide: BorderSide(color: theme.marque, width: 1.6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedScale(
                  scale: peutEnvoyer ? 1 : 0.85,
                  duration: const Duration(milliseconds: 180),
                  child: IconButton.filled(
                    tooltip: 'Envoyer',
                    onPressed: peutEnvoyer ? onEnvoyer : null,
                    icon: const Icon(PhosphorIconsRegular.arrowUp),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              positionPartagee
                  ? 'Position partagée pour cette conversation, jamais enregistrée.'
                  : 'L’IA peut se tromper : vérifiez les prix dans l’application.',
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fondu + léger glissement, joué une seule fois à l'apparition.
class _Apparition extends StatelessWidget {
  const _Apparition({required this.child, this.delai = Duration.zero});

  final Widget child;
  final Duration delai;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final total = 280 + delai.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      builder: (context, v, child) {
        final t = Curves.easeOutCubic.transform(
          ((v * total - delai.inMilliseconds) / 280).clamp(0.0, 1.0),
        );
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - t)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
