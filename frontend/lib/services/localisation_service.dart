import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Pourquoi la position n'a pas pu être obtenue (message prêt à afficher).
class LocalisationException implements Exception {
  const LocalisationException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Accès à la position GPS de l'appareil (ou du navigateur).
///
/// La position n'est demandée qu'à l'initiative de l'utilisateur (bouton
/// 📍 du chat, « Ma position » sur la carte) et n'est jamais enregistrée.
abstract final class LocalisationService {
  /// Centre par défaut des cartes : Toliara.
  static const centreParDefaut = LatLng(-23.3516, 43.6855);

  static const _delai = Duration(seconds: 15);

  /// Position actuelle, en demandant l'autorisation si besoin.
  ///
  /// Lève [LocalisationException] avec un message clair si le GPS est
  /// coupé, si l'autorisation est refusée ou si la position tarde.
  static Future<LatLng> positionActuelle() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocalisationException(
        'La localisation est désactivée. Activez-la dans les réglages puis réessayez.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocalisationException(
        'Autorisation refusée : MarketScope ne peut pas connaître votre position.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocalisationException(
        'La localisation est bloquée pour MarketScope. Autorisez-la dans les réglages de l’appareil.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: _delai,
        ),
      );
      return LatLng(position.latitude, position.longitude);
    } on TimeoutException {
      final derniere = await Geolocator.getLastKnownPosition();
      if (derniere != null) {
        return LatLng(derniere.latitude, derniere.longitude);
      }
      throw const LocalisationException(
        'Position introuvable pour le moment. Réessayez à l’extérieur ou près d’une fenêtre.',
      );
    }
  }
}
