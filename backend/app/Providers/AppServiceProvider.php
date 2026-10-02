<?php

namespace App\Providers;

use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // PHP sous Windows n'a pas de certificats racine par défaut : on lui
        // indique un fichier CA pour les appels HTTPS sortants (assistant IA).
        if ($ca = config('services.http_ca_bundle')) {
            Http::globalOptions(['verify' => $ca]);
        }

        // Assistant IA : chaque message coûte un appel au fournisseur.
        RateLimiter::for('assistant', function (Request $request) {
            $cle = $request->user('sanctum')?->id ?? $request->ip();
            $reponse = fn () => response()->json([
                'message' => 'Vous avez envoyé beaucoup de questions. Patientez un peu avant de réessayer.',
            ], 429);

            return [
                Limit::perMinute(config('services.assistant.limite_minute'))->by("min:$cle")->response($reponse),
                Limit::perDay(config('services.assistant.limite_jour'))->by("jour:$cle")->response($reponse),
            ];
        });
    }
}
