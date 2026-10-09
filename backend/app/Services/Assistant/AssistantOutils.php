<?php

namespace App\Services\Assistant;

use App\Models\Marche;
use App\Models\Produit;
use App\Models\RelevePrix;
use App\Models\Signalement;
use App\Models\User;
use Illuminate\Support\Carbon;

/**
 * Outils mis à disposition de l'IA : lecture seule sur les données de la
 * plateforme. L'IA ne connaît aucun prix par elle-même, elle doit passer
 * par ces fonctions, ce qui évite les chiffres inventés.
 */
class AssistantOutils
{
    /** Rayon de recherche par défaut et maximal (km) pour marches_proches. */
    private const RAYON_DEFAUT_KM = 10;

    private const RAYON_MAX_KM = 50;

    /** @var array{0: float, 1: float}|null [latitude, longitude] */
    private ?array $position = null;

    /** Position de l'utilisateur pour la requête en cours (ou null). */
    public function definirPosition(?array $position): void
    {
        $this->position = $position;
    }

    /**
     * Déclarations neutres (JSON Schema), traduites par chaque fournisseur.
     *
     * @return list<array{name: string, description: string, parameters: array}>
     */
    public function definitions(): array
    {
        return [
            [
                'name' => 'rechercher_produits',
                'description' => 'Trouve les produits suivis (id, nom, unité, catégorie). '
                    .'À appeler en premier pour obtenir le produit_id. Sans texte : liste tout.',
                'parameters' => [
                    'type' => 'object',
                    'properties' => [
                        'recherche' => ['type' => 'string', 'description' => 'Mot-clé, ex. « riz », « huile ».'],
                    ],
                ],
            ],
            [
                'name' => 'lister_marches',
                'description' => 'Liste les marchés actifs (id, nom, ville), filtrables par ville ou nom.',
                'parameters' => [
                    'type' => 'object',
                    'properties' => [
                        'ville' => ['type' => 'string', 'description' => 'Ville ou nom de marché, ex. « Toliara ».'],
                    ],
                ],
            ],
            [
                'name' => 'comparer_prix',
                'description' => 'Dernier prix validé du produit dans chaque marché, du moins cher au plus cher, '
                    .'avec la date du relevé et l’écart en % par rapport au moins cher.',
                'parameters' => [
                    'type' => 'object',
                    'properties' => [
                        'produit_id' => ['type' => 'integer'],
                        'ville' => ['type' => 'string', 'description' => 'Optionnel : limiter à une ville.'],
                    ],
                    'required' => ['produit_id'],
                ],
            ],
            [
                'name' => 'marches_proches',
                'description' => 'Marchés les plus proches de la position de l’utilisateur, avec la distance en km. '
                    .'Avec produit_id : dernier prix du produit dans chacun de ces marchés, '
                    .'trié du moins cher au plus cher. Renvoie position_inconnue si l’utilisateur '
                    .'n’a pas partagé sa position.',
                'parameters' => [
                    'type' => 'object',
                    'properties' => [
                        'produit_id' => ['type' => 'integer', 'description' => 'Optionnel : comparer ce produit.'],
                        'rayon_km' => ['type' => 'number', 'description' => 'Rayon de recherche (défaut 10, max 50).'],
                    ],
                ],
            ],
            [
                'name' => 'historique_prix',
                'description' => 'Évolution du prix moyen d’un produit (par date) sur une période, '
                    .'avec la variation en % entre le premier et le dernier point.',
                'parameters' => [
                    'type' => 'object',
                    'properties' => [
                        'produit_id' => ['type' => 'integer'],
                        'marche_id' => ['type' => 'integer', 'description' => 'Optionnel : un seul marché.'],
                        'jours' => ['type' => 'integer', 'description' => 'Période en jours (défaut 60, max 365).'],
                    ],
                    'required' => ['produit_id'],
                ],
            ],
            [
                'name' => 'statistiques_plateforme',
                'description' => 'Chiffres globaux : nombre de relevés, marchés, produits, contributeurs, '
                    .'signalements et date de la dernière mise à jour.',
                'parameters' => ['type' => 'object', 'properties' => new \stdClass],
            ],
        ];
    }

