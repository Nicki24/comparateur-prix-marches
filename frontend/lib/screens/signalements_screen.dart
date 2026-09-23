import 'package:flutter/material.dart';

import '../models/signalement.dart';
import '../services/signalement_service.dart';
import '../theme/app_theme.dart';
import '../utils/formats.dart';
import '../widgets/etats.dart';
import '../widgets/ms_anim.dart';
import '../widgets/ms_card.dart';
import '../widgets/ms_decor.dart';
import '../widgets/produit_icone.dart';
import '../widgets/statut_badge.dart';

class SignalementsScreen extends StatefulWidget {
  const SignalementsScreen({super.key});

  @override
  State<SignalementsScreen> createState() => _SignalementsScreenState();
}

class _SignalementsScreenState extends State<SignalementsScreen> {
  late Future<List<Signalement>> _futur;
  bool _enDetection = false;

  @override
  void initState() {
    super.initState();
    _futur = SignalementService.lister();
  }

  Future<void> _recharger() async {
    setState(() {
      _futur = SignalementService.lister();
    });
    await _futur;
  }

  Future<void> _detecterObsoletes() async {
    setState(() => _enDetection = true);
    try {
      final nombre = await SignalementService.detecterObsoletes();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$nombre relevé(s) marqué(s) obsolète(s).')),
      );
      await _recharger();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _enDetection = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Signalements'),
        actions: [
          IconButton(
            tooltip: 'Détecter les prix obsolètes',
            onPressed: _enDetection ? null : _detecterObsoletes,
            icon: _enDetection
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.schedule_send),
          ),
        ],
      ),
      body: FutureBuilder<List<Signalement>>(
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

          final signalements = snapshot.data ?? [];
          if (signalements.isEmpty) {
            return const ContenuVide(
              message: 'Aucune anomalie détectée. '
                  'Utilisez l’icône en haut à droite pour lancer la détection '
                  'des prix obsolètes.',
              icone: Icons.verified_user,
            );
          }

          return RefreshIndicator(
            color: AppColors.green,
            onRefresh: _recharger,
            child: MsDecorFond(
              densite: 0.5,
              child: ListView.separated(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.xl),
                itemCount: signalements.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final s = signalements[index];
                  final releve = s.releve;
                  final estPrixAnormal =
                      s.typeAnomalie == 'prix_anormal';
                  final theme = Theme.of(context);
                  return MsCascade(
                    index: index % 7,
                    child: MarketScopeCard(
                      padding: const EdgeInsets.all(
                          AppSpacing.md),
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          ProduitIcone(
                            nom: releve?.produit?.nom ?? '',
                            categorie: releve
                                ?.produit?.categorie,
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
                                        s.libelleType,
                                        maxLines: 1,
                                        overflow: TextOverflow
                                            .ellipsis,
                                        style: theme
                                            .textTheme.titleSmall
                                            ?.copyWith(
                                          fontWeight:
                                              FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    estPrixAnormal
                                        ? const StatutBadge
                                            .alerte('Écart')
                                        : const StatutBadge
                                            .obsolete(
                                            'Obsolète'),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                if (releve?.produit != null)
                                  Text(
                                    '${releve!.produit!.nom} — ${formaterPrix(releve.valeur)}',
                                    maxLines: 1,
                                    overflow:
                                        TextOverflow.ellipsis,
                                    style: AppTextStyles
                                        .priceSmall
                                        .copyWith(
                                      fontSize: 12.5,
                                      color: theme.colorScheme
                                          .onSurface,
                                    ),
                                  ),
                                if (releve?.marche != null)
                                  Text(
                                    releve!.marche!.nom,
                                    maxLines: 1,
                                    overflow:
                                        TextOverflow.ellipsis,
                                    style: theme
                                        .textTheme.bodySmall
                                        ?.copyWith(
                                      color: theme.colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                Text(
                                  'Détecté le ${formaterDate(s.dateDetection)}',
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(
                                    fontSize: 11.5,
                                    color: theme.colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}