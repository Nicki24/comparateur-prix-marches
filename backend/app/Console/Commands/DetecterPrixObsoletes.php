<?php

namespace App\Console\Commands;

use App\Services\AnomalieDetectionService;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;

#[Signature('app:detecter-prix-obsoletes')]
#[Description('Marque comme obsolètes les relevés valides datant de plus de 14 jours')]
class DetecterPrixObsoletes extends Command
{
    public function handle(AnomalieDetectionService $service): int
    {
        $compte = $service->detecterPrixObsoletes();

        $this->info("$compte relevé(s) marqué(s) comme obsolètes.");

        return self::SUCCESS;
    }
}
