<?php

namespace App\Exceptions;

use RuntimeException;

/**
 * Fusion refusée : des relevés du doublon existent déjà sur la cible
 * (même contributeur, même jour), la contrainte d'unicité l'interdit.
 */
class FusionEnConflitException extends RuntimeException
{
    public function __construct(public readonly int $conflits)
    {
        parent::__construct("$conflits relevé(s) en conflit");
    }
}
