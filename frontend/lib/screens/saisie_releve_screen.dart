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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Saisir un relevé')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── Info-card en dégradé ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.ink, AppColors.ink2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.2),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
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
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Un relevé par produit, marché et jour',
                        style: TextStyle(
                          color: Color(0xFFEAF3EE),
                          fontFamily: AppFonts.sans,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Vous pouvez soumettre au maximum un prix par produit, '
                        'par marché et par jour.',
                        style: TextStyle(
                          color: const Color(0xFF9FB6AE),
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Form(
            key: _formulaire,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionReleve(etape: '1', titre: 'Produit et marché'),
                _ChampProduit(
                  futurProduits: _futurProduits,
                  produit: _produitChoisi,
                  onChanged: (p) => setState(() => _produitChoisi = p),
                ),
                const SizedBox(height: 16),
                _ChampMarche(
                  futurMarches: _futurMarches,
                  marche: _marcheChoisi,
                  onChanged: (m) => setState(() => _marcheChoisi = m),
                ),
                const _SectionReleve(etape: '2', titre: 'Prix et date'),
                TextFormField(
                  controller: _prixController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Prix observé (Ariary)',
                    hintText: 'Ex. 3200',
                    prefixIcon: const Icon(Icons.payments_outlined),
                    suffixText: _produitChoisi?.uniteMesure,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Veuillez saisir le prix.';
                    }
                    final prix = double.tryParse(v.trim().replaceAll(',', '.'));
                    if (prix == null || prix <= 0) {
                      return 'Le prix doit être supérieur à 0.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event),
                  title: const Text('Date du relevé'),
                  subtitle: Text(formaterDate(_date)),
                  trailing: TextButton(
                    onPressed: _choisirDate,
                    child: const Text('Modifier'),
                  ),
                ),
                const SizedBox(height: 8),
                const _SectionReleve(etape: '3', titre: 'Détails'),
                TextField(
                  controller: _commentaireController,
                  decoration: const InputDecoration(
                    labelText: 'Commentaire (facultatif)',
                    hintText: 'État du produit, précisions…',
                  ),
                  maxLines: 2,
                ),
                if (_erreur != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _erreur!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(height: 24),
                _BoutonEnvoyer(
                  enChargement: _enChargement,
                  onPressed: _soumettre,
                ),
              ],
            ),
          ),
        ],
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

/// Bouton d'envoi : dégradé vert → encre, ombre portée, icône dans une
/// pastille translucide.
class _BoutonEnvoyer extends StatelessWidget {
  const _BoutonEnvoyer({
    required this.enChargement,
    required this.onPressed,
  });

  final bool enChargement;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.green, AppColors.ink],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.green.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: enChargement ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: enChargement
                      ? const Padding(
                          padding: EdgeInsets.all(6),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Envoyer le relevé',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: AppFonts.sans,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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