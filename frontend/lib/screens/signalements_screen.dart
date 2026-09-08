import 'package:flutter/material.dart';

import '../models/signalement.dart';
import '../services/signalement_service.dart';
import '../utils/formats.dart';
import '../widgets/etats.dart';

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
    final theme = Theme.of(context);
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
            onRefresh: _recharger,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: signalements.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final s = signalements[index];
                final releve = s.releve;
                final estPrixAnormal = s.typeAnomalie == 'prix_anormal';
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: estPrixAnormal
                          ? theme.colorScheme.errorContainer
                          : theme.colorScheme.secondaryContainer,
                      child: Icon(
                        estPrixAnormal
                            ? Icons.warning_amber
                            : Icons.hourglass_empty,
                        color: estPrixAnormal
                            ? theme.colorScheme.error
                            : theme.colorScheme.secondary,
                      ),
                    ),
                    title: Text(s.libelleType),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (releve?.produit != null)
                          Text('${releve!.produit!.nom} — ${formaterPrix(releve.valeur)}'),
                        if (releve?.marche != null)
                          Text(releve!.marche!.nom),
                        Text('Détecté le ${formaterDate(s.dateDetection)}'),
                      ],
                    ),
                    isThreeLine: true,
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