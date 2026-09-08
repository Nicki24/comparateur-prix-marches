import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/session.dart';

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
      final user = await AuthService.utilisateurCourant();
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
    final s = e.toString();
    return s.startsWith('ApiException')
        ? s.replaceFirst('ApiException: ', '')
        : 'Connexion impossible. Vérifiez votre réseau.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Se connecter')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Form(
            key: _formulaire,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Adresse e-mail',
                    prefixIcon: Icon(Icons.mail_outline),
                    border: OutlineInputBorder(),
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
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
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
                  const SizedBox(height: 12),
                  Text(
                    _erreur!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _enChargement ? null : _seConnecter,
                  child: _enChargement
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Se connecter'),
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