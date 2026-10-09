<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\Assistant\AssistantService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AssistantController extends Controller
{
    /**
     * Discussion avec l'assistant IA. L'historique est envoyé par
     * l'application à chaque message (aucune conversation stockée).
     */
    public function discuter(Request $request, AssistantService $assistant): JsonResponse
    {
        $donnees = $request->validate([
            'messages' => ['required', 'array', 'min:1', 'max:20'],
            'messages.*.role' => ['required', 'in:user,assistant'],
            'messages.*.content' => ['required', 'string', 'max:2000'],
            // Position partagée volontairement depuis le chat (bouton 📍).
            // Utilisée pour ce seul calcul de distances, jamais enregistrée.
            'position' => ['nullable', 'array'],
            'position.latitude' => ['required_with:position', 'numeric', 'between:-90,90'],
            'position.longitude' => ['required_with:position', 'numeric', 'between:-180,180'],
        ]);

        $messages = array_map(fn ($m) => [
            'role' => $m['role'],
            'content' => trim($m['content']),
        ], $donnees['messages']);

        if (end($messages)['role'] !== 'user') {
            return response()->json(['message' => 'Le dernier message doit venir de l\'utilisateur.'], 422);
        }

        // Plusieurs allers-retours avec l'IA : on dépasse les 30 s par défaut.
        set_time_limit(120);

        try {
            $position = isset($donnees['position'])
                ? [(float) $donnees['position']['latitude'], (float) $donnees['position']['longitude']]
                : null;

            return response()->json($assistant->repondre($messages, $position));
        } catch (\Throwable $e) {
            report($e);

            return response()->json([
                'message' => 'L\'assistant est momentanément indisponible. Réessayez dans un instant.',
            ], 503);
        }
    }
}
