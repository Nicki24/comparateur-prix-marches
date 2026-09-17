<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['releve_id', 'type_anomalie'])]
class Signalement extends Model
{
    protected $table = 'signalements';

    public $timestamps = false;

    protected function casts(): array
    {
        return [
            'date_detection' => 'datetime',
        ];
    }

    public function releve(): BelongsTo
    {
        return $this->belongsTo(RelevePrix::class, 'releve_id');
    }
}
