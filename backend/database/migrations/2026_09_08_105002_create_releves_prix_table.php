<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('releves_prix', function (Blueprint $table) {
            $table->id();
            $table->foreignId('produit_id')->constrained('produits')->restrictOnDelete();
            $table->foreignId('marche_id')->constrained('marches')->restrictOnDelete();
            $table->foreignId('utilisateur_id')->constrained('users')->restrictOnDelete();
            $table->decimal('valeur', 12, 2);
            $table->date('date_releve');
            $table->text('commentaire')->nullable();
            $table->enum('statut', ['valide', 'signale'])->default('valide');
            $table->timestamp('created_at')->useCurrent();
            $table->unique(
                ['utilisateur_id', 'produit_id', 'marche_id', 'date_releve'],
                'un_releve_par_jour_par_contributeur'
            );
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('releves_prix');
    }
};
