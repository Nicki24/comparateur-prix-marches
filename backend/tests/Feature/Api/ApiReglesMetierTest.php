<?php

namespace Tests\Feature\Api;

use App\Models\Marche;
use App\Models\Produit;
use App\Models\RelevePrix;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ApiReglesMetierTest extends TestCase
{
    use RefreshDatabase;

    private User $contributeur;

    private User $admin;

    private Marche $marche;

    private Produit $produit;

    protected function setUp(): void
    {
        parent::setUp();

        $this->contributeur = User::create([
            'name' => 'Contributeur',
            'email' => 'contrib@test.fr',
            'password' => 'password123',
            'role' => 'contributeur',
        ]);

        $this->admin = User::create([
            'name' => 'Admin',
            'email' => 'admin@test.fr',
            'password' => 'password123',
            'role' => 'admin',
        ]);

        $this->marche = Marche::create(['nom' => 'Marché Test', 'localisation' => 'Toliara']);
        $this->produit = Produit::create(['nom' => 'Riz', 'unite_mesure' => 'kg']);
    }

    private function authentifier(User $user): void
    {
        Sanctum::actingAs($user, ['*']);
    }

    // --- Consultation publique ---

    public function test_les_marches_sont_consultables_sans_compte(): void
    {
        $this->getJson('/api/marches')
            ->assertOk()
            ->assertJsonCount(1, 'data');
    }

    public function test_la_comparaison_est_consultable_sans_compte(): void
    {
        RelevePrix::create([
            'produit_id' => $this->produit->id,
            'marche_id' => $this->marche->id,
            'utilisateur_id' => $this->contributeur->id,
            'valeur' => 3200,
            'date_releve' => now()->toDateString(),
            'statut' => 'valide',
        ]);

        $this->getJson('/api/produits/'.$this->produit->id.'/comparaison')
            ->assertOk()
            ->assertJsonPath('prix_par_marche.0.dernier_prix', '3200.00');
    }

    // --- Authentification ---

    public function test_register_creer_un_contributeur_et_un_token(): void
    {
        $response = $this->postJson('/api/register', [
            'name' => 'Nouveau',
            'email' => 'nouveau@test.fr',
            'password' => 'secret123',
            'password_confirmation' => 'secret123',
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('user.role', 'contributeur')
            ->assertJsonStructure(['token', 'user']);
    }

    public function test_login_retourne_un_token(): void
    {
        $this->postJson('/api/login', [
            'email' => $this->contributeur->email,
            'password' => 'password123',
        ])->assertOk()->assertJsonStructure(['token', 'user']);
    }

    // --- Règle anti-doublon : un relevé max / contributeur / produit / marché / jour ---

    public function test_un_contributeur_ne_peut_pas_soumettre_un_doublon_le_meme_jour(): void
    {
        RelevePrix::create([
            'produit_id' => $this->produit->id,
            'marche_id' => $this->marche->id,
            'utilisateur_id' => $this->contributeur->id,
            'valeur' => 3200,
            'date_releve' => now()->toDateString(),
            'statut' => 'valide',
        ]);

        $this->authentifier($this->contributeur);

        $this->postJson('/api/releves', [
            'produit_id' => $this->produit->id,
            'marche_id' => $this->marche->id,
            'valeur' => 3300,
            'date_releve' => now()->toDateString(),
        ])
            ->assertStatus(422);
    }

    public function test_un_contributeur_peut_soumettre_pour_une_autre_date(): void
    {
        $this->authentifier($this->contributeur);

        $this->postJson('/api/releves', [
            'produit_id' => $this->produit->id,
            'marche_id' => $this->marche->id,
            'valeur' => 3200,
            'date_releve' => now()->subDay()->toDateString(),
        ])
            ->assertCreated();
    }

    // --- Immutabilité : un relevé ne peut pas être modifié ---

    public function test_un_releve_est_immuable_apres_creation(): void
    {
        RelevePrix::create([
            'produit_id' => $this->produit->id,
            'marche_id' => $this->marche->id,
            'utilisateur_id' => $this->contributeur->id,
            'valeur' => 3200,
            'date_releve' => now()->toDateString(),
            'statut' => 'valide',
        ]);

        // Il n'y a pas d'endpoint de mise à jour de relevé (par conception).
        $this->getJson('/api/releves')
            ->assertOk()
            ->assertJsonPath('data.0.valeur', 3200);
    }

    // --- Validation du prix ---

    public function test_un_prix_doit_etre_superieur_a_zero(): void
    {
        $this->authentifier($this->contributeur);

        $this->postJson('/api/releves', [
            'produit_id' => $this->produit->id,
            'marche_id' => $this->marche->id,
            'valeur' => 0,
            'date_releve' => now()->toDateString(),
        ])
            ->assertStatus(422)
            ->assertJsonValidationErrors('valeur');
    }

    public function test_une_date_de_releve_future_est_refusee(): void
    {
        $this->authentifier($this->contributeur);

        $this->postJson('/api/releves', [
            'produit_id' => $this->produit->id,
            'marche_id' => $this->marche->id,
            'valeur' => 3200,
            'date_releve' => now()->addDay()->toDateString(),
        ])
            ->assertStatus(422)
            ->assertJsonValidationErrors('date_releve');
    }

    // --- Détection d'anomalie ---

    public function test_un_prix_anormal_est_signale_automatiquement(): void
    {
        $this->authentifier($this->contributeur);

        // Prix de référence normaux sur des jours distincts (contrainte anti-doublon)
        foreach ([3200, 3300, 3150] as $i => $prix) {
            RelevePrix::create([
                'produit_id' => $this->produit->id,
                'marche_id' => $this->marche->id,
                'utilisateur_id' => $this->contributeur->id,
                'valeur' => $prix,
                'date_releve' => now()->subDays($i + 1)->toDateString(),
                'statut' => 'valide',
            ]);
        }

        // Prix anormalement bas (-80%)
        $this->postJson('/api/releves', [
            'produit_id' => $this->produit->id,
            'marche_id' => $this->marche->id,
            'valeur' => 700,
            'date_releve' => now()->toDateString(),
        ])
            ->assertCreated()
            ->assertJsonPath('statut', 'signale');
    }

    // --- Autorisations ---

    public function test_les_signalements_sont_reserves_aux_admins(): void
    {
        $this->authentifier($this->contributeur);

        $this->getJson('/api/signalements')
            ->assertForbidden();
    }

    public function test_un_admin_peut_voir_les_signalements(): void
    {
        $this->authentifier($this->admin);

        $this->getJson('/api/signalements')
            ->assertOk();
    }

    public function test_seul_un_admin_peut_creer_un_produit(): void
    {
        $this->authentifier($this->contributeur);

        $this->postJson('/api/produits', [
            'nom' => 'Huile',
            'unite_mesure' => 'L',
        ])
            ->assertForbidden();

        $this->authentifier($this->admin);

        $this->postJson('/api/produits', [
            'nom' => 'Huile',
            'unite_mesure' => 'L',
        ])
            ->assertCreated();
    }

    public function test_la_saisie_de_releve_requiert_une_authentification(): void
    {
        $this->postJson('/api/releves', [
            'produit_id' => $this->produit->id,
            'marche_id' => $this->marche->id,
            'valeur' => 3200,
            'date_releve' => now()->toDateString(),
        ])->assertUnauthorized();
    }

    // --- Tableau de bord (synthèse) ---

    public function test_la_synthese_est_consultable_sans_compte(): void
    {
        $this->getJson('/api/stats')
            ->assertOk()
            ->assertJsonStructure([
                'nb_releves',
                'nb_marches_actifs',
                'nb_produits_actifs',
                'nb_contributeurs',
                'nb_signalements',
                'derniere_mise_a_jour',
            ]);
    }

    // --- Export CSV ---

    public function test_l_export_csv_est_reserve_aux_admins(): void
    {
        $this->authentifier($this->contributeur);

        $this->get('/api/releves/export')->assertForbidden();

        $this->authentifier($this->admin);

        $this->get('/api/releves/export')->assertOk();
    }

    public function test_l_export_csv_contient_l_en_tete_et_les_releves(): void
    {
        RelevePrix::create([
            'produit_id' => $this->produit->id,
            'marche_id' => $this->marche->id,
            'utilisateur_id' => $this->contributeur->id,
            'valeur' => 3200,
            'date_releve' => now()->toDateString(),
            'statut' => 'valide',
        ]);

        $this->authentifier($this->admin);

        $response = $this->get('/api/releves/export');

        $response->assertOk();
        $contenu = $response->streamedContent();

        $this->assertStringContainsString('Date', $contenu);
        $this->assertStringContainsString('Produit', $contenu);
        $this->assertStringContainsString('Riz', $contenu);
        $this->assertStringContainsString('3 200,00', $contenu);
    }
}
