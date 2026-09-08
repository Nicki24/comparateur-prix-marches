<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['nom', 'localisation', 'description', 'actif'])]
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
        ];
    }

    public function relevesPrix(): HasMany
    {
        return $this->hasMany(RelevePrix::class);
    }
}
