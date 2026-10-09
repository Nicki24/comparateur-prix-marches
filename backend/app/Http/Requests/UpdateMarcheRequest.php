<?php

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

class UpdateMarcheRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'nom' => ['sometimes', 'string', 'max:120'],
            'localisation' => ['sometimes', 'string', 'max:180'],
            'quartier' => ['nullable', 'string', 'max:120'],
            // Les deux coordonnées vont ensemble (point posé sur la carte).
            'latitude' => ['nullable', 'numeric', 'between:-90,90', 'required_with:longitude'],
            'longitude' => ['nullable', 'numeric', 'between:-180,180', 'required_with:latitude'],
            'description' => ['nullable', 'string'],
            'actif' => ['sometimes', 'boolean'],
        ];
    }
}
