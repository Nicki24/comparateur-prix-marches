import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../screens/login_screen.dart';
import '../services/session.dart';

/// À placer juste sous [MaterialApp] : affiche une seule alerte quand l'API
/// renvoie un 401 et que le jeton Sanctum n'est plus valide.
class AlerteSessionExpiree extends StatefulWidget {
  const AlerteSessionExpiree({super.key, required this.child});

  final Widget child;

  @override
  State<AlerteSessionExpiree> createState() => _AlerteSessionExpireeState();
}

class _AlerteSessionExpireeState extends State<AlerteSessionExpiree> {
  // -1 pour afficher aussi une expiration survenue avant le montage du widget.
  int _derniereVersion = -1;
  bool _dialogOuvert = false;

  @override
  void initState() {
    super.initState();
    Session.instance.addListener(_surExpiration);
    _surExpiration();
  }

  @override
  void dispose() {
    Session.instance.removeListener(_surExpiration);
    super.dispose();
  }

  void _surExpiration() {
    final session = Session.instance;
    if (!mounted ||
        _dialogOuvert ||
        session.messageExpiration == null ||
        session.versionExpiration == _derniereVersion) {
      return;
    }
    _derniereVersion = session.versionExpiration;
    _dialogOuvert = true;
    final message = session.messageExpiration!;
    // addPostFrameCallback ne planifie pas de frame : sans cette ligne,
    // l'alerte peut rester en attente indéfiniment si l'app est inactive.
    WidgetsBinding.instance.scheduleFrame();
    WidgetsBinding.instance.addPostFrameCallback((_) => _afficher(message));
  }

  Future<void> _afficher(String message) async {
    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          PhosphorIconsRegular.warningCircle,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('Session expirée'),
        content: Text(
          '$message\n\nConnectez-vous à nouveau pour continuer '
          'à utiliser votre compte.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  settings: const RouteSettings(name: 'login'),
                  builder: (_) => const LoginScreen(),
                ),
              );
            },
            child: const Text('Se reconnecter'),
          ),
        ],
      ),
    );
    if (!mounted) {
      return;
    }
    _dialogOuvert = false;
    Session.instance.effacerAlerteExpiration();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
