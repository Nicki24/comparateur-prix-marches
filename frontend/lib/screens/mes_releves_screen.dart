import 'package:flutter/material.dart';

import '../models/releve_prix.dart';
import '../services/releve_service.dart';
import '../theme/app_theme.dart';
import '../utils/formats.dart';
import '../widgets/etats.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Mes relevés')),
      body: FutureBuilder<List<RelevePrix>>(
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
              message: 'Aucun relevé pour le moment. '
                  'Saisissez votre premier prix sur le terrain.',
              icone: Icons.add_chart,
            );
          }

          return RefreshIndicator(
            onRefresh: _recharger,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: releves.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final r = releves[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: r.estSignale
                          ? AppColors.alertBg
                          : AppColors.okBg,
                      child: Icon(
                        r.estSignale ? Icons.warning_amber : Icons.payments,
                        color: r.estSignale
                            ? AppColors.alertFg
                            : AppColors.okFg,
                      ),
                    ),
                    title: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${r.produit?.nom ?? 'Produit'} — ',
                          ),
                          TextSpan(
                            text: formaterPrix(r.valeur),
                            style: stylePrix(
                              taille: 15,
                              couleur: r.estSignale
                                  ? AppColors.alertFg
                                  : AppColors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (r.marche != null) Text(r.marche!.nom),
                        Text('Relevé le ${formaterDate(r.dateReleve)}'),
                        if (r.commentaire != null && r.commentaire!.isNotEmpty)
                          Text(
                            r.commentaire!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: r.estSignale
                        ? const StatutBadge.alerte('Signalé')
                        : const StatutBadge.ok('Validé'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}