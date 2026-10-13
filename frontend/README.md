# MarketScope — Application mobile (Flutter)

Application Android (et Web) de [MarketScope](../README.md) : consultation des prix,
saisie de relevés, administration et assistant IA.

- **Flutter 3.32** · Dart 3.8 · Material 3, thèmes clair et sombre
- Accessibilité **WCAG 2.2 AA** (contrastes, lecteurs d'écran, animations réduites)
- 40 tests (`flutter test`), aucune alerte (`flutter analyze`)

## Lancer en local

```bash
flutter pub get
flutter run                   # émulateur Android, appareil ou Chrome
```

L'application appelle l'API locale en développement et l'API en ligne en version de
production. Adresse personnalisée : `--dart-define=API_URL=https://…/api`.

## Organisation

| Dossier | Contenu |
|---|---|
| `lib/screens/` | Écrans : accueil, marchés, produits, comparaison, carte, saisie, relevés, profil, administration, aide |
| `lib/services/` | Client API, session chiffrée, localisation, assistant IA |
| `lib/widgets/` | Design system MarketScope (en-tête, cartes, boutons, états, assistant…) |
| `lib/theme/` | Jetons de couleur, typographie (Space Grotesk, Inter, IBM Plex Mono) |
| `test/` | Tests de widgets, d'accessibilité et de modèles |

## Compiler l'APK

Voir [`docs/DEPLOIEMENT.md`](../docs/DEPLOIEMENT.md) (signature, NDK, distribution).

```bash
flutter build apk --release
```
