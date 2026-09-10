<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Marche;
use App\Models\Produit;
use App\Models\RelevePrix;
use App\Models\Signalement;
use App\Models\User;
use Illuminate\Http\JsonResponse;

class StatistiqueController extends Controller
{
    /**
     * Vue de synthèse pour le tableau de bord : compteurs généraux
     * et date de la dernière mise à jour. Consultation publique.
     */
    public function synthese(): JsonResponse
    {
        $dernierReleve = RelevePrix::query()
            ->where('statut', '=', 'valide')
            ->orderByDesc('date_releve')
            ->first();

        return response()->json([
            'nb_releves' => RelevePrix::count(),
            'nb_marches_actifs' => Marche::where('actif', true)->count(),
            'nb_produits_actifs' => Produit::where('actif', true)->count(),
            'nb_contributeurs' => User::where('role', 'contributeur')->count(),
            'nb_signalements' => Signalement::count(),
            'derniere_mise_a_jour' => $dernierReleve?->date_releve?->toDateString(),
        ]);
    }
}
