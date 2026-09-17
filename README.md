# Comparateur des Prix des Marchés Locaux

Application de **comparaison des prix des produits essentiels sur les marchés locaux** de Toliara (Madagascar).

**Projet de fin d'études — Mémoire (2026) — ENI** — présenté par **Norlande**.

---

## 📌 Contexte & Objectif

Ce projet vise à aider les consommateurs à comparer les prix des produits essentiels (riz, huile, sucre, tomates, etc.) entre les différents marchés de Toliara, afin de trouver le meilleur prix au quotidien.

## 🎯 Fonctionnalités principales (selon le cahier des charges)

- **Consultation publique sans compte** : tout le monde peut rechercher et comparer les prix des produits par marché sans s'inscrire.
- **Interface en français**.
- **Contribution des prix** : les contributeurs enregistrés peuvent saisir les relevés de prix.
- **Règles métier** :
  - ⛔ Pas de modification des relevés après validation.
  - 🔁 Maximum **1 relevé / contributeur / produit / marché / jour**.
- **Statistiques & graphiques** : évolution des prix (bibliothèque `fl_chart`).

## 🏗️ Architecture

Stack choisie (**Plan A — application mobile**) :

| Couche | Technologie | Dossier |
|--------|-------------|---------|
| 📱 Frontend (mobile) | **Flutter** + Dart | [`frontend/`](frontend/) |
| ⚙️ Backend (API REST) | **Laravel** (PHP) | [`backend/`](backend/) |
| 🗄️ Base de données | **MySQL** | — |

```
F:\Application comparaison de prix\
├── frontend\   → Application mobile Flutter
└── backend\    → API REST Laravel
```

---

## 🧰 État actuel du projet

✅ **Environnement de développement entièrement installé et vérifié.**

### Outils installés

| Outil | Version | Emplacement / Détail |
|-------|---------|----------------------|
| **Flutter SDK** | 3.32.4 | `C:\src\flutter` (Dart 3.8.1) |
| **Android Toolchain** | SDK 36.1.0 | Command-line tools + licences acceptées |
| **Laravel** | 13.30.1 | `backend/` — sert sur `http://localhost:8000` |
| **PHP** | 8.4.1 | `C:\php-8.4.1-nts-Win32-vs17-x64\php.exe` |
| **Composer** | 2.9.2 | Gestionnaire de paquets PHP |
| **MySQL** | 8.4.9 | Service `MySQL84` — **port 3308** |
| **Node.js** | v22.22.3 | + npm 10.9.8 / npx |
| **Git** | 2.49.0 | Contrôle de version |
| **Android Studio** | 2025.3.2 | IDE Android |
| **VS Code** | 1.121.0 | Éditeur principal |

### Configuration de la base de données (backend)

```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3308        # ⚠️ Port 3308 (3306/3307 déjà pris par WAMP)
DB_DATABASE=comparateur_prix
DB_USERNAME=root
DB_PASSWORD=root1234   # à changer en production
```

> ℹ️ **Pourquoi le port 3308 ?** Le poste dispose déjà d'un **WAMP** qui occupe les ports 3306 (MySQL 8.3) et 3307 (MariaDB 11.3). Le MySQL dédié au projet écoute donc sur **3308**.

### Migrations
Le schéma complet est implémenté : utilisateurs (avec rôle `contributeur`/`admin`), jetons Sanctum, **marchés**, **produits**, **relevés de prix** (contrainte unique `un_releve_par_jour_par_contributeur`) et **signalements** d'anomalies.

### API REST (21 routes)
- **Publique** : `GET /api/marches`, `GET /api/produits`, `GET /api/produits/{id}/comparaison` (prix triés + écarts %), `GET /api/produits/{id}/historique` (points pour `fl_chart`, filtre `marche_id`).
- **Authentification** (Sanctum) : `POST /api/register`, `POST /api/login`, `POST /api/logout`, `GET /api/user`.
- **Contributeur** : `POST /api/releves` (anti-doublon 1/jour, détection automatique prix anormal > ±40 %), `GET /api/mes-releves` (historique personnel, lecture seule).
- **Admin** : gestion des marchés et produits (créer, modifier, désactiver, **réactiver**), `GET /api/signalements`, `POST /api/signalements/detecter-obsoletes` (prix > 14 jours).

