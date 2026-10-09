<?php

namespace Tests\Feature\Api;

use App\Models\Marche;
use App\Models\Produit;
use App\Models\RelevePrix;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * Protections de sécurité de l'API : limitation des tentatives,
 * export CSV sans formules, pagination plafonnée.
 */
class SecuriteApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_la_connexion_est_bloquee_apres_cinq_echecs(): void
    {
        User::create([
            'name' => 'Victime',
            'email' => 'victime@test.fr',
            'password' => 'password123',
            'role' => 'contributeur',
        ]);

        for ($i = 0; $i < 5; $i++) {
            $this->postJson('/api/login', [
                'email' => 'victime@test.fr',
                'password' => 'mauvais-mot-de-passe',
            ])->assertStatus(401);
        }

        // Même le bon mot de passe est refusé tant que la fenêtre court.
        $this->postJson('/api/login', [
            'email' => 'victime@test.fr',
            'password' => 'password123',
        ])->assertStatus(429);
    }

    public function test_l_inscription_est_limitee_par_adresse_ip(): void
    {
        for ($i = 0; $i < 10; $i++) {
            $this->postJson('/api/register', [
                'name' => "Compte $i",
                'email' => "compte$i@test.fr",
                'password' => 'password123',
                'password_confirmation' => 'password123',
            ])->assertCreated();
        }

        $this->postJson('/api/register', [
            'name' => 'Compte de trop',
            'email' => 'trop@test.fr',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ])->assertStatus(429);
    }

    public function test_l_export_csv_neutralise_les_formules(): void
    {
        $piege = User::create([
            'name' => '=HYPERLINK("http://evil.test","clic")',
            'email' => 'piege@test.fr',
            'password' => 'password123',
            'role' => 'contributeur',
        ]);
        $admin = User::create([
            'name' => 'Admin',
            'email' => 'admin@test.fr',
            'password' => 'password123',
            'role' => 'admin',
        ]);
        $marche = Marche::create(['nom' => 'Marché Test', 'localisation' => 'Toliara']);
        $produit = Produit::create(['nom' => 'Riz', 'unite_mesure' => 'kg']);
        RelevePrix::create([
            'produit_id' => $produit->id,
            'marche_id' => $marche->id,
            'utilisateur_id' => $piege->id,
            'valeur' => 3200,
            'date_releve' => now()->toDateString(),
            'statut' => 'valide',
        ]);

        Sanctum::actingAs($admin, ['*']);
        $csv = $this->get('/api/releves/export')->assertOk()->streamedContent();

        $this->assertStringContainsString("'=HYPERLINK", $csv);
        $this->assertStringNotContainsString(';"=HYPERLINK', $csv);
    }

    public function test_la_pagination_est_plafonnee_a_cent_elements(): void
    {
        $this->getJson('/api/releves?per_page=100000')
            ->assertOk()
            ->assertJsonPath('meta.per_page', 100);
    }
}
