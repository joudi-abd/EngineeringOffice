<?php

namespace App\Http\Requests\Project;

use Illuminate\Foundation\Http\FormRequest;

class UpdateProjectVideoRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'title' => [
                'sometimes',
                'nullable',
                'string',
                'max:150',
            ],

            'description' => [
                'sometimes',
                'nullable',
                'string',
                'max:1000',
            ],
        ];
    }

    public function messages(): array
    {
        return [
            'title.string' => 'عنوان الفيديو يجب أن يكون نصاً.',
            'title.max' => 'عنوان الفيديو يجب ألا يتجاوز 150 حرفاً.',

            'description.string' => 'وصف الفيديو يجب أن يكون نصاً.',
            'description.max' => 'وصف الفيديو يجب ألا يتجاوز 1000 حرف.',
        ];
    }
}