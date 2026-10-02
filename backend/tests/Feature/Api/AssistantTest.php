<?php

namespace Tests\Feature\Api;

use App\Models\Marche;
use App\Models\Produit;
use App\Models\RelevePrix;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Client\Request;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class AssistantTest extends TestCase
{
    use RefreshDatabase;

    private Produit $riz;

    protected function setUp(): void
    {
        parent::setUp();

        config([
            'services.assistant.provider' => 'gemini',
            'services.assistant.gemini.key' => 'cle-test',
            'services.assistant.openrouter.key' => 'cle-test',
            'services.assistant.openrouter.models' => 'modele/test:free',
            'services.assistant.limite_minute' => 100,
        ]);

        $user = User::create([
            'name' => 'Contributeur', 'email' => 'c@test.fr',
            'password' => 'password123', 'role' => 'contributeur',
        ]);
        $marche = Marche::create(['nom' => 'Marché Test', 'localisation' => 'Toliara']);
        $this->riz = Produit::create(['nom' => 'Riz local', 'unite_mesure' => 'kilo']);
        RelevePrix::create([
            'produit_id' => $this->riz->id, 'marche_id' => $marche->id,
            'utilisateur_id' => $user->id, 'valeur' => 2800,
            'date_releve' => now()->toDateString(), 'statut' => 'valide',
        ]);
    }

    private function question(string $texte = 'Où est le riz le moins cher ?')
    {
        return $this->postJson('/api/assistant', [
            'messages' => [['role' => 'user', 'content' => $texte]],
        ]);
    }

    public function test_gemini_appelle_un_outil_puis_repond_avec_les_vraies_donnees(): void
    {
        Http::fake([
            'generativelanguage.googleapis.com/*' => Http::sequence()
                ->push(['candidates' => [['content' => ['role' => 'model', 'parts' => [
                    ['functionCall' => ['id' => 'a1', 'name' => 'comparer_prix', 'args' => ['produit_id' => $this->riz->id]]],
                ]]]]])
                ->push(['candidates' => [['content' => ['role' => 'model', 'parts' => [
                    ['text' => 'Le riz est à 2 800 Ar au Marché Test.'],
                ]]]]]),
        ]);

        $this->question()
            ->assertOk()
            ->assertJson(['fournisseur' => 'gemini', 'reponse' => 'Le riz est à 2 800 Ar au Marché Test.']);

        // Le 2e appel renvoie bien le résultat de l'outil, issu de la base.
        Http::assertSent(function (Request $r) {
            $reponse = $r['contents'][2]['parts'][0]['functionResponse']['response'] ?? null;

            return $reponse && $reponse['prix_par_marche'][0]['prix_ariary'] === 2800.0
                && $reponse['prix_par_marche'][0]['marche'] === 'Marché Test';
        });
    }

    public function test_bascule_sur_openrouter_si_gemini_echoue(): void
    {
        Http::fake([
            'generativelanguage.googleapis.com/*' => Http::response(['error' => ['message' => 'quota']], 400),
            'openrouter.ai/*' => Http::response(['choices' => [['message' => [
                'role' => 'assistant', 'content' => 'Réponse de secours.',
            ]]]]),
        ]);

        $this->question()->assertOk()->assertJson(['fournisseur' => 'openrouter']);
    }

    public function test_503_lisible_si_tous_les_fournisseurs_echouent(): void
    {
        Http::fake(['*' => Http::response(['error' => ['message' => 'panne']], 500)]);

        $this->question()->assertStatus(503)->assertJsonStructure(['message']);
    }

    public function test_valide_l_historique(): void
    {
        Http::fake();

        $this->postJson('/api/assistant', ['messages' => []])->assertStatus(422);
        $this->postJson('/api/assistant', ['messages' => [
            ['role' => 'assistant', 'content' => 'Bonjour'],
        ]])->assertStatus(422);
        Http::assertNothingSent();
    }

    public function test_limite_d_usage_par_minute(): void
    {
        config(['services.assistant.limite_minute' => 2]);
        Http::fake(['*' => Http::response(['candidates' => [['content' => ['parts' => [['text' => 'ok']]]]]])]);

        $this->question()->assertOk();
        $this->question()->assertOk();
        $this->question()->assertStatus(429);
    }
}
