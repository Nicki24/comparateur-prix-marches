<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\MarcheResource;
use App\Http\Resources\ProduitResource;
use App\Models\Marche;
use App\Models\Produit;
use App\Models\RelevePrix;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ComparisonController extends Controller
{
    /**
     * Dernier prix connu par marché pour un produit, trié du moins cher
     * au plus cher, avec l'écart en pourcentage par rapport au prix minimal.
     */
    public function dernierPrixParMarche(Request $request, Produit $produit): JsonResponse
    {
        $marches = Marche::where('actif', true)->withCount('relevesPrix')->get();

        $resultats = $marches->map(function (Marche $marche) use ($produit) {
            $dernier = RelevePrix::where('produit_id', $produit->id)
                ->where('marche_id', $marche->id)
                ->where('statut', '=', 'valide')
                ->orderByDesc('date_releve')
                ->first();

            return [
                'marche' => new MarcheResource($marche),
                'dernier_prix' => $dernier?->valeur,
                'date_dernier_releve' => $dernier?->date_releve?->toDateString(),
                'nb_releves' => $dernier ? 1 : 0,
            ];
        });

        $section = $resultats
            ->filter(fn ($r) => $r['dernier_prix'] !== null)
            ->sortBy('dernier_prix')
            ->values();

        $prixMin = $section->first()['dernier_prix'] ?? null;

        $final = $section->map(function ($r) use ($prixMin) {
            $ecart = null;
            if ($prixMin && (float) $prixMin > 0) {
                $ecart = round((floatval($r['dernier_prix']) - floatval($prixMin)) / floatval($prixMin) * 100, 2);
            }

            return [
                ...$r,
                'ecart_pourcentage' => $ecart,
            ];
        });

        return response()->json([
            'produit' => new ProduitResource($produit),
            'prix_minimum' => $prixMin ? (float) $prixMin : null,
            'prix_par_marche' => $final,
        ]);
    }

    /**
     * Historique des prix pour un produit (utile pour les graphiques fl_chart),
     * groupé par date, avec prix min/max/moyen selon le paramètre mode.
     */
    public function historique(Request $request, Produit $produit): JsonResponse
    {
        $mode = in_array($request->mode, ['min', 'max', 'moyenne'], true) ? $request->mode : 'moyenne';
        $marcheId = $request->integer('marche_id', 0) ?: null;

        $query = RelevePrix::where('produit_id', $produit->id)
            ->where('statut', '=', 'valide')
            ->when($marcheId, fn ($q) => $q->where('marche_id', $marcheId));

        $rows = (clone $query)
            ->selectRaw('date_releve, MIN(valeur) as min, MAX(valeur) as max, AVG(valeur) as moyenne, COUNT(*) as nb')
            ->groupBy('date_releve')
            ->orderBy('date_releve')
            ->get();

        $points = $rows->map(function ($row) use ($mode) {
            return [
                'date' => $row->date_releve,
                'valeur' => match ($mode) {
                    'min' => (float) $row->min,
                    'max' => (float) $row->max,
                    default => round((float) $row->moyenne, 2),
                },
            ];
        });

        return response()->json([
            'produit' => new ProduitResource($produit),
            'mode' => $mode,
            'points' => $points,
        ]);
    }
}
