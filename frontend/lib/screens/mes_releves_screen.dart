import 'package:flutter/material.dart';

import '../models/releve_prix.dart';
import '../services/releve_service.dart';
import '../theme/app_theme.dart';
import '../utils/formats.dart';
import '../widgets/etats.dart';
import '../widgets/ms_anim.dart';
import '../widgets/ms_card.dart';
import '../widgets/ms_decor.dart';
import '../widgets/produit_icone.dart';
import '../widgets/statut_badge.dart';

/// Historique personnel des relevés de l'utilisateur connecté.
/// Lecture seule : un relevé est immuable après envoi (règle métier).
class MesRelevesScreen extends StatefulWidget {
  const MesRelevesScreen({super.key});

  @override
  State<MesRelevesScreen> createState() => _MesRelevesScreenState();
}

class _MesRelevesScreenState extends State<MesRelevesScreen> {
  late Future<List<RelevePrix>> _futur;

  @override
  void initState() {
    super.initState();
    _futur = ReleveService.mesReleves();
  }

  Future<void> _recharger() async {
    setState(() {
      _futur = ReleveService.mesReleves();
    });
    await _futur;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Mes relevés')),
      body: MsDecorFond(
        densite: 0.6,
        child: FutureBuilder<List<RelevePrix>>(
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

            final releves = snapshot.data ?? [];
            if (releves.isEmpty) {
              return const ContenuVide(
                titre: 'Aucun relevé',
                message: 'Aucun relevé pour le moment. '
                    'Saisissez votre premier prix sur le terrain.',
                icone: Icons.add_chart_rounded,
              );
            }

            final nbSignales =
                releves.where((r) => r.estSignale).length;

            return RefreshIndicator(
              color: AppColors.green,
              onRefresh: _recharger,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.xl),
                itemCount: releves.length + 1,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${releves.length} relevé${releves.length > 1 ? 's' : ''}'
                        '${nbSignales > 0 ? ' · $nbSignales signalé${nbSignales > 1 ? 's' : ''}' : ''}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme
                              .colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }
                  final r = releves[index - 1];
                  return MsCascade(
                    index: (index - 1) % 7,
                    child: MarketScopeCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm),
                      child: Row(
                        children: [
                          ProduitIcone(
                            nom: r.produit?.nom ?? '',
                            categorie:
                                r.produit?.categorie,
                            taille: 42,
                            tailleIcone: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        r.produit?.nom ??
                                            'Produit',
                                        maxLines: 1,
                                        overflow:
                                            TextOverflow.ellipsis,
                                        style: theme
                                            .textTheme.titleSmall
                                            ?.copyWith(
                                          fontWeight:
                                              FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      formaterPrix(r.valeur),
                                      style: AppTextStyles
                                          .priceSmall
                                          .copyWith(
                                        color: r.estSignale
                                            ? theme.alertFg
                                            : theme.colorScheme
                                                .onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${r.marche?.nom ?? 'Marché'} · Relevé le ${formaterDate(r.dateReleve)}',
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(
                                    color: theme.colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                                if (r.commentaire != null &&
                                    r.commentaire!
                                        .isNotEmpty)
                                  Text(
                                    r.commentaire!,
                                    maxLines: 1,
                                    overflow:
                                        TextOverflow.ellipsis,
                                    style: theme
                                        .textTheme.bodySmall
                                        ?.copyWith(
                                      color: theme.colorScheme
                                          .onSurfaceVariant
                                          .withValues(
                                              alpha: 0.75),
                                      fontSize: 11.5,
                                    ),
                                  ),
                                const SizedBox(height: 6),
                                r.estSignale
                                    ? const StatutBadge.alerte(
                                        'Signalé — en vérification')
                                    : const StatutBadge.ok(
                                        'Validé'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}