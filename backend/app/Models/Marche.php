<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Casts;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['nom', 'localisation', 'description', 'actif'])]
#[Casts(actif: 'boolean')]
class Marche extends Model
{
    protected $table = 'marches';

    public function relevesPrix(): HasMany
    {
        return $this->hasMany(RelevePrix::class);
    }
}
