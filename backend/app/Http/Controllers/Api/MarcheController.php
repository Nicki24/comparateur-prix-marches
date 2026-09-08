<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreMarcheRequest;
use App\Http\Requests\UpdateMarcheRequest;
use App\Http\Resources\MarcheResource;
use App\Models\Marche;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class MarcheController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $marches = Marche::query()
            ->when($request->boolean('tout'), fn ($q) => $q, fn ($q) => $q->where('actif', true))
            ->orderBy('nom')
            ->get();

        return MarcheResource::collection($marches);
    }

    public function store(StoreMarcheRequest $request): JsonResponse
    {
        $marche = Marche::create($request->validated());

        return response()->json(new MarcheResource($marche), 201);
    }

    public function show(Marche $marche): MarcheResource
    {
        return new MarcheResource($marche);
    }

    public function update(UpdateMarcheRequest $request, Marche $marche): MarcheResource
    {
        $marche->update($request->validated());

        return new MarcheResource($marche);
    }

    /**
     * Suppression logique : jamais de DELETE physique, simplement actif = false.
     */
    public function destroy(Marche $marche): JsonResponse
    {
        $marche->update(['actif' => false]);

        return response()->json(['message' => 'Marché désactivé.']);
    }
}
