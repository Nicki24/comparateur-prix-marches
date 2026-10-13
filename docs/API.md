# API REST MarketScope

URL de base : `https://marketscope-api.wasmer.app/api` (production) ou
`http://localhost:8000/api` (développement). Toutes les réponses sont en JSON.

Les routes protégées attendent l'en-tête `Authorization: Bearer <jeton>`, obtenu à la
connexion ou à l'inscription (Laravel Sanctum, jeton valable 30 jours).

**Légende des accès** : 🌐 public · 🔑 compte connecté · 🛡️ administrateur

## Authentification

| Méthode | Route | Accès | Description |
|---|---|---|---|
| `POST` | `/register` | 🌐 | Crée un compte **contributeur** et renvoie un jeton. Limité à 10 inscriptions / heure par IP. |
| `POST` | `/login` | 🌐 | Connexion. Limitée à 5 essais / minute par couple e-mail + IP. |
| `POST` | `/logout` | 🔑 | Révoque le jeton courant. |
| `GET` | `/user` | 🔑 | Profil de l'utilisateur connecté. |

## Consultation

| Méthode | Route | Accès | Description |
|---|---|---|---|
| `GET` | `/marches` | 🌐 | Marchés actifs (`?tout=1` : inclut les désactivés). Inclut quartier et coordonnées GPS. |
| `GET` | `/marches/{id}` | 🌐 | Détail d'un marché. |
| `GET` | `/produits` | 🌐 | Produits suivis. |
| `GET` | `/produits/{id}` | 🌐 | Détail d'un produit. |
| `GET` | `/produits/{id}/comparaison` | 🌐 | Dernier prix par marché, trié, avec l'écart en % par rapport au moins cher. |
| `GET` | `/produits/{id}/historique` | 🌐 | Points d'évolution du prix (`mode=moyenne\|min\|max`, filtre `marche_id`). |
| `GET` | `/releves` | 🌐 | Relevés paginés (`per_page` plafonné à 100). |
| `GET` | `/stats` | 🌐 | Chiffres de la plateforme (relevés, marchés, produits, contributeurs). |

## Contribution

| Méthode | Route | Accès | Description |
|---|---|---|---|
| `POST` | `/releves` | 🔑 | Saisit un relevé. Refusé si le contributeur a déjà relevé ce produit dans ce marché ce jour-là. Prix > 0, date non future. Signalé automatiquement s'il s'écarte de plus de 40 % de la moyenne récente. |
| `GET` | `/mes-releves` | 🔑 | Historique personnel, en lecture seule (les relevés sont immuables). |

## Assistant IA

| Méthode | Route | Accès | Description |
|---|---|---|---|
| `POST` | `/assistant` | 🌐 | Question en langage naturel. Corps : `messages` (historique, 20 max) et, en option, `position` (`latitude`, `longitude`) partagée par l'utilisateur. Limité par minute et par jour. |

L'assistant ne connaît aucun prix par lui-même : il interroge la base via des outils en
lecture seule (`rechercher_produits`, `lister_marches`, `comparer_prix`, `historique_prix`,
`marches_proches`, `statistiques_plateforme`). La position éventuelle sert au seul calcul des
distances et n'est jamais enregistrée.

## Administration

| Méthode | Route | Accès | Description |
|---|---|---|---|
| `POST` | `/marches` | 🛡️ | Crée un marché (nom, ville, quartier, latitude/longitude facultatives). |
| `PUT` | `/marches/{id}` | 🛡️ | Modifie un marché (dont `actif: true` pour le réactiver). |
| `DELETE` | `/marches/{id}` | 🛡️ | **Désactive** le marché (suppression logique). |
| `DELETE` | `/marches/{id}/definitif` | 🛡️ | Suppression définitive, **refusée (409)** si des relevés y sont liés. |
| `POST` | `/marches/{id}/fusionner` | 🛡️ | Déplace tous les relevés vers un autre marché, puis supprime le doublon. |
| `POST` | `/produits` | 🛡️ | Crée un produit. |
| `PUT` | `/produits/{id}` | 🛡️ | Modifie / réactive un produit. |
| `DELETE` | `/produits/{id}` | 🛡️ | Désactive un produit. |
| `DELETE` | `/produits/{id}/definitif` | 🛡️ | Suppression définitive (409 si des relevés y sont liés). |
| `POST` | `/produits/{id}/fusionner` | 🛡️ | Fusionne un produit doublon dans un autre. |
| `GET` | `/signalements` | 🛡️ | Relevés signalés (prix anormaux, obsolètes). |
| `POST` | `/signalements/detecter-obsoletes` | 🛡️ | Marque les relevés de plus de 14 jours comme obsolètes. |
| `GET` | `/releves/export` | 🛡️ | Export CSV de tous les relevés (cellules protégées contre l'injection de formules). |

## Maintenance (tâches Wasmer)

| Méthode | Route | Accès | Description |
|---|---|---|---|
| `POST` | `/systeme/installer` | 🌐 | Migrations + compte admin + produits de départ. Idempotent, ne reçoit aucune donnée, ne renvoie qu'un statut, limité à 3 appels / minute. |
| `POST` | `/systeme/prix-obsoletes` | 🌐 | Tâche nocturne de détection des relevés obsolètes. Mêmes garanties. |

Ces deux routes sont appelées par les tâches définies dans [`backend/app.yaml`](../backend/app.yaml) ;
voir [DEPLOIEMENT.md](DEPLOIEMENT.md) pour la raison de ce choix.

## Codes de réponse courants

| Code | Signification |
|---|---|
| `401` | Jeton absent, invalide ou expiré — se reconnecter. |
| `403` | Action réservée aux administrateurs. |
| `409` | Suppression impossible : des relevés dépendent de l'élément. |
| `422` | Données invalides (le détail par champ est dans `errors`). |
| `429` | Trop de requêtes — patienter avant de réessayer. |
