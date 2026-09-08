<?php

namespace Database\Seeders;

use App\Models\Marche;
use App\Models\Produit;
use App\Models\RelevePrix;
use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    public function run(): void
    {
        $admin = User::create([
            'name' => 'Norlande',
            'email' => 'admin@comparateur.mg',
            'password' => 'password123',
            'role' => 'admin',
        ]);

        $contributeur = User::create([
            'name' => 'Contributeur Témoin',
            'email' => 'contrib@comparateur.mg',
            'password' => 'password123',
            'role' => 'contributeur',
        ]);

        $marches = collect([
            ['nom' => 'Marché Andranomena', 'localisation' => 'Andranomena, Toliara', 'description' => 'Grand marché central, très fréquenté, bon choix de produits frais.'],
            ['nom' => 'Marché Sanférina', 'localisation' => 'Sanférina, Toliara', 'description' => 'Marché de quartier, prix généralement abordables.'],
            ['nom' => 'Marché Mahavatse II', 'localisation' => 'Mahavatse II, Toliara', 'description' => 'Marché récent, bonne disponibilité des produits de base.'],
            ['nom' => 'Marché Ankijabe', 'localisation' => 'Ankijabe, Toliara', 'description' => 'Petit marché local, produits maraîchers.'],
        ])->map(fn (array $m) => Marche::create($m));

        $produits = collect([
            ['nom' => 'Riz local (kilo)', 'unite_mesure' => 'kg', 'categorie' => 'Céréales'],
            ['nom' => 'Huile végétale (litre)', 'unite_mesure' => 'L', 'categorie' => 'Produits de base'],
            ['nom' => 'Sucre en poudre (kilo)', 'unite_mesure' => 'kg', 'categorie' => 'Produits de base'],
            ['nom' => 'Tomates fraîches (kilo)', 'unite_mesure' => 'kg', 'categorie' => 'Fruits & légumes'],
            ['nom' => 'Pommes de terre (kilo)', 'unite_mesure' => 'kg', 'categorie' => 'Fruits & légumes'],
            ['nom' => 'Farine de blé (kilo)', 'unite_mesure' => 'kg', 'categorie' => 'Céréales'],
            ['nom' => 'Haricots secs (kilo)', 'unite_mesure' => 'kg', 'categorie' => 'Légumineuses'],
            ['nom' => 'Lait en poudre (boîte 400g)', 'unite_mesure' => 'boîte', 'categorie' => 'Produits laitiers'],
        ])->map(fn (array $p) => Produit::create($p));

        $prixReferentiel = [
            'Riz local (kilo)' => 3200,
            'Huile végétale (litre)' => 8800,
            'Sucre en poudre (kilo)' => 5200,
            'Tomates fraîches (kilo)' => 2500,
            'Pommes de terre (kilo)' => 3000,
            'Farine de blé (kilo)' => 6400,
            'Haricots secs (kilo)' => 9500,
            'Lait en poudre (boîte 400g)' => 14500,
        ];

        // Facteur de marché : léger écart de prix entre marchés
        $facteurs = [0.95, 1.0, 1.08, 1.15];

        $jours = 14;
        for ($jour = $jours; $jour >= 0; $jour--) {
            $date = now()->subDays($jour)->toDateString();
            foreach ($produits as $i => $produit) {
                foreach ($marches as $j => $marche) {
                    $base = $prixReferentiel[$produit->nom];
                    $variation = (($jour + $i) % 5) - 2; // -2 à +2
                    $pct = ($variation / 100) * $base * 0.5;
                    $valeur = round(($base + $pct) * $facteurs[$j], 2);

                    RelevePrix::create([
                        'produit_id' => $produit->id,
                        'marche_id' => $marche->id,
                        'utilisateur_id' => $contributeur->id,
                        'valeur' => $valeur,
                        'date_releve' => $date,
                        'commentaire' => null,
                        'statut' => 'valide',
                    ]);
                }
            }
        }
    }
}
