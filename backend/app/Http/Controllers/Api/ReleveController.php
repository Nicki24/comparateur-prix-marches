<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreReleveRequest;
use App\Http\Resources\RelevePrixResource;
use App\Models\RelevePrix;
use App\Services\AnomalieDetectionService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpFoundation\StreamedResponse;

class ReleveController extends Controller
{
    public function __construct(
        private readonly AnomalieDetectionService $anomalieService,
    ) {}

    public function index(Request $request): AnonymousResourceCollection
    {
        $releves = RelevePrix::query()
            ->with(['produit', 'marche', 'utilisateur'])
            ->when($request->filled('produit_id'), fn ($q) => $q->where('produit_id', $request->produit_id))
            ->when($request->filled('marche_id'), fn ($q) => $q->where('marche_id', $request->marche_id))
            ->when($request->filled('date_debut'), fn ($q) => $q->where('date_releve', '>=', $request->date_debut))
            ->when($request->filled('date_fin'), fn ($q) => $q->where('date_releve', '<=', $request->date_fin))
            ->orderByDesc('date_releve')
            ->paginate($request->integer('per_page', 50) ?: 50);

        return RelevePrixResource::collection($releves);
    }

    /**
     * Crée un relevé. Applique strictement la règle anti-doublon :
     * max 1 relevé / contributeur / produit / marché / jour.
     */
    public function store(StoreReleveRequest $request): JsonResponse
    {
        $existe = RelevePrix::where('utilisateur_id', $request->user()->id)
            ->where('produit_id', $request->produit_id)
            ->where('marche_id', $request->marche_id)
            ->where('date_releve', $request->date_releve)
            ->exists();

        if ($existe) {
            throw ValidationException::withMessages([
                'date_releve' => 'Vous avez déjà relevé ce prix pour ce produit, ce marché et cette date.',
            ]);
        }

        $releve = RelevePrix::create([
            'produit_id' => $request->produit_id,
            'marche_id' => $request->marche_id,
            'utilisateur_id' => $request->user()->id,
            'valeur' => $request->valeur,
            'date_releve' => $request->date_releve,
            'commentaire' => $request->commentaire,
            'statut' => 'valide',
        ]);

        $this->anomalieService->detecterPrixAnormal($releve);
        $releve->refresh();

        return response()->json(new RelevePrixResource($releve->load(['produit', 'marche'])), 201);
    }

    /**
     * Export CSV de tous les relevés (réservé aux administrateurs),
     * utile pour l'analyse des données dans le mémoire.
     */
    public function exportCsv(): StreamedResponse
    {
        $releves = RelevePrix::with(['produit', 'marche', 'utilisateur'])
            ->orderByDesc('date_releve')
            ->get();

        $callback = static function () use ($releves): void {
            $handle = fopen('php://output', 'w');

            // BOM UTF-8 pour une ouverture correcte dans Excel.
            fwrite($handle, "\xEF\xBB\xBF");

            fputcsv($handle, ['Date', 'Produit', 'Marché', 'Prix (Ar)', 'Unité', 'Contributeur', 'Statut'], ';');

            foreach ($releves as $releve) {
                fputcsv($handle, [
                    $releve->date_releve?->toDateString(),
                    $releve->produit->nom,
                    $releve->marche->nom,
                    number_format((float) $releve->valeur, 2, ',', ' '),
                    $releve->produit->unite_mesure,
                    $releve->utilisateur->name,
                    $releve->statut,
                ], ';');
            }

            fclose($handle);
        };

        $filename = 'releves_prix_'.now()->format('Y-m-d_His').'.csv';

        return response()->streamDownload($callback, $filename, [
            'Content-Type' => 'text/csv; charset=UTF-8',
        ]);
    }
}
