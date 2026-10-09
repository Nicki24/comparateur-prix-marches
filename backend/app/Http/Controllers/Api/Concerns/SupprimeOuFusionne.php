<?php

namespace App\Http\Controllers\Api\Concerns;

use App\Exceptions\FusionEnConflitException;
use App\Services\GestionReferentielService;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Suppression définitive et fusion partagées par les marchés et les produits.
 */
trait SupprimeOuFusionne
{
    /**
     * Supprime l'élément s'il n'a aucun historique, sinon 409.
     */
    protected function supprimerElement(Request $request, Model $element, string $libelle): JsonResponse
    {
        $service = app(GestionReferentielService::class);
        $liens = $service->supprimer($element, $request->user());

        if ($liens !== null) {
            return response()->json([
                'message' => $service->messageRefus($element, $liens),
                'releves' => $liens['releves'],
                'signalements' => $liens['signalements'],
            ], 409);
        }

        return response()->json(['message' => "$libelle supprimé définitivement."]);
    }

    /**
     * Déplace l'historique du doublon vers la cible puis supprime le doublon.
     *
     * @param  class-string<Model>  $classe
     */
    protected function fusionnerElement(Request $request, Model $doublon, string $classe, string $libelle): JsonResponse
    {
        $donnees = $request->validate([
            'cible_id' => [
                'required',
                'integer',
                'exists:'.$doublon->getTable().',id',
                'not_in:'.$doublon->getKey(),
            ],
        ], [
            'cible_id.required' => 'Choisissez l’élément à conserver.',
            'cible_id.exists' => 'L’élément à conserver est introuvable.',
            'cible_id.not_in' => 'Un élément ne peut pas être fusionné avec lui-même.',
        ]);

        $cible = $classe::findOrFail($donnees['cible_id']);
        $service = app(GestionReferentielService::class);

        try {
            $deplaces = $service->fusionner($doublon, $cible, $request->user());
        } catch (FusionEnConflitException $e) {
            return response()->json([
                'message' => 'Fusion impossible : '
                    .$service->pluriel($e->conflits, 'relevé existe', 'relevés existent')
                    ." déjà pour « {$cible->nom} » (même contributeur, même jour). "
                    .'Désactivez plutôt le doublon.',
                'conflits' => $e->conflits,
            ], 409);
        }

        return response()->json([
            'message' => "$libelle fusionné dans « {$cible->nom} » : "
                .$service->pluriel($deplaces, 'relevé déplacé', 'relevés déplacés').'.',
            'releves_deplaces' => $deplaces,
            'cible_id' => $cible->getKey(),
        ]);
    }
}
