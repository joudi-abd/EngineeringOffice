<?php

namespace App\Http\Requests\Project;

use App\Support\ProjectMediaRules;
use Illuminate\Foundation\Http\FormRequest;

class StoreProjectCoverRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'cover' => ProjectMediaRules::image(),
        ];
    }

    public function messages(): array
    {
        return [
            'cover.required' => 'يجب اختيار صورة لغلاف المشروع.',
            ...ProjectMediaRules::imageMessages('cover'),
        ];
    }
}