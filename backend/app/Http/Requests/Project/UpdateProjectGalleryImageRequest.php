<?php

namespace App\Http\Requests\Project;

use Illuminate\Foundation\Http\FormRequest;

class UpdateProjectGalleryImageRequest extends FormRequest
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
            'title.string' => 'عنوان الصورة يجب أن يكون نصاً.',
            'title.max' => 'عنوان الصورة يجب ألا يتجاوز 150 حرفاً.',

            'description.string' => 'وصف الصورة يجب أن يكون نصاً.',
            'description.max' => 'وصف الصورة يجب ألا يتجاوز 1000 حرف.',
        ];
    }
}