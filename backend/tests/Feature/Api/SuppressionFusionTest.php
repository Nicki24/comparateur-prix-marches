<?php

namespace Tests\Feature\Api;

use App\Models\Marche;
use App\Models\Produit;
use App\Models\RelevePrix;
use App\Models\Signalement;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Log;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * Suppression définitive et fusion de doublons : l'historique des prix
 * n'est jamais perdu.
 */
class SuppressionFusionTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;

    private User $contributeur;

    private Marche $marche;

    private Produit $produit;

    protected function setUp(): void
    {
        parent::setUp();

        $this->admin = User::create([
            'name' => 'Admin',
            'email' => 'admin@test.fr',
            'password' => 'password123',
            'role' => 'admin',
        ]);

        $this->contributeur = User::create([
            'name' => 'Contributeur',
            'email' => 'contrib@test.fr',
            'password' => 'password123',
            'role' => 'contributeur',
        ]);

        $this->marche = Marche::create(['nom' => 'Marché Test', 'localisation' => 'Toliara']);
        $this->produit = Produit::create(['nom' => 'Riz', 'unite_mesure' => 'kg']);
    }

    private function releve(Marche $marche, Produit $produit, string $date, float $valeur = 3000): RelevePrix
    {
        return RelevePrix::create([
            'produit_id' => $produit->id,
            'marche_id' => $marche->id,
            'utilisateur_id' => $this->contributeur->id,
            'valeur' => $valeur,
            'date_releve' => $date,
            'statut' => 'valide',
        ]);
    }

    // --- Accès ---

    public function test_un_contributeur_ne_peut_ni_supprimer_ni_fusionner(): void
    {
        Sanctum::actingAs($this->contributeur, ['*']);

        $this->deleteJson("/api/marches/{$this->marche->id}/definitif")->assertForbidden();
        $this->postJson("/api/produits/{$this->produit->id}/fusionner", ['cible_id' => 1])
            ->assertForbidden();

        $this->assertDatabaseHas('marches', ['id' => $this->marche->id]);
    }

    public function test_un_visiteur_doit_etre_connecte(): void
    {
        $this->deleteJson("/api/produits/{$this->produit->id}/definitif")->assertUnauthorized();
    }

    // --- Suppression définitive ---

    public function test_un_marche_sans_releve_est_supprime_et_journalise(): void
    {
        Log::spy();
        Sanctum::actingAs($this->admin, ['*']);

        $this->deleteJson("/api/marches/{$this->marche->id}/definitif")
            ->assertOk()
            ->assertJsonPath('message', 'Marché supprimé définitivement.');

        $this->assertDatabaseMissing('marches', ['id' => $this->marche->id]);
        Log::shouldHaveReceived('info')->once()->withArgs(
            fn ($message, $contexte) => $message === 'Administration : suppression définitive'
                && $contexte['type'] === 'marche'
                && $contexte['nom'] === 'Marché Test'
                && $contexte['admin_id'] === $this->admin->id
        );
    }

    public function test_un_produit_sans_releve_est_supprime(): void
    {
        Sanctum::actingAs($this->admin, ['*']);

        $this->deleteJson("/api/produits/{$this->produit->id}/definitif")
            ->assertOk()
            ->assertJsonPath('message', 'Produit supprimé définitivement.');

        $this->assertDatabaseMissing('produits', ['id' => $this->produit->id]);
    }

    public function test_un_marche_avec_releves_est_refuse_avec_409(): void
    {
        Sanctum::actingAs($this->admin, ['*']);
        $r1 = $this->releve($this->marche, $this->produit, '2026-10-01');
        $this->releve($this->marche, $this->produit, '2026-10-02');
        Signalement::create(['releve_id' => $r1->id, 'type_anomalie' => 'prix_anormal']);

        $this->deleteJson("/api/marches/{$this->marche->id}/definitif")
            ->assertStatus(409)
            ->assertJsonPath('releves', 2)
            ->assertJsonPath('signalements', 1)
            ->assertJsonPath(
                'message',
                'Ce marché a 2 relevés de prix et 1 signalement : '
                    .'désactivez-le plutôt, ou fusionnez-le avec un autre marché.'
            );

        $this->assertDatabaseHas('marches', ['id' => $this->marche->id]);
        $this->assertSame(2, RelevePrix::count());
    }

    public function test_un_produit_avec_un_releve_est_refuse_avec_409(): void
    {
        Sanctum::actingAs($this->admin, ['*']);
        $this->releve($this->marche, $this->produit, '2026-10-01');

        $this->deleteJson("/api/produits/{$this->produit->id}/definitif")
            ->assertStatus(409)
            ->assertJsonPath(
                'message',
                'Ce produit a 1 relevé de prix : désactivez-le plutôt, ou fusionnez-le avec un autre produit.'
            );

        $this->assertDatabaseHas('produits', ['id' => $this->produit->id]);
    }

    public function test_la_desactivation_existante_reste_une_suppression_logique(): void
    {
        Sanctum::actingAs($this->admin, ['*']);

        $this->deleteJson("/api/marches/{$this->marche->id}")->assertOk();

        $this->assertDatabaseHas('marches', ['id' => $this->marche->id, 'actif' => false]);
    }

    // --- Fusion ---

    public function test_la_fusion_deplace_les_releves_puis_supprime_le_doublon(): void
    {
        Log::spy();
        Sanctum::actingAs($this->admin, ['*']);
        $doublon = Marche::create(['nom' => 'Marche test', 'localisation' => 'Toliara']);
        $r1 = $this->releve($doublon, $this->produit, '2026-10-01');
        $this->releve($doublon, $this->produit, '2026-10-02');
        Signalement::create(['releve_id' => $r1->id, 'type_anomalie' => 'prix_anormal']);

        $this->postJson("/api/marches/{$doublon->id}/fusionner", ['cible_id' => $this->marche->id])
            ->assertOk()
            ->assertJsonPath('releves_deplaces', 2)
            ->assertJsonPath('message', 'Marché fusionné dans « Marché Test » : 2 relevés déplacés.');

        $this->assertDatabaseMissing('marches', ['id' => $doublon->id]);
        $this->assertSame(2, RelevePrix::where('marche_id', $this->marche->id)->count());
        // Les signalements suivent leur relevé.
        $this->assertDatabaseHas('signalements', ['releve_id' => $r1->id]);
        Log::shouldHaveReceived('info')->once()->withArgs(
            fn ($message, $contexte) => $message === 'Administration : fusion'
                && $contexte['doublon_id'] === $doublon->id
                && $contexte['cible_id'] === $this->marche->id
                && $contexte['releves_deplaces'] === 2
                && $contexte['admin_email'] === 'admin@test.fr'
        );
    }

    public function test_la_fusion_de_produits_deplace_les_releves(): void
    {
        Sanctum::actingAs($this->admin, ['*']);
        $doublon = Produit::create(['nom' => 'Riz blanc', 'unite_mesure' => 'kg']);
        $this->releve($this->marche, $doublon, '2026-10-01');

        $this->postJson("/api/produits/{$doublon->id}/fusionner", ['cible_id' => $this->produit->id])
            ->assertOk()
            ->assertJsonPath('releves_deplaces', 1);

        $this->assertDatabaseMissing('produits', ['id' => $doublon->id]);
        $this->assertSame(1, RelevePrix::where('produit_id', $this->produit->id)->count());
    }

    public function test_la_fusion_est_refusee_en_cas_de_releves_en_conflit(): void
    {
        Sanctum::actingAs($this->admin, ['*']);
        $doublon = Marche::create(['nom' => 'Doublon', 'localisation' => 'Toliara']);
        // Même contributeur, même produit, même jour sur les deux marchés.
        $this->releve($this->marche, $this->produit, '2026-10-01', 3000);
        $this->releve($doublon, $this->produit, '2026-10-01', 3100);
        $this->releve($doublon, $this->produit, '2026-10-02', 3200);

        $this->postJson("/api/marches/{$doublon->id}/fusionner", ['cible_id' => $this->marche->id])
            ->assertStatus(409)
            ->assertJsonPath('conflits', 1);

        // Rien n'a bougé : la transaction n'a rien appliqué.
        $this->assertDatabaseHas('marches', ['id' => $doublon->id]);
        $this->assertSame(2, RelevePrix::where('marche_id', $doublon->id)->count());
    }

    public function test_la_fusion_avec_soi_meme_ou_une_cible_inconnue_est_invalide(): void
    {
        Sanctum::actingAs($this->admin, ['*']);

        $this->postJson("/api/marches/{$this->marche->id}/fusionner", ['cible_id' => $this->marche->id])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('cible_id');

        $this->postJson("/api/marches/{$this->marche->id}/fusionner", ['cible_id' => 999999])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('cible_id');

        $this->postJson("/api/produits/{$this->produit->id}/fusionner", [])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('cible_id');

        $this->assertDatabaseHas('marches', ['id' => $this->marche->id]);
    }
}
