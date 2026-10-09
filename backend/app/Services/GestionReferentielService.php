<?php

namespace App\Services;

use App\Exceptions\FusionEnConflitException;
use App\Models\Marche;
use App\Models\RelevePrix;
use App\Models\Signalement;
use App\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

/**
 * Suppression définitive et fusion des marchés / produits.
 *
 * Règle : l'historique des prix ne se perd jamais. Un élément qui porte
 * des relevés ne peut pas être supprimé (il faut le désactiver), et une
 * fusion déplace tous les relevés vers l'élément conservé avant de
 * supprimer le doublon. Chaque opération est journalisée.
 */
class GestionReferentielService
{
    /**
     * Nombre de relevés et de signalements rattachés à l'élément.
     *
     * @return array{releves: int, signalements: int}
     */
    public function liens(Model $element): array
    {
        $colonne = $this->colonne($element);

        return [
            'releves' => RelevePrix::where($colonne, $element->getKey())->count(),
            'signalements' => Signalement::whereHas(
                'releve',
                fn ($q) => $q->where($colonne, $element->getKey())
            )->count(),
        ];
    }

    /**
     * Message de refus quand l'élément porte encore de l'historique.
     */
    public function messageRefus(Model $element, array $liens): string
    {
        $parts = [$this->pluriel($liens['releves'], 'relevé de prix', 'relevés de prix')];
        if ($liens['signalements'] > 0) {
            $parts[] = $this->pluriel($liens['signalements'], 'signalement', 'signalements');
        }

        $sujet = $element instanceof Marche ? 'Ce marché' : 'Ce produit';
        $autre = $element instanceof Marche ? 'un autre marché' : 'un autre produit';

        return "$sujet a ".implode(' et ', $parts)
            ." : désactivez-le plutôt, ou fusionnez-le avec $autre.";
    }

    /**
     * Supprime définitivement l'élément s'il n'a aucun relevé.
     *
     * @return array{releves: int, signalements: int}|null les liens bloquants, ou null si supprimé
     */
    public function supprimer(Model $element, User $admin): ?array
    {
        return DB::transaction(function () use ($element, $admin) {
            // Verrou : aucun relevé ne peut être ajouté entre le comptage et la suppression.
            $element->newQuery()->whereKey($element->getKey())->lockForUpdate()->first();

            $liens = $this->liens($element);
            if ($liens['releves'] > 0) {
                return $liens;
            }

            $element->delete();

            Log::info('Administration : suppression définitive', [
                'type' => $this->type($element),
                'id' => $element->getKey(),
                'nom' => $element->nom,
                'admin_id' => $admin->id,
                'admin_email' => $admin->email,
                'date' => now()->toIso8601String(),
            ]);

            return null;
        });
    }

    /**
     * Relevés du doublon qui entreraient en collision avec ceux de la cible
     * (même contributeur, même produit/marché, même jour).
     */
    public function conflits(Model $doublon, Model $cible): int
    {
        $colonne = $this->colonne($doublon);
        $autre = $colonne === 'marche_id' ? 'produit_id' : 'marche_id';

        return RelevePrix::query()
            ->where($colonne, $doublon->getKey())
            ->whereExists(function ($q) use ($colonne, $autre, $cible) {
                $q->selectRaw('1')
                    ->from('releves_prix as c')
                    ->where("c.$colonne", $cible->getKey())
                    ->whereColumn('c.utilisateur_id', 'releves_prix.utilisateur_id')
                    ->whereColumn("c.$autre", "releves_prix.$autre")
                    ->whereColumn('c.date_releve', 'releves_prix.date_releve');
            })
            ->count();
    }

    /**
     * Déplace tous les relevés du doublon vers la cible puis supprime le doublon,
     * dans une seule transaction.
     *
     * @return int nombre de relevés déplacés
     *
     * @throws FusionEnConflitException si des relevés sont en conflit avec la cible
     */
    public function fusionner(Model $doublon, Model $cible, User $admin): int
    {
        $colonne = $this->colonne($doublon);

        return DB::transaction(function () use ($doublon, $cible, $admin, $colonne) {
            $doublon->newQuery()
                ->whereKey([$doublon->getKey(), $cible->getKey()])
                ->lockForUpdate()
                ->get();

            $conflits = $this->conflits($doublon, $cible);
            if ($conflits > 0) {
                throw new FusionEnConflitException($conflits);
            }

            $deplaces = RelevePrix::where($colonne, $doublon->getKey())
                ->update([$colonne => $cible->getKey()]);

            $doublon->delete();

            Log::info('Administration : fusion', [
                'type' => $this->type($doublon),
                'doublon_id' => $doublon->getKey(),
                'doublon_nom' => $doublon->nom,
                'cible_id' => $cible->getKey(),
                'cible_nom' => $cible->nom,
                'releves_deplaces' => $deplaces,
                'admin_id' => $admin->id,
                'admin_email' => $admin->email,
                'date' => now()->toIso8601String(),
            ]);

            return $deplaces;
        });
    }

    public function pluriel(int $n, string $singulier, string $pluriel): string
    {
        return $n.' '.($n > 1 ? $pluriel : $singulier);
    }

    private function colonne(Model $element): string
    {
        return $element instanceof Marche ? 'marche_id' : 'produit_id';
    }

    private function type(Model $element): string
    {
        return $element instanceof Marche ? 'marche' : 'produit';
    }
}
