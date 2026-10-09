<?php

namespace Tests\Feature\Api;

use App\Models\Marche;
use App\Models\Produit;
use App\Models\RelevePrix;
use App\Models\User;
use App\Services\Assistant\AssistantOutils;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * Position GPS des marchés et outil « marchés proches » de l'assistant.
 * Coordonnées fictives autour d'un point d'origine arbitraire.
 */
class GeolocalisationTest extends TestCase
{
    use RefreshDatabase;

    private const ORIGINE = [-23.35, 43.67];

    private AssistantOutils $outils;

    private Produit $riz;

    protected function setUp(): void
    {
        parent::setUp();

        $this->outils = new AssistantOutils;
        $this->riz = Produit::create(['nom' => 'Riz', 'unite_mesure' => 'kg']);
    }

    private function marche(string $nom, ?float $lat, ?float $lng, bool $actif = true): Marche
    {
        return Marche::create([
            'nom' => $nom,
            'localisation' => 'Ville test',
            'latitude' => $lat,
            'longitude' => $lng,
            'actif' => $actif,
        ]);
    }

    private function prix(Marche $marche, float $valeur): void
    {
        $contributeur = User::firstOrCreate(['email' => 'c@test.fr'], [
            'name' => 'C', 'password' => 'password123', 'role' => 'contributeur',
        ]);
        RelevePrix::create([
            'produit_id' => $this->riz->id,
            'marche_id' => $marche->id,
            'utilisateur_id' => $contributeur->id,
            'valeur' => $valeur,
            'date_releve' => now()->toDateString(),
            'statut' => 'valide',
        ]);
    }

    public function test_la_distance_haversine_est_correcte(): void
    {
        // 0,01° de latitude ≈ 1,11 km partout sur Terre.
        $this->assertEqualsWithDelta(1.11, AssistantOutils::distanceKm(0, 0, 0.01, 0), 0.01);
        $this->assertSame(0.0, AssistantOutils::distanceKm(10, 20, 10, 20));
    }

    public function test_sans_position_l_outil_le_signale(): void
    {
        $this->assertSame(
            ['erreur' => 'position_inconnue'],
            $this->outils->executer('marches_proches', []),
        );
    }

    public function test_les_marches_sont_tries_par_distance_dans_le_rayon(): void
    {
        $this->marche('Loin', -23.35 + 0.5, 43.67, true);     // ≈ 55 km : hors rayon
        $this->marche('Moyen', -23.35 + 0.03, 43.67, true);   // ≈ 3,3 km
        $this->marche('Proche', -23.35 + 0.01, 43.67, true);  // ≈ 1,1 km
        $this->marche('Sans GPS', null, null, true);
        $this->marche('Fermé', -23.35, 43.67, false);

        $this->outils->definirPosition(self::ORIGINE);
        $resultat = $this->outils->executer('marches_proches', []);

        $this->assertSame(['Proche', 'Moyen'], array_column($resultat['marches'], 'marche'));
        $this->assertSame(1.1, $resultat['marches'][0]['distance_km']);
        $this->assertSame(1, $resultat['nb_marches_sans_position']);
    }

    public function test_avec_un_produit_le_moins_cher_proche_passe_en_premier(): void
    {
        $proche = $this->marche('Proche', -23.35 + 0.01, 43.67);
        $moyen = $this->marche('Moyen', -23.35 + 0.03, 43.67);
        $this->marche('Sans prix', -23.35 + 0.02, 43.67);
        $this->prix($proche, 3200);
        $this->prix($moyen, 2900);

        $this->outils->definirPosition(self::ORIGINE);
        $resultat = $this->outils->executer('marches_proches', ['produit_id' => $this->riz->id]);

        $this->assertSame(['Moyen', 'Proche'], array_column($resultat['marches'], 'marche'));
        $this->assertSame(2900.0, $resultat['marches'][0]['prix_ariary']);
    }

    public function test_l_admin_enregistre_la_position_d_un_marche(): void
    {
        $admin = User::create([
            'name' => 'Admin', 'email' => 'admin@test.fr', 'password' => 'password123', 'role' => 'admin',
        ]);
        Sanctum::actingAs($admin, ['*']);

        $this->postJson('/api/marches', [
            'nom' => 'Marché GPS',
            'localisation' => 'Ville test',
            'quartier' => 'Quartier A',
            'latitude' => -23.351,
            'longitude' => 43.671,
        ])->assertCreated()
            ->assertJsonPath('quartier', 'Quartier A')
            ->assertJsonPath('latitude', -23.351);
    }

    public function test_une_latitude_seule_est_refusee(): void
    {
        $admin = User::create([
            'name' => 'Admin', 'email' => 'admin@test.fr', 'password' => 'password123', 'role' => 'admin',
        ]);
        Sanctum::actingAs($admin, ['*']);

        $this->postJson('/api/marches', [
            'nom' => 'Marché incomplet',
            'localisation' => 'Ville test',
            'latitude' => -23.351,
        ])->assertUnprocessable()->assertJsonValidationErrors('longitude');
    }

    public function test_l_assistant_refuse_une_position_invalide(): void
    {
        $this->postJson('/api/assistant', [
            'messages' => [['role' => 'user', 'content' => 'Marché proche ?']],
            'position' => ['latitude' => 120, 'longitude' => 43.67],
        ])->assertUnprocessable()->assertJsonValidationErrors('position.latitude');
    }
}
