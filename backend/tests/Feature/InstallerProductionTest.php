<?php

namespace Tests\Feature;

use App\Models\Marche;
use App\Models\Produit;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class InstallerProductionTest extends TestCase
{
    use RefreshDatabase;

    protected function tearDown(): void
    {
        putenv('ADMIN_EMAIL');
        putenv('ADMIN_PASSWORD');
        parent::tearDown();
    }

    public function test_cree_l_admin_et_les_produits_sans_donnees_de_test(): void
    {
        putenv('ADMIN_EMAIL=admin@exemple.test');
        putenv('ADMIN_PASSWORD=un-mot-de-passe-long');

        $this->artisan('app:installer-production')->assertSuccessful();

        $this->assertTrue(User::where('email', 'admin@exemple.test')->where('role', 'admin')->exists());
        $this->assertSame(8, Produit::count());
        $this->assertSame(0, Marche::count());
    }

    public function test_relancer_ne_duplique_rien(): void
    {
        putenv('ADMIN_EMAIL=admin@exemple.test');
        putenv('ADMIN_PASSWORD=un-mot-de-passe-long');

        $this->artisan('app:installer-production')->assertSuccessful();
        $this->artisan('app:installer-production')->assertSuccessful();

        $this->assertSame(1, User::where('role', 'admin')->count());
        $this->assertSame(8, Produit::count());
    }

    public function test_refuse_un_mot_de_passe_admin_trop_court(): void
    {
        putenv('ADMIN_EMAIL=admin@exemple.test');
        putenv('ADMIN_PASSWORD=court');

        $this->artisan('app:installer-production')->assertFailed();

        $this->assertSame(0, User::count());
    }

    public function test_la_route_systeme_installe_sans_exposer_de_detail(): void
    {
        putenv('ADMIN_EMAIL=admin@exemple.test');
        putenv('ADMIN_PASSWORD=un-mot-de-passe-long');

        $this->postJson('/api/systeme/installer')
            ->assertOk()
            ->assertExactJson(['ok' => true]);

        $this->assertSame(8, Produit::count());
    }

    public function test_la_route_systeme_est_limitee(): void
    {
        putenv('ADMIN_EMAIL=admin@exemple.test');
        putenv('ADMIN_PASSWORD=un-mot-de-passe-long');

        for ($i = 0; $i < 3; $i++) {
            $this->postJson('/api/systeme/installer')->assertOk();
        }
        $this->postJson('/api/systeme/installer')->assertStatus(429);
    }
}
