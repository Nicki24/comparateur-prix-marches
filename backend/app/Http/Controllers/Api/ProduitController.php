<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreProduitRequest;
use App\Http\Requests\UpdateProduitRequest;
use App\Http\Resources\ProduitResource;
use App\Models\Produit;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class ProduitController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $produits = Produit::query()
            ->when($request->boolean('tout'), fn ($q) => $q, fn ($q) => $q->where('actif', true))
            ->orderBy('nom')
            ->get();

        return ProduitResource::collection($produits);
    }

    public function store(StoreProduitRequest $request): JsonResponse
    {
        $produit = Produit::create($request->validated());

        return response()->json(new ProduitResource($produit), 201);
    }

    public function show(Produit $produit): ProduitResource
    {
        return new ProduitResource($produit);
    }

    public function update(UpdateProduitRequest $request, Produit $produit): ProduitResource
    {
        $produit->update($request->validated());

        return new ProduitResource($produit);
    }

    /**
     * Suppression logique : actif = false.
     */
    public function destroy(Produit $produit): JsonResponse
    {
        $produit->update(['actif' => false]);

        return response()->json(['message' => 'Produit désactivé.']);
    }
}
