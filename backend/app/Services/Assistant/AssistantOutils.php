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
            ->get(['id', 'nom', 'localisation']);

        return [
            'marches' => $marches->map(fn (Marche $m) => [
                'id' => $m->id,
                'nom' => $m->nom,
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
