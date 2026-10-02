<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Resend, Postmark, AWS, and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'postmark' => [
        'key' => env('POSTMARK_API_KEY'),
    ],

    'resend' => [
        'key' => env('RESEND_API_KEY'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

    /*
    | Assistant IA MarketScope : fournisseur principal + secours automatique.
    | Les clés restent côté serveur (jamais dans l'application mobile).
    */
    // Fichier de certificats racine pour les appels HTTPS (utile sous Windows).
    'http_ca_bundle' => env('HTTP_CA_BUNDLE'),

    'assistant' => [
        'provider' => env('ASSISTANT_PROVIDER', 'gemini'),
        'limite_minute' => (int) env('ASSISTANT_LIMITE_MINUTE', 8),
        'limite_jour' => (int) env('ASSISTANT_LIMITE_JOUR', 60),
        'gemini' => [
            'key' => env('GEMINI_API_KEY'),
            'model' => env('GEMINI_MODEL', 'gemini-flash-lite-latest'),
        ],
        'openrouter' => [
            'key' => env('OPENROUTER_API_KEY'),
            // Liste séparée par des virgules : OpenRouter essaie dans l'ordre.
            'models' => env('OPENROUTER_MODEL', 'google/gemma-4-31b-it:free'),
        ],
    ],

];
