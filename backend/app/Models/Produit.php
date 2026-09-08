<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Casts;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['nom', 'unite_mesure', 'categorie', 'actif'])]
#[Casts(actif: 'boolean')]
class Produit extends Model
{
    protected $table = 'produits';

    public function relevesPrix(): HasMany
    {
        return $this->hasMany(RelevePrix::class);
    }
}
