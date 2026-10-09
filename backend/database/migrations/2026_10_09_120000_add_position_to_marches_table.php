<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Position GPS du marché, placée par l'administrateur sur la carte.
     * Facultative : un marché sans position reste consultable, il n'apparaît
     * simplement pas dans les recherches « près de moi ».
     */
    public function up(): void
    {
        Schema::table('marches', function (Blueprint $table) {
            $table->string('quartier', 120)->nullable()->after('localisation');
            // 7 décimales ≈ 1 cm : largement suffisant pour un marché.
            $table->decimal('latitude', 10, 7)->nullable()->after('quartier');
            $table->decimal('longitude', 10, 7)->nullable()->after('latitude');
        });
    }

    public function down(): void
    {
        Schema::table('marches', function (Blueprint $table) {
            $table->dropColumn(['quartier', 'latitude', 'longitude']);
        });
    }
};
