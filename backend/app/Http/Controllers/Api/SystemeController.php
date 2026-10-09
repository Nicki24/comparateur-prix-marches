<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Facades\Schema;

/**
 * Tâches de maintenance déclenchées par Wasmer Edge (app.yaml → jobs).
 *
 * Wasmer lance ses tâches « execute » sans les variables ni les secrets
 * de l'app : elles appellent donc ces routes en HTTP, qui s'exécutent
 * dans l'app avec sa vraie configuration.
 *
 * Sans danger en accès public : aucune donnée reçue, seulement un statut
 * renvoyé, et chaque tâche est idempotente (migrations en attente, admin
 * et produits créés une seule fois, relevés obsolètes marqués).
 */
class SystemeController extends Controller
{
    public function installer(): JsonResponse
    {
        return $this->executer('app:installer-production');
    }

    public function prixObsoletes(): JsonResponse
    {
        return $this->executer('app:detecter-prix-obsoletes');
    }

    private function executer(string $commande): JsonResponse
    {
        // Limite anti-abus ; ignorée au tout premier déploiement, quand la
        // table de cache (créée par les migrations) n'existe pas encore.
        if (Schema::hasTable('cache')
            && ! RateLimiter::attempt("systeme:$commande", 3, fn () => true, 60)) {
            return response()->json(['ok' => false, 'message' => 'Réessayez dans une minute.'], 429);
        }

        set_time_limit(120);
        $code = Artisan::call($commande);
        $sortie = trim(Artisan::output());
        // Détail (dont l'e-mail admin) dans les journaux, jamais dans la réponse.
        Log::warning("Tâche $commande : code $code", ['sortie' => $sortie]);

        return response()->json(['ok' => $code === 0], $code === 0 ? 200 : 500);
    }
}
