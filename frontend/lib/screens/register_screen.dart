import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/session.dart';
import '../theme/app_theme.dart';
import '../widgets/fond_auth.dart';
import '../widgets/logo.dart';
import '../widgets/ms_anim.dart';
import '../widgets/ms_button.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formulaire = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _enChargement = false;
  bool _mdpVisible = false;
  bool _confirmVisible = false;
  String? _erreur;

  InputDecoration _deco({
    required IconData icone,
    required String label,
    String? hint,
    Widget? suffix,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icone),
      suffixIcon: suffix,
      prefixIconColor: AppColors.textMuted,
      labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
      hintStyle:
          TextStyle(color: AppColors.textMuted.withValues(alpha: 0.7)),
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
        borderSide:
            const BorderSide(color: AppColors.terracotta, width: 1.8),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _inscrire() async {
    if (!(_formulaire.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _enChargement = true;
      _erreur = null;
    });

    try {
      final token = await AuthService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        passwordConfirmation: _confirmController.text,
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
        _erreur = e.toString().replaceFirst('ApiException: ', '');
        _enChargement = false;
      });
    }
  }

  void _voirConnexion() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: FondEncre()),
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
                          tailleLogo: 72,
                          couleurTexte: surEncre,
                          couleurSousTitre: attenueEncre,
                          sousTitre:
                              'Rejoignez la communauté des contributeurs',
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    MsApparition(
                      delai: const Duration(milliseconds: 80),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Créer un compte',
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
                            'Contribuez aux prix des marchés locaux en quelques secondes.',
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
                              controller: _nameController,
                              textCapitalization:
                                  TextCapitalization.words,
                              autofillHints: const [AutofillHints.name],
                              textInputAction: TextInputAction.next,
                              decoration: _deco(
                                icone: Icons.person_outline,
                                label: 'Nom complet',
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Veuillez saisir votre nom.';
                                }
                                if (v.trim().length < 2) {
                                  return 'Ce nom semble trop court.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              keyboardType:
                                  TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              textInputAction: TextInputAction.next,
                              decoration: _deco(
                                icone: Icons.mail_outline,
                                label: 'Adresse e-mail',
                              ),
                              validator: (v) {
                                final t = v?.trim() ?? '';
                                if (t.isEmpty) {
                                  return 'Veuillez saisir votre e-mail.';
                                }
                                if (!t.contains('@') ||
                                    !t.contains('.')) {
                                  return 'Cette adresse e-mail semble invalide.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_mdpVisible,
                              autofillHints: const [
                                AutofillHints.newPassword
                              ],
                              textInputAction: TextInputAction.next,
                              decoration: _deco(
                                icone: Icons.lock_outline,
                                label: 'Mot de passe',
                                hint: '8 caractères minimum',
                                suffix: IconButton(
                                  tooltip: _mdpVisible
                                      ? 'Masquer'
                                      : 'Afficher',
                                  icon: Icon(
                                    _mdpVisible
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() =>
                                      _mdpVisible = !_mdpVisible),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.length < 8) {
                                  return 'Le mot de passe doit contenir au moins 8 caractères.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmController,
                              obscureText: !_confirmVisible,
                              autofillHints: const [
                                AutofillHints.newPassword
                              ],
                              textInputAction: TextInputAction.done,
                              decoration: _deco(
                                icone: Icons.lock_outline,
                                label: 'Confirmer le mot de passe',
                                suffix: IconButton(
                                  tooltip: _confirmVisible
                                      ? 'Masquer'
                                      : 'Afficher',
                                  icon: Icon(
                                    _confirmVisible
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() =>
                                      _confirmVisible =
                                          !_confirmVisible),
                                ),
                              ),
                              validator: (v) {
                                if (v != _passwordController.text) {
                                  return 'Les mots de passe ne correspondent pas.';
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) => _inscrire(),
                            ),
                            if (_erreur != null) ...[
                              const SizedBox(height: 16),
                              MarketScopeErrorBanner(
                                  message: _erreur!),
                            ],
                            const SizedBox(height: 20),
                            MarketScopeButton(
                              label: 'Créer mon compte',
                              icone: Icons.person_add_outlined,
                              enChargement: _enChargement,
                              onPressed:
                                  _enChargement ? null : _inscrire,
                            ),
                            const SizedBox(height: 10),
                            const Center(
                              child: Text(
                                'Les nouveaux comptes sont créés en tant que contributeurs.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: attenueEncre,
                                  fontSize: 12.5,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Center(
                              child: TextButton(
                                onPressed: _voirConnexion,
                                style: TextButton.styleFrom(
                                  foregroundColor:
                                      AppColors.greenLight,
                                  minimumSize: const Size(48, 44),
                                ),
                                child: const Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Déjà un compte ? ',
                                        style: TextStyle(
                                            color: attenueEncre),
                                      ),
                                      TextSpan(
                                        text: 'Se connecter',
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