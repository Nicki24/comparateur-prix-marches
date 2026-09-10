<?php

namespace App\Services;

use App\Models\RelevePrix;
use App\Models\Signalement;
use Illuminate\Support\Carbon;

class AnomalieDetectionService
{
    /**
     * Seuil d'écart (en %) au-delà duquel un prix est considéré comme anormal.
     */
    public const SEUIL_ECART = 40.0;

    /**
     * Nombre de jours au-delà duquel un relevé est considéré comme obsolète.
     */
    public const OBSOLETE_JOURS = 14;

    /**
     * Analyse un relevé fractionnaire et crée un signalement "prix_anormal"
     * si sa valeur s'écarte de plus de SEUIL_ECART % de la moyenne récente.
     */
    public function detecterPrixAnormal(RelevePrix $releve): ?Signalement
    {
        $moyenne = $this->moyenneRecentPourProduit($releve->produit_id, $releve->id);

        if ($moyenne === null || $moyenne <= 0) {
            return null;
        }

        $ecart = abs($releve->valeur - $moyenne) / $moyenne * 100;

        if ($ecart > self::SEUIL_ECART) {
            $releve->update(['statut' => 'signale']);

            return Signalement::create([
                'releve_id' => $releve->id,
                'type_anomalie' => 'prix_anormal',
            ]);
        }

        return null;
    }

    /**
     * Marque comme "prix obsolète" les relevés valides dont la date de relevé
     * est plus ancienne que OBSOLETE_JOURS jours. Retourne le nombre créé.
     */
    public function detecterPrixObsoletes(): int
    {
        $seuil = Carbon::today()->subDays(self::OBSOLETE_JOURS);

        $releves = RelevePrix::query()
            ->where('statut', '=', 'valide')
            ->where('date_releve', '<', $seuil->toDateString())
            ->get();

        $compte = 0;
        foreach ($releves as $releve) {
            $releve->update(['statut' => 'signale']);
            Signalement::create([
                'releve_id' => $releve->id,
                'type_anomalie' => 'prix_obsolete',
            ]);
            $compte++;
        }

        return $compte;
    }

    /**
     * Calcule la moyenne du même produit sur les 14 derniers jours,
     * hors relevé courant (identifié par son id) et hors relevés signalés.
     */
    protected function moyenneRecentPourProduit(int $produitId, ?int $exclureReleveId = null): ?float
    {
        $moyenne = RelevePrix::query()
            ->where('produit_id', $produitId)
            ->where('statut', '=', 'valide')
            ->where('date_releve', '>=', Carbon::today()->subDays(self::OBSOLETE_JOURS)->toDateString())
            ->when($exclureReleveId !== null, fn ($q) => $q->where('id', '!=', $exclureReleveId))
            ->avg('valeur');

        return $moyenne === null ? null : (float) $moyenne;
    }
}