    /**
     * Exécute un outil. Ne lève jamais : une erreur est renvoyée à l'IA
     * sous forme de données pour qu'elle puisse l'expliquer.
     */
    public function executer(string $nom, array $args): array
    {
        try {
            return match ($nom) {
                'rechercher_produits' => $this->rechercherProduits((string) ($args['recherche'] ?? '')),
                'lister_marches' => $this->listerMarches((string) ($args['ville'] ?? '')),
                'comparer_prix' => $this->comparerPrix((int) ($args['produit_id'] ?? 0), (string) ($args['ville'] ?? '')),
                'historique_prix' => $this->historiquePrix(
                    (int) ($args['produit_id'] ?? 0),
                    isset($args['marche_id']) ? (int) $args['marche_id'] : null,
                    (int) ($args['jours'] ?? 60),
                ),
                'statistiques_plateforme' => $this->statistiques(),
                'marches_proches' => $this->marchesProches(
                    isset($args['produit_id']) ? (int) $args['produit_id'] : null,
                    (float) ($args['rayon_km'] ?? self::RAYON_DEFAUT_KM),
                ),
                default => ['erreur' => "Outil inconnu : $nom"],
            };
        } catch (\Throwable $e) {
            report($e);

            return ['erreur' => 'Impossible de lire les données pour le moment.'];
        }
    }

    private function rechercherProduits(string $recherche): array
    {
        $produits = Produit::where('actif', true)
            ->when($recherche !== '', fn ($q) => $q->where(fn ($q) => $q
                ->where('nom', 'like', "%$recherche%")
                ->orWhere('categorie', 'like', "%$recherche%")))
            ->orderBy('nom')
            ->limit(40)
            ->get(['id', 'nom', 'unite_mesure', 'categorie']);

        return [
            'produits' => $produits->map(fn (Produit $p) => [
                'id' => $p->id,
                'nom' => $p->nom,
                'unite' => $p->unite_mesure,
                'categorie' => $p->categorie,
            ])->all(),
        ];
    }

    private function listerMarches(string $ville): array
    {
        $marches = Marche::where('actif', true)
            ->when($ville !== '', fn ($q) => $q->where(fn ($q) => $q
                ->where('localisation', 'like', "%$ville%")
                ->orWhere('nom', 'like', "%$ville%")))
            ->orderBy('nom')
            ->limit(40)
            ->get(['id', 'nom', 'localisation', 'quartier']);

        return [
            'marches' => $marches->map(fn (Marche $m) => [
                'id' => $m->id,
                'nom' => $m->nom,
                'quartier' => $m->quartier,
                'ville' => $m->localisation,
            ])->all(),
        ];
    }

    private function comparerPrix(int $produitId, string $ville): array
    {
        $produit = Produit::find($produitId);
        if (! $produit) {
            return ['erreur' => "Aucun produit avec l'id $produitId."];
        }

        $marches = Marche::where('actif', true)
            ->when($ville !== '', fn ($q) => $q->where('localisation', 'like', "%$ville%"))
            ->get(['id', 'nom', 'localisation']);

        $lignes = $marches->map(function (Marche $marche) use ($produit) {
            $dernier = RelevePrix::where('produit_id', $produit->id)
                ->where('marche_id', $marche->id)
                ->where('statut', 'valide')
                ->orderByDesc('date_releve')
                ->first(['valeur', 'date_releve']);

            return $dernier ? [
                'marche_id' => $marche->id,
                'marche' => $marche->nom,
                'ville' => $marche->localisation,
                'prix_ariary' => (float) $dernier->valeur,
                'date_releve' => $dernier->date_releve->toDateString(),
            ] : null;
        })->filter()->sortBy('prix_ariary')->values();

        $min = $lignes->first()['prix_ariary'] ?? null;

        return [
            'produit' => ['id' => $produit->id, 'nom' => $produit->nom, 'unite' => $produit->unite_mesure],
            'nb_marches_avec_prix' => $lignes->count(),
            'prix_par_marche' => $lignes->map(fn ($l) => [
                ...$l,
                'ecart_vs_moins_cher_pct' => $min ? round(($l['prix_ariary'] - $min) / $min * 100, 1) : null,
            ])->all(),
        ];
    }

