import 'package:flutter/material.dart';

import '../models/marche.dart';
import '../models/produit.dart';
import '../models/releve_prix.dart';
import '../services/marche_service.dart';
import '../services/produit_service.dart';
import '../services/releve_service.dart';
import '../theme/app_theme.dart';
import '../utils/formats.dart';
import '../widgets/etats.dart';
import '../widgets/ms_anim.dart';
import '../widgets/ms_button.dart';
import '../widgets/ms_card.dart';
import '../widgets/ms_decor.dart';

/// Formulaire de saisie d'un relevé de prix (contributeur).
class SaisieReleveScreen extends StatefulWidget {
  const SaisieReleveScreen({super.key});

  @override
  State<SaisieReleveScreen> createState() => _SaisieReleveScreenState();
}

class _SaisieReleveScreenState extends State<SaisieReleveScreen> {
  final _formulaire = GlobalKey<FormState>();
  final _prixController = TextEditingController();
  final _commentaireController = TextEditingController();

  late Future<List<Produit>> _futurProduits;
  late Future<List<Marche>> _futurMarches;

  Produit? _produitChoisi;
  Marche? _marcheChoisi;
  DateTime _date = DateTime.now();

  bool _enChargement = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _futurProduits = ProduitService.lister();
    _futurMarches = MarcheService.lister();
  }

  @override
  void dispose() {
    _prixController.dispose();
    _commentaireController.dispose();
    super.dispose();
  }

  Future<void> _choisirDate() async {
    final choix = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      helpText: 'Date du relevé',
    );
    if (choix != null) {
      setState(() => _date = choix);
    }
  }

  Future<void> _soumettre() async {
    if (!(_formulaire.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _enChargement = true;
      _erreur = null;
    });

    try {
      final releve = await ReleveService.creer(
        produitId: _produitChoisi!.id,
        marcheId: _marcheChoisi!.id,
        valeur: double.parse(_prixController.text.trim().replaceAll(',', '.')),
        dateReleve: _date,
        commentaire: _commentaireController.text.trim().isEmpty
            ? null
            : _commentaireController.text.trim(),
      );

      if (!mounted) {
        return;
      }
      await _confirmerEnvoi(releve);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _erreur = e.toString().replaceFirst('ApiException: ', '');
        _enChargement = false;
      });
    }
  }

  Future<void> _confirmerEnvoi(RelevePrix releve) async {
    final message = releve.estSignale
        ? 'Relevé enregistré, mais un prix anormal a été détecté. '
            'Il sera vérifié par un administrateur.'
        : 'Relevé de ${formaterPrix(releve.valeur)} enregistré. '
            'Merci pour votre contribution !';

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          releve.estSignale ? Icons.warning : Icons.check_circle,
          color: releve.estSignale ? Colors.orange : Colors.green,
        ),
        title: Text(releve.estSignale ? 'Prix signalé' : 'Relevé enregistré'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau relevé')),
      body: MsDecorFond(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            MsApparition(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.ink, AppColors.ink2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius:
                      BorderRadius.circular(AppRadius.sheet),
                ),
                child: const Stack(
                  children: [
                    Positioned(
                      top: -40,
                      right: -30,
                      child: _HaloSaisie(),
                    ),
                    Row(
                      children: [
                        _IconeSaisie(),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Un relevé par produit, marché et jour',
                                style: TextStyle(
                                  color: Color(0xFFEAF3EE),
                                  fontFamily: AppFonts.sans,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Si vous avez déjà enregistré ce produit dans ce marché aujourd’hui, le serveur vous le signalera.',
                                style: TextStyle(
                                  color: Color(0xFF9FB6AE),
                                  fontSize: 12.5,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Form(
              key: _formulaire,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionReleve(
                      etape: '1',
                      titre: 'Quel produit ? Dans quel marché ?'),
                  MsApparition(
                    child: _ChampProduit(
                      futurProduits: _futurProduits,
                      produit: _produitChoisi,
                      onChanged: (p) =>
                          setState(() => _produitChoisi = p),
                    ),
                  ),
                  const SizedBox(height: 12),
                  MsApparition(
                    delai: Duration(milliseconds: 60),
                    child: _ChampMarche(
                      futurMarches: _futurMarches,
                      marche: _marcheChoisi,
                      onChanged: (m) =>
                          setState(() => _marcheChoisi = m),
                    ),
                  ),
                  const _SectionReleve(
                      etape: '2', titre: 'Quel prix ? Quelle date ?'),
                  MsApparition(
                    child: TextFormField(
                      controller: _prixController,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Prix observé (Ariary)',
                        hintText: 'Ex. 3200',
                        prefixIcon: const Icon(
                            Icons.payments_outlined),
                        suffixText:
                            _produitChoisi?.uniteMesure.isNotEmpty ==
                                    true
                                ? '/ ${_produitChoisi!.uniteMesure}'
                                : null,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Veuillez saisir le prix observé.';
                        }
                        final prix = double.tryParse(v
                            .trim()
                            .replaceAll(',', '.'));
                        if (prix == null || prix <= 0) {
                          return 'Le prix doit être un nombre supérieur à 0.';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  MsApparition(
                    child: MarketScopeCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.10),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.event_rounded,
                              size: 19,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Date du relevé',
                                  style: TextStyle(
                                      fontWeight:
                                          FontWeight.w600,
                                      fontSize: 13.5),
                                ),
                                Text(
                                  formaterDate(_date),
                                  style: TextStyle(
                                    fontFamily: AppFonts.mono,
                                    fontSize: 12.5,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: _choisirDate,
                            child: const Text('Modifier'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const _SectionReleve(
                      etape: '3',
                      titre: 'Précisions (facultatif)'),
                  TextField(
                    controller: _commentaireController,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Commentaire',
                      hintText:
                          'État du produit, qualité, précisions…',
                      prefixIcon:
                          Icon(Icons.notes_rounded),
                    ),
                    maxLines: 2,
                  ),
                  if (_erreur != null) ...[
                    const SizedBox(height: 12),
                    MarketScopeErrorBanner(
                        message: _erreur!),
                  ],
                  const SizedBox(height: 20),
                  MarketScopeButton(
                    label: 'Envoyer le relevé',
                    icone: Icons.send_rounded,
                    enChargement: _enChargement,
                    onPressed:
                        _enChargement ? null : _soumettre,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChampProduit extends StatelessWidget {
  const _ChampProduit({
    required this.futurProduits,
    required this.produit,
    required this.onChanged,
  });

  final Future<List<Produit>> futurProduits;
  final Produit? produit;
  final ValueChanged<Produit?> onChanged;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Produit>>(
      future: futurProduits,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LinearProgressIndicator();
        }
        if (snapshot.hasError || (snapshot.data ?? []).isEmpty) {
          return const ContenuVide(
            message: 'Aucun produit disponible.',
            icone: Icons.category,
          );
        }
        final produits = snapshot.data!;
        return DropdownButtonFormField<Produit>(
          value: produit,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Produit',
            prefixIcon: Icon(Icons.category_outlined),
          ),
          items: [
            for (final p in produits)
              DropdownMenuItem(value: p, child: Text(p.nom)),
          ],
          onChanged: onChanged,
          validator: (v) => v == null ? 'Choisissez un produit.' : null,
        );
      },
    );
  }
}

/// En-tête de section du formulaire : étape numérotée en mono.
class _SectionReleve extends StatelessWidget {
  const _SectionReleve({required this.etape, required this.titre});

  final String etape;
  final String titre;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 10),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              etape,
              style: stylePrix(taille: 11.5, couleur: AppColors.green),
            ),
          ),
          const SizedBox(width: 9),
          Text(
            titre.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontFamily: AppFonts.mono,
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Divider(
              color: theme.brightness == Brightness.dark
                  ? AppColors.darkLine
                  : AppColors.line,
            ),
          ),
        ],
      ),
    );
  }
}

class _HaloSaisie extends StatelessWidget {
  const _HaloSaisie();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.greenLight.withValues(alpha: 0.14),
            AppColors.greenLight.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}

class _IconeSaisie extends StatelessWidget {
  const _IconeSaisie();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.receipt_long_outlined,
        color: AppColors.greenLight,
        size: 22,
      ),
    );
  }
}

// Bouton d'envoi : désormais MarketScopeButton (vert uni).
// L'ancien dégradé vert→encre a été supprimé (charte sobre).

class _ChampMarche extends StatelessWidget {
  const _ChampMarche({
    required this.futurMarches,
    required this.marche,
    required this.onChanged,
  });

  final Future<List<Marche>> futurMarches;
  final Marche? marche;
  final ValueChanged<Marche?> onChanged;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Marche>>(
      future: futurMarches,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LinearProgressIndicator();
        }
        if (snapshot.hasError || (snapshot.data ?? []).isEmpty) {
          return const ContenuVide(
            message: 'Aucun marché disponible.',
            icone: Icons.storefront,
          );
        }
        final marches = snapshot.data!;
        return DropdownButtonFormField<Marche>(
          value: marche,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Marché',
            prefixIcon: Icon(Icons.storefront_outlined),
          ),
          items: [
            for (final m in marches)
              DropdownMenuItem(value: m, child: Text(m.nom)),
          ],
          onChanged: onChanged,
          validator: (v) => v == null ? 'Choisissez un marché.' : null,
        );
      },
    );
  }
}