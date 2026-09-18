import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/session.dart';
import '../theme/app_theme.dart';
import '../widgets/fond_auth.dart';
import '../widgets/logo.dart';
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
  String? _erreur;

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
          // ─── Fond encre en dégradé + halos de couleur ─────────────────
          const Positioned.fill(child: FondEncre()),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: surEncre),
                    style: IconButton.styleFrom(
                      backgroundColor: surEncre.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: MarqueComplete(
                    tailleLogo: 72,
                    couleurTexte: surEncre,
                    couleurSousTitre: attenueEncre,
                    sousTitre: 'Rejoignez la communauté des contributeurs',
                  ),
                ),
                const SizedBox(height: 28),
                Form(
                  key: _formulaire,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: decoAuth(
                          icone: Icons.person_outline,
                          label: 'Nom complet',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Veuillez saisir votre nom.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: decoAuth(
                          icone: Icons.mail_outline,
                          label: 'Adresse e-mail',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Veuillez saisir votre e-mail.';
                          }
                          if (!v.contains('@')) {
                            return 'Adresse e-mail invalide.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: decoAuth(
                          icone: Icons.lock_outline,
                          label: 'Mot de passe',
                          hint: '8 caractères minimum',
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
                        obscureText: true,
                        decoration: decoAuth(
                          icone: Icons.lock_outline,
                          label: 'Confirmer le mot de passe',
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.alertBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                size: 20,
                                color: AppColors.alertFg,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _erreur!,
                                  style: const TextStyle(
                                    color: AppColors.alertFg,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _enChargement ? null : _inscrire,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _enChargement
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Créer mon compte'),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Les nouveaux comptes sont créés en tant que contributeurs.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: attenueEncre,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          onPressed: _voirConnexion,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.greenLight,
                          ),
                          child: const Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Déjà un compte ? ',
                                  style: TextStyle(color: attenueEncre),
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
                    ],
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