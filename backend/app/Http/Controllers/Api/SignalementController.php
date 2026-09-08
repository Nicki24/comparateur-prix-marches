<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\SignalementResource;
use App\Models\Signalement;
use App\Services\AnomalieDetectionService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class SignalementController extends Controller
{
    public function __construct(
        private readonly AnomalieDetectionService $anomalieService,
    ) {}

    public function index(): AnonymousResourceCollection
    {
        $signalements = Signalement::with(['releve.produit', 'releve.marche'])
            ->orderByDesc('date_detection')
            ->get();

        return SignalementResource::collection($signalements);
    }

    /**
     * Déclenche manuellement la détection des prix obsolètes (admin).
     */
    public function detecterObsoletes(): JsonResponse
    {
        $compte = $this->anomalieService->detecterPrixObsoletes();

        return response()->json([
            'message' => "Détection de prix obsolètes terminée. $compte relevé(s) signalé(s).",
            'nombre_signalements' => $compte,
        ]);
    }
}
