<?php

namespace App\Http\Requests\ProjectRequest;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateProjectRequestRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null
            && $this->user()->hasRole('customer');
    }

    public function rules(): array
    {
        return [
            'title' => ['sometimes', 'required', 'string', 'max:255'],

            'description' => [
                'sometimes',
                'required',
                'string',
                'max:10000',
            ],

            'location' => [
                'sometimes',
                'required',
                'string',
                'max:255',
            ],

            'area' => [
                'sometimes',
                'nullable',
                'numeric',
                'gt:0',
                'max:99999999.99',
            ],

            'budget' => [
                'sometimes',
                'nullable',
                'numeric',
                'min:0',
                'max:9999999999999.99',
            ],

            'preferred_start_date' => [
                'sometimes',
                'nullable',
                'date',
                'after_or_equal:today',
            ],

            'service_ids' => [
                'sometimes',
                'required',
                'array',
                'min:1',
                'max:20',
            ],

            'service_ids.*' => [
                'required',
                'integer',
                'distinct',
                Rule::exists('services', 'id')
                    ->where('is_active', true),
            ],
            'latitude' => [
                'sometimes',
                'nullable',
                'numeric',
                'min:-90',
                'max:90',
            ],
            'longitude' => [
                'sometimes',
                'nullable',
                'numeric',
                'min:-180',
                'max:180',
            ],
        ];
    }
}