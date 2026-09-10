<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ComparisonController;
use App\Http\Controllers\Api\MarcheController;
use App\Http\Controllers\Api\ProduitController;
use App\Http\Controllers\Api\ReleveController;
use App\Http\Controllers\Api\SignalementController;
use App\Http\Controllers\Api\StatistiqueController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

// --- Authentification (publique) ---
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

// --- Consultation publique (sans compte) ---
Route::get('/marches', [MarcheController::class, 'index']);
Route::get('/marches/{marche}', [MarcheController::class, 'show']);
Route::get('/produits', [ProduitController::class, 'index']);
Route::get('/produits/{produit}', [ProduitController::class, 'show']);
Route::get('/releves', [ReleveController::class, 'index']);
Route::get('/produits/{produit}/comparaison', [ComparisonController::class, 'dernierPrixParMarche']);
Route::get('/produits/{produit}/historique', [ComparisonController::class, 'historique']);

// --- Tableau de bord (synthèse publique) ---
Route::get('/stats', [StatistiqueController::class, 'synthese']);

// --- Zone authentifiée (contributeurs + admin) ---
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);

    // Saisie de relevés (contributeur)
    Route::post('/releves', [ReleveController::class, 'store']);

    // Gestion marchés / produits (admin)
    Route::middleware('admin')->group(function () {
        Route::post('/marches', [MarcheController::class, 'store']);
        Route::put('/marches/{marche}', [MarcheController::class, 'update']);
        Route::delete('/marches/{marche}', [MarcheController::class, 'destroy']);

        Route::post('/produits', [ProduitController::class, 'store']);
        Route::put('/produits/{produit}', [ProduitController::class, 'update']);
        Route::delete('/produits/{produit}', [ProduitController::class, 'destroy']);

        Route::get('/signalements', [SignalementController::class, 'index']);
        Route::post('/signalements/detecter-obsoletes', [SignalementController::class, 'detecterObsoletes']);

        // Export CSV des relevés (réservé aux administrateurs)
        Route::get('/releves/export', [ReleveController::class, 'exportCsv']);
    });
});
