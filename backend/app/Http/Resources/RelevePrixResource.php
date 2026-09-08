<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class RelevePrixResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'valeur' => (float) $this->valeur,
            'date_releve' => $this->date_releve?->toDateString(),
            'commentaire' => $this->commentaire,
            'statut' => $this->statut,
            'created_at' => $this->created_at?->toISOString(),
            'produit' => $this->whenLoaded('produit', fn () => new ProduitResource($this->produit)),
            'marche' => $this->whenLoaded('marche', fn () => new MarcheResource($this->marche)),
            'utilisateur' => $this->whenLoaded('utilisateur', fn () => new UserResource($this->utilisateur)),
            'signalements' => SignalementResource::collection($this->whenLoaded('signalements')),
        ];
    }
}
