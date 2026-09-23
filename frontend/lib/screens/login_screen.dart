import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/session.dart';
import '../theme/app_theme.dart';
import '../widgets/fond_auth.dart';
import '../widgets/logo.dart';
import '../widgets/ms_anim.dart';
import '../widgets/ms_button.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formulaire = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _enChargement = false;
  bool _motDePasseVisible = false;
  String? _erreur;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _decoChamp({
    required IconData icone,
    required String label,
    Widget? suffix,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      labelText: label,
      prefixIcon: Icon(icone),
      suffixIcon: suffix,
      prefixIconColor: AppColors.textMuted,
      labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
      hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.7)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        borderSide: const BorderSide(color: AppColors.green, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        borderSide: const BorderSide(color: AppColors.terracotta),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        borderSide: const BorderSide(color: AppColors.terracotta, width: 1.8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Future<void> _seConnecter() async {
    if (!(_formulaire.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _enChargement = true;
      _erreur = null;
    });

    try {
      final token = await AuthService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final user = await AuthService.utilisateurCourant(token: token);
      await Session.instance.connecter(token, user);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _erreur = _messageErreur(e);
        _enChargement = false;
      });
    }
  }

  String _messageErreur(Object e) {
    if (e is ApiException) {
      return e.message;
    }
    return 'Connexion impossible. Vérifiez votre réseau.';
  }

  void _voirInscription() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ─── Fond encre + halos + atmosphère marché discrète ──────────
          const Positioned.fill(child: FondEncre()),
          const Positioned.fill(child: _AtmosphereMarche()),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: surEncre),
                        style: IconButton.styleFrom(
                          backgroundColor:
                              surEncre.withValues(alpha: 0.1),
                        ),
                        tooltip: 'Retour',
                      ),
                    ),
                    const SizedBox(height: 12),
                    const MsApparition(
                      child: Center(
                        child: MarqueComplete(
                          tailleLogo: 76,
                          couleurTexte: surEncre,
                          couleurSousTitre: attenueEncre,
                          sousTitre:
                              'Comparez · Suivez · Comprenez\nles prix des marchés locaux',
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    MsApparition(
                      delai: const Duration(milliseconds: 80),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bienvenue',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontFamily: AppFonts.display,
                                  fontWeight: FontWeight.w700,
                                  color: surEncre,
                                ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Connectez-vous pour contribuer aux relevés de prix.',
                            style: TextStyle(
                              color: attenueEncre,
                              fontSize: 13.5,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    MsApparition(
                      delai: const Duration(milliseconds: 140),
                      child: Form(
                        key: _formulaire,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              textInputAction: TextInputAction.next,
                              decoration: _decoChamp(
                                icone: Icons.mail_outline,
                                label: 'Adresse e-mail',
                              ),
                              validator: (v) {
                                final t = v?.trim() ?? '';
                                if (t.isEmpty) {
                                  return 'Veuillez saisir votre e-mail.';
                                }
                                if (!t.contains('@') || !t.contains('.')) {
                                  return 'Cette adresse e-mail semble invalide.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_motDePasseVisible,
                              autofillHints: const [AutofillHints.password],
                              textInputAction: TextInputAction.done,
                              decoration: _decoChamp(
                                icone: Icons.lock_outline,
                                label: 'Mot de passe',
                                suffix: IconButton(
                                  tooltip: _motDePasseVisible
                                      ? 'Masquer le mot de passe'
                                      : 'Afficher le mot de passe',
                                  icon: Icon(
                                    _motDePasseVisible
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() =>
                                      _motDePasseVisible =
                                          !_motDePasseVisible),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Veuillez saisir votre mot de passe.';
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) => _seConnecter(),
                            ),
                            if (_erreur != null) ...[
                              const SizedBox(height: 16),
                              MarketScopeErrorBanner(message: _erreur!),
                            ],
                            const SizedBox(height: 24),
                            MarketScopeButton(
                              label: 'Se connecter',
                              icone: Icons.login_rounded,
                              enChargement: _enChargement,
                              onPressed:
                                  _enChargement ? null : _seConnecter,
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: TextButton(
                                onPressed: _voirInscription,
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.greenLight,
                                  minimumSize: const Size(48, 44),
                                ),
                                child: const Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Pas encore de compte ? ',
                                        style:
                                            TextStyle(color: attenueEncre),
                                      ),
                                      TextSpan(
                                        text: 'Créer un compte',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.greenLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Atmosphère marché local très discrète : rangée d'icônes produits
/// (riz, légumes, huile…) à 8 % d'opacité en bas d'écran.
/// 100 % code Flutter, aucune image lourde, jamais devant le contenu.
class _AtmosphereMarche extends StatelessWidget {
  const _AtmosphereMarche();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Opacity(
            opacity: 0.10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.eco_rounded, size: 26, color: surEncre),
                SizedBox(width: 22),
                Icon(Icons.grain_rounded, size: 30, color: surEncre),
                SizedBox(width: 22),
                Icon(Icons.water_drop_outlined,
                    size: 26, color: surEncre),
                SizedBox(width: 22),
                Icon(Icons.shopping_basket_rounded,
                    size: 28, color: surEncre),
                SizedBox(width: 22),
                Icon(Icons.spa_rounded, size: 26, color: surEncre),
              ],
            ),
          ),
        ),
      ),
    );
  }
}