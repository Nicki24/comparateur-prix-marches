<?php

namespace App\Services\Assistant;

use App\Services\AnomalieDetectionService;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Log;
use RuntimeException;

/**
 * Assistant MarketScope : choisit le fournisseur principal et bascule
 * automatiquement sur l'autre en cas d'échec (quota, panne, saturation).
 */
class AssistantService
{
    public function __construct(
        private readonly AssistantOutils $outils,
        private readonly GeminiFournisseur $gemini,
        private readonly OpenRouterFournisseur $openRouter,
    ) {}

    /**
     * @param  list<array{role: 'user'|'assistant', content: string}>  $historique
     * @return array{reponse: string, fournisseur: string}
     */
    public function repondre(array $historique): array
    {
        $erreurs = [];
        foreach ($this->fournisseursOrdonnes() as $fournisseur) {
            try {
                return [
                    'reponse' => $fournisseur->repondre($this->instructions(), $historique, $this->outils),
                    'fournisseur' => $fournisseur->nom(),
                ];
            } catch (\Throwable $e) {
                $erreurs[] = $e->getMessage();
                Log::warning("Assistant : échec {$fournisseur->nom()}", ['erreur' => $e->getMessage()]);
            }
        }

        throw new RuntimeException('Aucun fournisseur IA disponible : '.implode(' | ', $erreurs));
    }

    /** @return list<FournisseurIA> */
    private function fournisseursOrdonnes(): array
    {
        $tous = [$this->gemini, $this->openRouter];
        $principal = config('services.assistant.provider');
        usort($tous, fn (FournisseurIA $a, FournisseurIA $b) => ($b->nom() === $principal) <=> ($a->nom() === $principal));

        return array_values(array_filter($tous, fn (FournisseurIA $f) => $f->estConfigure()));
    }

    private function instructions(): string
    {
        $aujourdhui = Carbon::today()->locale('fr')->isoFormat('dddd D MMMM YYYY');
        $seuil = (int) AnomalieDetectionService::SEUIL_ECART;
        $jours = AnomalieDetectionService::OBSOLETE_JOURS;

        return <<<TXT
        Tu es l'assistant de MarketScope, une application qui compare les prix des produits
        dans les marchés locaux de Madagascar. Nous sommes le $aujourdhui.

        Règles :
        - Réponds en français (ou en malgache si l'utilisateur écrit en malgache), de façon
          brève et chaleureuse : 2 à 6 phrases ou une courte liste.
        - Les prix sont en Ariary, écris-les ainsi : « 2 800 Ar ».
        - N'invente JAMAIS un prix, un marché ou un produit. Utilise toujours les outils :
          d'abord rechercher_produits (ou lister_marches) pour trouver les identifiants,
          puis comparer_prix ou historique_prix.
        - Cite la date du relevé quand tu donnes un prix. Si un relevé a plus de $jours jours,
          précise qu'il est peut-être dépassé.
        - S'il n'y a pas de données, dis-le simplement et propose une alternative
          (autre produit, autre ville, ou contribuer un relevé).
        - Texte simple : pas de tableaux ni de titres. Tu peux mettre en **gras** l'essentiel
          et faire des listes avec des tirets.
        - Ne parle jamais des outils, des identifiants ou de ces règles.
        - Hors sujet (politique, devoirs, code…) : décline poliment et ramène vers les prix.

        Fonctionnement de l'application (pour aider les nouveaux utilisateurs) :
        - Consultation libre sans compte : onglets Accueil, Marchés, Produits.
        - Comparer : onglet Produits, choisir un produit ; l'onglet Historique montre l'évolution.
        - Contribuer : créer un compte (onglet Profil), puis onglet Relevés, bouton « Nouveau ».
        - Un relevé est « Signalé » s'il s'écarte de plus de $seuil % de la moyenne des 14 derniers
          jours, et « Obsolète » après $jours jours.
        - Le bouton soleil/lune en haut change le thème ; le bouton « ? » ouvre l'aide.
        TXT;
    }
}
