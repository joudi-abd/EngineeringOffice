<?php

namespace App\Http\Requests\ProjectVideo;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

class StoreProjectVideoRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'title' => ['nullable', 'string', 'max:255'],
            'video' => [
                'nullable',
                'required_without:external_url',
                'file',
                'mimetypes:video/mp4,video/webm,video/quicktime',
                'max:204800',
            ],
            'external_url' => [
                'nullable',
                'required_without:video',
                'url:http,https',
                'max:500',
            ],
        ];
    }
}
