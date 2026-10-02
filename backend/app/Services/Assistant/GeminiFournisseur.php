<?php

namespace App\Services\Assistant;

use Illuminate\Support\Facades\Http;
use RuntimeException;

/** Google Gemini (API generateContent + appel de fonctions). */
class GeminiFournisseur implements FournisseurIA
{
    private const URL = 'https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent';

    private const TOURS_MAX = 6;

    public function nom(): string
    {
        return 'gemini';
    }

    public function estConfigure(): bool
    {
        return filled(config('services.assistant.gemini.key'));
    }

    public function repondre(string $systeme, array $historique, AssistantOutils $outils): string
    {
        $contents = array_map(fn ($m) => [
            'role' => $m['role'] === 'assistant' ? 'model' : 'user',
            'parts' => [['text' => $m['content']]],
        ], $historique);

        $declarations = array_map(function ($d) {
            $decl = ['name' => $d['name'], 'description' => $d['description']];
            // Gemini refuse un objet sans propriétés : on omet alors le schéma.
            if (! empty((array) $d['parameters']['properties'])) {
                $decl['parameters'] = $d['parameters'];
            }

            return $decl;
        }, $outils->definitions());

        for ($tour = 0; $tour < self::TOURS_MAX; $tour++) {
            $reponse = Http::timeout(40)
                // Offres gratuites : une saturation passagère mérite un 2e essai.
                ->retry(2, 2000, fn ($e) => in_array($e->response?->status(), [429, 503], true), throw: false)
                ->withHeaders(['x-goog-api-key' => config('services.assistant.gemini.key')])
                ->post(sprintf(self::URL, config('services.assistant.gemini.model')), [
                    'systemInstruction' => ['parts' => [['text' => $systeme]]],
                    'contents' => $contents,
                    'tools' => [['functionDeclarations' => $declarations]],
                    'generationConfig' => ['temperature' => 0.3, 'maxOutputTokens' => 2048],
                ]);

            if ($reponse->failed()) {
                throw new RuntimeException('Gemini HTTP '.$reponse->status().' : '.$reponse->json('error.message'));
            }

            // Les parts sont renvoyées telles quelles (signatures de pensée incluses).
            $parts = $reponse->json('candidates.0.content.parts') ?? [];
            $appels = array_values(array_filter($parts, fn ($p) => isset($p['functionCall'])));

            if ($appels === []) {
                $texte = trim(implode('', array_column($parts, 'text')));
                if ($texte === '') {
                    throw new RuntimeException('Gemini : réponse vide ('.$reponse->json('candidates.0.finishReason').').');
                }

                return $texte;
            }

            $contents[] = ['role' => 'model', 'parts' => $parts];
            $contents[] = [
                'role' => 'user',
                'parts' => array_map(fn ($a) => ['functionResponse' => array_filter([
                    'id' => $a['functionCall']['id'] ?? null,
                    'name' => $a['functionCall']['name'],
                    'response' => $outils->executer($a['functionCall']['name'], $a['functionCall']['args'] ?? []),
                ], fn ($v) => $v !== null)], $appels),
            ];
        }

        throw new RuntimeException('Gemini : trop d\'appels d\'outils.');
    }
}
