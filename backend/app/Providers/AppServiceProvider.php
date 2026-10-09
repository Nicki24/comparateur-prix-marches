<?php

namespace App\Providers;

use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Str;

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

        // Connexion : 5 essais/minute par couple e-mail + IP, et 20/minute par
        // IP pour freiner le test d'une liste d'e-mails depuis une même machine.
        RateLimiter::for('connexion', function (Request $request) {
            $email = Str::lower((string) $request->input('email'));
            $reponse = fn () => response()->json([
                'message' => 'Trop de tentatives de connexion. Réessayez dans une minute.',
            ], 429);

            return [
                Limit::perMinute(5)->by("connexion:$email|{$request->ip()}")->response($reponse),
                Limit::perMinute(20)->by("connexion-ip:{$request->ip()}")->response($reponse),
            ];
        });

        // Inscription : limite la création de comptes en masse.
        RateLimiter::for('inscription', function (Request $request) {
            return Limit::perHour(10)->by($request->ip())->response(fn () => response()->json([
                'message' => 'Trop de créations de compte depuis cette connexion. Réessayez plus tard.',
            ], 429));
        });

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
