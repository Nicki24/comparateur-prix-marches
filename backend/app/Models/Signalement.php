<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Casts;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['releve_id', 'type_anomalie'])]
#[Casts(date_detection: 'datetime')]
class Signalement extends Model
{
    protected $table = 'signalements';

    public const UPDATED_AT = null;

    public function releve(): BelongsTo
    {
        return $this->belongsTo(RelevePrix::class);
    }
}