> Le CORS est activé (`config/cors.php`) pour permettre à l'application Flutter Web d'appeler l'API pendant le développement.

### Frontend Flutter

Application mobile Android (+ Web) pour la consultation et la contribution.

- **Consultation publique** (sans compte) : marchés, produits, comparaison des prix par marché (graphique en barres + écarts en %) et évolution historique (courbe `fl_chart`, modes moyenne/min/max).
- **Espace contributeur** : inscription, connexion, saisie de relevé de prix (avec sélecteur de date et détection du prix anormal), consultation de son historique personnel (statut valide/signalé).
- **Espace admin** : vue des signalements (détection des prix obsolètes), gestion complète des marchés et produits (créer, modifier, désactiver, réactiver).

```bash
cd frontend
flutter pub get
flutter run                          # émulateur Android / Chrome
# Autre adresse API :
flutter run --dart-define=API_URL=https://api.exemple.fr/api
```

> Par défaut, l'API est `http://localhost:8000/api` (web/désktop) ou `http://10.0.2.2:8000/api` (émulateur Android).

### Tests (Laravel)
```bash
cd backend
php artisan test    # 16 tests verts (règles métier + API)
```

### Tests (Flutter)
```bash
cd frontend
flutter analyze     # aucune alerte
flutter test        # 7 tests verts (widget + décodage des modèles)
```

> La configuration `phpunit.xml` utilise une base dédiée `comparateur_prix_test` (MySQL, port 3308). Les tests utilisent `RefreshDatabase` et `Sanctum::actingAs`.

### Comptes de démonstration (seeder)
| Rôle | Email | Mot de passe |
|------|-------|--------------|
| Admin | `admin@comparateur.mg` | `password123` |
| Contributeur | `contrib@comparateur.mg` | `password123` |

---

## 🚀 Lancer le projet sur un autre PC

### 0. Prérequis (installer si besoin)

- **PHP ≥ 8.3** + extensions `pdo_mysql`, `mbstring`, `openssl`
- **Composer** 2.x
- **MySQL** 8.x
- **Flutter SDK** (démarrage) + un éditeur (VS Code / Android Studio)

### 1. Cloner le dépôt

```bash
git clone https://github.com/Nicki24/comparateur-prix-marches.git
cd comparateur-prix-marches
```

### 2. Backend (Laravel)

```bash
cd backend
composer install
copy .env.example .env        # puis configurer la base MySQL (voir plus haut)
php artisan key:generate
php artisan migrate
php artisan serve             # → http://localhost:8000
```

### 3. Frontend (Flutter)

```bash
cd frontend
flutter pub get
flutter run                    # sur un appareil Android / émulateur / chrome
```

---

## 🔗 Liens utiles

- **Dépôt GitHub** : https://github.com/Nicki24/comparateur-prix-marches
- **Documentation Flutter** : https://docs.flutter.dev/
- **Documentation Laravel** : https://laravel.com/docs
- **SDK Flutter (Windows)** : https://docs.flutter.dev/get-started/install/windows
- **Téléchargement Composer** : https://getcomposer.org/download/
- **Téléchargement MySQL** : https://dev.mysql.com/downloads/

---

## 📝 Notes techniques importantes

- **Backend** : API REST fonctionnelle (20 routes) + 16 tests ; **Frontend** : application Flutter fonctionnelle (consultation, contribution, admin) + 7 tests.
- Le fichier `.env` du backend **ne doit jamais être commité** (il contient les identifiants de la base). Il est déjà exclu via `.gitignore`.
- Les identifiants de base de données ci-dessus ne sont valables qu'en environnement local de développement.
- **Jeton de session** : stocké localement via `shared_preferences` ; le jeton Sanctum est révoqué côté serveur à la déconnexion.

---

*Application pédagogique réalisée dans le cadre d'un mémoire de fin d'études.*
