<?php

namespace App\Services\Assistant;

use Illuminate\Support\Facades\Http;
use RuntimeException;

/** OpenRouter (format OpenAI chat/completions + tools). */
class OpenRouterFournisseur implements FournisseurIA
{
    private const URL = 'https://openrouter.ai/api/v1/chat/completions';

    private const TOURS_MAX = 6;

    public function nom(): string
    {
        return 'openrouter';
    }

    public function estConfigure(): bool
    {
        return filled(config('services.assistant.openrouter.key'));
    }

    public function repondre(string $systeme, array $historique, AssistantOutils $outils): string
    {
        $messages = [['role' => 'system', 'content' => $systeme], ...$historique];

        $tools = array_map(fn ($d) => ['type' => 'function', 'function' => $d], $outils->definitions());

        $modeles = array_values(array_filter(array_map('trim',
            explode(',', (string) config('services.assistant.openrouter.models')))));

        for ($tour = 0; $tour < self::TOURS_MAX; $tour++) {
            $reponse = Http::timeout(40)
                // Offres gratuites : une saturation passagère mérite un 2e essai.
                ->retry(2, 2000, fn ($e) => in_array($e->response?->status(), [429, 503], true), throw: false)
                ->withToken(config('services.assistant.openrouter.key'))
                ->withHeaders(['X-Title' => 'MarketScope'])
                ->post(self::URL, [
                    // Plusieurs modèles : OpenRouter bascule si le premier est saturé.
                    ...(count($modeles) > 1 ? ['models' => $modeles] : ['model' => $modeles[0] ?? '']),
                    'messages' => $messages,
                    'tools' => $tools,
                    'temperature' => 0.3,
                    'max_tokens' => 1500,
                ]);

            if ($reponse->failed() || $reponse->json('error')) {
                throw new RuntimeException('OpenRouter HTTP '.$reponse->status().' : '
                    .json_encode($reponse->json('error.message') ?? $reponse->json('error')));
            }

            $message = $reponse->json('choices.0.message') ?? [];
            $appels = $message['tool_calls'] ?? [];

            if ($appels === []) {
                $texte = trim((string) ($message['content'] ?? ''));
                if ($texte === '') {
                    throw new RuntimeException('OpenRouter : réponse vide.');
                }

                return $texte;
            }

            $messages[] = [
                'role' => 'assistant',
                'content' => $message['content'] ?? null,
                'tool_calls' => $appels,
            ];
            foreach ($appels as $appel) {
                $args = json_decode($appel['function']['arguments'] ?? '{}', true);
                $messages[] = [
                    'role' => 'tool',
                    'tool_call_id' => $appel['id'],
                    'content' => json_encode(
                        $outils->executer($appel['function']['name'], is_array($args) ? $args : []),
                        JSON_UNESCAPED_UNICODE
                    ),
                ];
            }
        }

        throw new RuntimeException('OpenRouter : trop d\'appels d\'outils.');
    }
}
