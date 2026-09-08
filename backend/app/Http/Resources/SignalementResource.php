<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SignalementResource extends JsonResource
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
            'releve_id' => $this->releve_id,
            'type_anomalie' => $this->type_anomalie,
            'date_detection' => $this->date_detection?->toISOString(),
            'releve' => $this->whenLoaded('releve', fn () => new RelevePrixResource($this->releve)),
        ];
    }
}
