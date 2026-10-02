<?php

namespace App\Services\Assistant;

/**
 * Contrat commun à tous les fournisseurs d'IA (Gemini, OpenRouter…).
 * Ajouter un fournisseur = écrire une classe qui implémente ce contrat.
 */
interface FournisseurIA
{
    public function nom(): string;

    /** Clé présente dans la configuration ? */
    public function estConfigure(): bool;

    /**
     * Répond au dernier message en appelant les outils autant que
     * nécessaire. Lève une exception en cas d'échec du fournisseur.
     *
     * @param  list<array{role: 'user'|'assistant', content: string}>  $historique
     */
    public function repondre(string $systeme, array $historique, AssistantOutils $outils): string;
}
