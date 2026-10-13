# Déploiement de MarketScope

MarketScope se déploie en deux parties :

1. **L'API Laravel** sur [Wasmer Edge](https://wasmer.io) — hébergement gratuit, HTTPS et
   base MySQL inclus : <https://marketscope-api.wasmer.app>.
2. **L'application Android**, compilée en APK signé et distribuée directement
   (WhatsApp, Google Drive…) aux administrateurs et contributeurs.

---

## 1. L'API sur Wasmer Edge

### Pourquoi ces choix

| Choix | Raison |
|---|---|
| Wasmer Edge | Offre gratuite sans carte bancaire, MySQL géré, HTTPS automatique. |
| `config.platform.php = 8.3.4` dans `composer.json` | Wasmer ne fournit officiellement que **PHP 8.3** : Composer installe donc des dépendances compatibles (Symfony 7.4 LTS, accepté par Laravel 13). |
| Déploiement en ligne de commande | Le code Laravel est dans `backend/` (pas à la racine du dépôt), que l'import GitHub de Wasmer ne sait pas construire. |
| Tâches en `fetch` HTTP | Les tâches `execute` de Wasmer ne reçoivent ni les variables ni les secrets de l'app : elles appellent donc l'API (`/api/systeme/*`), qui s'exécute avec sa vraie configuration. |

### Fichiers concernés

| Fichier | Rôle |
|---|---|
| [`backend/wasmer.toml`](../backend/wasmer.toml) | Paquet : PHP 8.3, serveur web sur `public/`, commande `artisan`. |
| [`backend/app.yaml`](../backend/app.yaml) | App : variables non secrètes, base MySQL, tâches (installation après déploiement, relevés obsolètes chaque nuit). |
| [`scripts/deployer-backend.sh`](../scripts/deployer-backend.sh) | Construit et déploie depuis le **dernier commit** (le `.env` local ne part jamais). |
| [`backend/app/Console/Commands/InstallerProduction.php`](../backend/app/Console/Commands/InstallerProduction.php) | Migrations + compte admin + produits de départ, sans aucune donnée de test. |

### Premier déploiement

1. Installer l'outil Wasmer et se connecter (le navigateur s'ouvre) :

   ```bash
   wasmer login
   ```

2. Déployer depuis la racine du dépôt (Git Bash) :

   ```bash
   ./scripts/deployer-backend.sh
   ```

   Wasmer crée l'app et sa base MySQL, puis applique les migrations.

3. Dans le tableau de bord Wasmer (*Settings → Environment Vars*), ajouter les **secrets** :

   | Secret | Valeur |
   |---|---|
   | `APP_KEY` | Résultat de `php backend/artisan key:generate --show` |
   | `APP_URL` | `https://marketscope-api.wasmer.app` |
   | `ADMIN_NAME` | Nom affiché de l'administrateur |
   | `ADMIN_EMAIL` | E-mail de connexion de l'administrateur |
   | `ADMIN_PASSWORD` | Mot de passe admin (**12 caractères minimum**) |
   | `GEMINI_API_KEY` | Clé de l'assistant IA |
   | `OPENROUTER_API_KEY` | Clé du fournisseur IA de secours (facultatif) |

   Les variables de la base (`DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USERNAME`,
   `DB_PASSWORD`) sont injectées automatiquement par Wasmer.

4. Relancer `./scripts/deployer-backend.sh` : la tâche d'installation crée le compte
   administrateur et les produits.

> ⚠️ Le compte administrateur n'est créé **qu'une seule fois**. Modifier `ADMIN_PASSWORD`
> ensuite ne change pas le mot de passe du compte existant.

### Mettre à jour l'API

```bash
git commit -am "…"            # le script déploie le dernier commit
./scripts/deployer-backend.sh
```

Les migrations en attente sont appliquées automatiquement après chaque déploiement.
Un « Save and Redeploy » depuis le tableau de bord ne relance **pas** cette tâche ; pour
la déclencher à la main :

```bash
curl -X POST https://marketscope-api.wasmer.app/api/systeme/installer
```

### Vérifier et diagnostiquer

```bash
curl https://marketscope-api.wasmer.app/api/produits                 # API en service
wasmer app logs norlandehubery/marketscope-api --from 15m            # journaux récents
```

> La page d'accueil `https://marketscope-api.wasmer.app/` est celle de Laravel : c'est
> normal, l'application n'utilise que les routes `/api/…`.

---

## 2. L'application Android (APK)

### Signature (une seule fois)

L'APK doit être signé avec **une clé qui ne changera jamais** : sans elle, impossible de
publier une mise à jour installable par-dessus la version existante.

```bash
keytool -genkeypair -v -keystore "frontend/android/marketscope.jks" -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 10000 -alias marketscope
```

Puis créer `frontend/android/key.properties` :

```properties
storeFile=../marketscope.jks
storePassword=MOT_DE_PASSE
keyAlias=marketscope
keyPassword=MOT_DE_PASSE
```

Ces deux fichiers sont **exclus du dépôt** (`frontend/android/.gitignore`). Il faut en
garder une copie de sauvegarde (clé USB, Drive) avec le mot de passe.

### Compiler

```bash
cd frontend
flutter build apk --release
```

L'APK (`build/app/outputs/flutter-apk/app-release.apk`) appelle automatiquement l'API de
production. Avant chaque nouvelle version, augmenter `version:` dans
[`frontend/pubspec.yaml`](../frontend/pubspec.yaml) (ex. `1.0.1+2`).

### Problèmes rencontrés sous Windows

| Erreur | Cause | Solution |
|---|---|---|
| `Unable to establish loopback connection` | Espaces dans le nom du dossier utilisateur (dossier temporaire Java). | Définir `TEMP`/`TMP` vers un chemin simple, ex. `C:\gtmp`. |
| `NDK … did not have a source.properties file` | Téléchargement du NDK interrompu. | Installer **NDK (Side by side) 26.3.11579264** depuis Android Studio (*SDK Manager → SDK Tools*). |
| `Could not close incremental caches` | Projet sur `F:` et cache Pub sur `C:`. | `kotlin.incremental=false` dans `frontend/android/gradle.properties` (déjà fait). |

### Distribuer

| Moyen | Pour qui |
|---|---|
| **APK direct** (WhatsApp, Drive) | Administrateurs et contributeurs pendant la phase de collecte. Autoriser une fois « installer des applis inconnues ». |
| Firebase App Distribution | Groupe de testeurs avec mises à jour notifiées. |
| Google Play Store | Grand public, plus tard (compte développeur à 25 $, test fermé obligatoire pour un nouveau compte personnel). |

Les contributeurs créent leur compte dans l'application (*Profil → Créer un compte*) :
ils sont **contributeurs** par défaut. Seul le compte défini par `ADMIN_EMAIL` est
administrateur.
