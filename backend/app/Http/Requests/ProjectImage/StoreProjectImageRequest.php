<?php

namespace App\Http\Requests\ProjectImage;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

class StoreProjectImageRequest extends FormRequest
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
            'image' => ['required' , 'image' , 'max:5120' , 'mimes:jpeg,png,jpg,gif,svg'],
            'alt_text' => ['nullable' , 'string' , 'max:255'],
        ];
    }
}
