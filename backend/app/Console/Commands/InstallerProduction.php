<?php

namespace App\Console\Commands;

use App\Models\Produit;
use App\Models\User;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;

/**
 * Prépare la base de production, relancée à chaque déploiement :
 * migrations, compte administrateur et liste des produits suivis.
 *
 * Idempotente : rien n'est écrasé si le compte admin ou les produits
 * existent déjà. Aucun marché ni prix de test n'est créé : les vrais
 * marchés sont ajoutés par l'administrateur depuis l'application.
 */
#[Signature('app:installer-production')]
#[Description('Migre la base et crée le compte admin + les produits de départ (production)')]
class InstallerProduction extends Command
{
    /** Produits suivis au lancement ; modifiables ensuite par l'admin. */
    private const PRODUITS = [
        ['nom' => 'Riz local (kilo)', 'unite_mesure' => 'kg', 'categorie' => 'Céréales'],
        ['nom' => 'Huile végétale (litre)', 'unite_mesure' => 'L', 'categorie' => 'Produits de base'],
        ['nom' => 'Sucre en poudre (kilo)', 'unite_mesure' => 'kg', 'categorie' => 'Produits de base'],
        ['nom' => 'Tomates fraîches (kilo)', 'unite_mesure' => 'kg', 'categorie' => 'Fruits & légumes'],
        ['nom' => 'Pommes de terre (kilo)', 'unite_mesure' => 'kg', 'categorie' => 'Fruits & légumes'],
        ['nom' => 'Farine de blé (kilo)', 'unite_mesure' => 'kg', 'categorie' => 'Céréales'],
        ['nom' => 'Haricots secs (kilo)', 'unite_mesure' => 'kg', 'categorie' => 'Légumineuses'],
        ['nom' => 'Lait en poudre (boîte 400g)', 'unite_mesure' => 'boîte', 'categorie' => 'Produits laitiers'],
    ];

    public function handle(): int
    {
        $this->call('migrate', ['--force' => true]);

        if (! $this->creerAdmin()) {
            return self::FAILURE;
        }

        if (Produit::count() === 0) {
            foreach (self::PRODUITS as $produit) {
                Produit::create($produit);
            }
            $this->info(count(self::PRODUITS).' produits créés.');
        }

        return self::SUCCESS;
    }

    private function creerAdmin(): bool
    {
        if (User::where('role', 'admin')->exists()) {
            $this->info('Compte administrateur déjà présent : inchangé.');

            return true;
        }

        $email = (string) env('ADMIN_EMAIL');
        $motDePasse = (string) env('ADMIN_PASSWORD');

        if (! filter_var($email, FILTER_VALIDATE_EMAIL) || mb_strlen($motDePasse) < 12) {
            $this->error('Définissez les secrets ADMIN_EMAIL et ADMIN_PASSWORD (12 caractères minimum).');

            return false;
        }

        User::create([
            'name' => (string) env('ADMIN_NAME', 'Administrateur'),
            'email' => $email,
            'password' => $motDePasse,
            'role' => 'admin',
        ]);
        $this->info("Compte administrateur créé : $email");

        return true;
    }
}
