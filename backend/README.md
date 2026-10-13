# MarketScope — API REST (Laravel)

API de la plateforme [MarketScope](../README.md) : comparaison des prix des marchés locaux de
Toliara.

- **Laravel 13** · PHP 8.3+ · MySQL 8 · authentification par jetons **Sanctum**
- 30 routes documentées dans [`docs/API.md`](../docs/API.md)
- 56 tests (`php artisan test`)

## Lancer en local

```bash
composer install
cp .env.example .env          # renseigner la connexion MySQL (DB_*)
php artisan key:generate
php artisan migrate --seed    # données de démonstration
php artisan serve             # → http://localhost:8000
```

Les tests utilisent la base `comparateur_prix_test` définie dans [`phpunit.xml`](phpunit.xml).

## Organisation

| Dossier | Contenu |
|---|---|
| `app/Http/Controllers/Api/` | Contrôleurs de l'API (auth, marchés, produits, relevés, assistant, maintenance) |
| `app/Services/` | Détection des anomalies, gestion du référentiel, assistant IA (Gemini / OpenRouter) |
| `app/Console/Commands/` | Installation de production, détection des prix obsolètes |
| `database/migrations/` | Schéma : utilisateurs, marchés (avec GPS), produits, relevés, signalements |
| `tests/Feature/` | Règles métier, sécurité, géolocalisation, suppression/fusion, assistant |

## Déploiement

Hébergée sur Wasmer Edge : voir [`docs/DEPLOIEMENT.md`](../docs/DEPLOIEMENT.md)
([`wasmer.toml`](wasmer.toml), [`app.yaml`](app.yaml)).
