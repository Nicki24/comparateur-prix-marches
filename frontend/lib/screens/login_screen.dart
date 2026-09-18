import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/session.dart';
import '../theme/app_theme.dart';
import '../widgets/fond_auth.dart';
import '../widgets/logo.dart';
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
  String? _erreur;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
                    tailleLogo: 76,
                    couleurTexte: surEncre,
                    couleurSousTitre: attenueEncre,
                    sousTitre: 'Comparez · Suivez · Comprenez\nles prix des marchés locaux',
                  ),
                ),
                const SizedBox(height: 36),
                Form(
                  key: _formulaire,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _enChargement ? null : _seConnecter,
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
                            : const Text('Se connecter'),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: _voirInscription,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.greenLight,
                          ),
                          child: const Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Pas encore de compte ? ',
                                  style: TextStyle(color: attenueEncre),
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