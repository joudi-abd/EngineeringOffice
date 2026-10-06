<?php

namespace App\Http\Requests\Setting;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateSettingRequest extends FormRequest
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
        if ($this->route('key') === 'logo' && $this->hasFile('value')) {
            return [
                'value' => ['nullable', 'image', 'max:5120', 'mimes:jpeg,png,jpg,webp'],
                'type' => ['sometimes', 'string', Rule::in(['string', 'integer', 'boolean', 'json', 'array', 'text', 'url'])],
            ];
        }

        return [
            'value' => ['nullable', 'string', 'max:5000'],
            'type' => ['sometimes', 'string', Rule::in(['string', 'integer', 'boolean', 'json', 'array', 'text', 'url'])],
        ];
    }
}
