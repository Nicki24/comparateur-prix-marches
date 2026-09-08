<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['produit_id', 'marche_id', 'utilisateur_id', 'valeur', 'date_releve', 'commentaire', 'statut'])]
class RelevePrix extends Model
{
    protected $table = 'releves_prix';

    public const UPDATED_AT = null;

    protected function casts(): array
    {
        return [
            'date_releve' => 'date',
            'valeur' => 'decimal:2',
            'created_at' => 'datetime',
        ];
    }

    public function produit(): BelongsTo
    {
        return $this->belongsTo(Produit::class);
    }

    public function marche(): BelongsTo
    {
        return $this->belongsTo(Marche::class);
    }

    public function utilisateur(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function signalements(): HasMany
    {
        return $this->hasMany(Signalement::class);
    }
}
