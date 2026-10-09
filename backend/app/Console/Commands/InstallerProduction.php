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

        // Tolère les espaces ou guillemets ajoutés par erreur autour des valeurs.
        $email = trim((string) env('ADMIN_EMAIL'), " \t\n\r\"'");
        $motDePasse = (string) env('ADMIN_PASSWORD');

        $erreurs = [];
        if ($email === '') {
            $erreurs[] = 'ADMIN_EMAIL est absent';
        } elseif (! filter_var($email, FILTER_VALIDATE_EMAIL)) {
            $erreurs[] = "ADMIN_EMAIL n'est pas une adresse e-mail valide";
        }
        if ($motDePasse === '') {
            $erreurs[] = 'ADMIN_PASSWORD est absent';
        } elseif (mb_strlen($motDePasse) < 12) {
            $erreurs[] = 'ADMIN_PASSWORD fait moins de 12 caractères';
        }
        // Jamais les valeurs elles-mêmes dans les journaux.
        if ($erreurs !== []) {
            $this->error('Compte admin non créé : '.implode(' ; ', $erreurs).'.');

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
