<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['nom', 'localisation', 'quartier', 'latitude', 'longitude', 'description', 'actif'])]
class Marche extends Model
{
    protected $table = 'marches';

    protected $attributes = [
        'actif' => true,
    ];

    protected function casts(): array
    {
        return [
            'actif' => 'boolean',
            'latitude' => 'float',
            'longitude' => 'float',
        ];
    }

    public function aUnePosition(): bool
    {
        return $this->latitude !== null && $this->longitude !== null;
    }

    public function relevesPrix(): HasMany
    {
        return $this->hasMany(RelevePrix::class);
    }
}
