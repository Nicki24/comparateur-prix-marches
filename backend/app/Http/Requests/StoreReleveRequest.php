<?php

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

class StoreReleveRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return $this->user() !== null;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'produit_id' => ['required', 'integer', 'exists:produits,id'],
            'marche_id' => ['required', 'integer', 'exists:marches,id'],
            'valeur' => ['required', 'numeric', 'gt:0', 'max:9999999999'],
            'date_releve' => ['required', 'date', 'before_or_equal:today'],
            'commentaire' => ['nullable', 'string', 'max:1000'],
        ];
    }

    public function messages(): array
    {
        return [
            'valeur.gt' => 'Le prix doit être supérieur à 0.',
            'date_releve.before_or_equal' => 'La date de relevé ne peut pas être dans le futur.',
        ];
    }
}
