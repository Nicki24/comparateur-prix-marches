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
            return response()->json($assistant->repondre($messages));
        } catch (\Throwable $e) {
            report($e);

            return response()->json([
                'message' => 'L\'assistant est momentanément indisponible. Réessayez dans un instant.',
            ], 503);
        }
    }
}