    private function marchesProches(?int $produitId, float $rayonKm): array
    {
        if ($this->position === null) {
            return ['erreur' => 'position_inconnue'];
        }
        [$lat, $lng] = $this->position;
        $rayonKm = min(max($rayonKm, 1), self::RAYON_MAX_KM);

        $produit = $produitId ? Produit::find($produitId) : null;
        if ($produitId && ! $produit) {
            return ['erreur' => "Aucun produit avec l'id $produitId."];
        }

        $proches = Marche::where('actif', true)
            ->whereNotNull('latitude')
            ->whereNotNull('longitude')
            ->get(['id', 'nom', 'localisation', 'quartier', 'latitude', 'longitude'])
            ->map(fn (Marche $m) => [
                'marche' => $m,
                'distance_km' => round(self::distanceKm($lat, $lng, $m->latitude, $m->longitude), 1),
            ])
            ->filter(fn (array $l) => $l['distance_km'] <= $rayonKm)
            ->sortBy('distance_km')
            ->values();

        $lignes = $proches->map(function (array $l) use ($produit) {
            $m = $l['marche'];
            $ligne = [
                'marche_id' => $m->id,
                'marche' => $m->nom,
                'quartier' => $m->quartier,
                'ville' => $m->localisation,
                'distance_km' => $l['distance_km'],
            ];
            if (! $produit) {
                return $ligne;
            }
            $dernier = RelevePrix::where('produit_id', $produit->id)
                ->where('marche_id', $m->id)
                ->where('statut', 'valide')
                ->orderByDesc('date_releve')
                ->first(['valeur', 'date_releve']);

            return $dernier ? [
                ...$ligne,
                'prix_ariary' => (float) $dernier->valeur,
                'date_releve' => $dernier->date_releve->toDateString(),
            ] : null;
        })->filter()->values();

        if ($produit) {
            $lignes = $lignes->sortBy([['prix_ariary', 'asc'], ['distance_km', 'asc']])->values();
        }

        return [
            'rayon_km' => $rayonKm,
            'produit' => $produit ? ['id' => $produit->id, 'nom' => $produit->nom, 'unite' => $produit->unite_mesure] : null,
            // Marchés que l'admin n'a pas encore placés sur la carte.
            'nb_marches_sans_position' => Marche::where('actif', true)->whereNull('latitude')->count(),
            'marches' => $lignes->take(10)->all(),
        ];
    }

    /** Distance à vol d'oiseau (formule de haversine), en kilomètres. */
    public static function distanceKm(float $lat1, float $lng1, float $lat2, float $lng2): float
    {
        $rayonTerre = 6371.0;
        $dLat = deg2rad($lat2 - $lat1);
        $dLng = deg2rad($lng2 - $lng1);
        $a = sin($dLat / 2) ** 2 + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLng / 2) ** 2;

        return $rayonTerre * 2 * atan2(sqrt($a), sqrt(1 - $a));
    }

    private function historiquePrix(int $produitId, ?int $marcheId, int $jours): array
    {
        $produit = Produit::find($produitId);
        if (! $produit) {
            return ['erreur' => "Aucun produit avec l'id $produitId."];
        }
        $jours = max(1, min(365, $jours));

        $points = RelevePrix::where('produit_id', $produitId)
            ->where('statut', 'valide')
            ->when($marcheId, fn ($q) => $q->where('marche_id', $marcheId))
            ->where('date_releve', '>=', Carbon::today()->subDays($jours))
            ->selectRaw('date_releve, AVG(valeur) as moyenne, MIN(valeur) as min, MAX(valeur) as max')
            ->groupBy('date_releve')
            ->orderBy('date_releve')
            ->get()
            ->map(fn ($r) => [
                'date' => Carbon::parse($r->date_releve)->toDateString(),
                'moyenne' => round((float) $r->moyenne),
                'min' => (float) $r->min,
                'max' => (float) $r->max,
            ]);

        // Au-delà de 30 points, on échantillonne pour rester concis.
        if ($points->count() > 30) {
            $pas = (int) ceil($points->count() / 30);
            $points = $points->filter(fn ($p, $i) => $i % $pas === 0 || $i === $points->count() - 1)->values();
        }

        $premier = $points->first()['moyenne'] ?? null;
        $dernier = $points->last()['moyenne'] ?? null;

        return [
            'produit' => ['id' => $produit->id, 'nom' => $produit->nom, 'unite' => $produit->unite_mesure],
            'periode_jours' => $jours,
            'variation_pct' => $premier ? round(($dernier - $premier) / $premier * 100, 1) : null,
            'points' => $points->all(),
        ];
    }

    private function statistiques(): array
    {
        $dernier = RelevePrix::where('statut', 'valide')->orderByDesc('date_releve')->first(['date_releve']);

        return [
            'nb_releves' => RelevePrix::count(),
            'nb_marches_actifs' => Marche::where('actif', true)->count(),
            'nb_produits_actifs' => Produit::where('actif', true)->count(),
            'nb_contributeurs' => User::where('role', 'contributeur')->count(),
            'nb_signalements' => Signalement::count(),
            'derniere_mise_a_jour' => $dernier?->date_releve?->toDateString(),
        ];
    }
}
