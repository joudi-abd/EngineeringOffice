<?php

namespace App\Http\Requests\Project;

use App\Support\ProjectMediaRules;
use Illuminate\Foundation\Http\FormRequest;

class StoreProjectGalleryImageRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'image' => ProjectMediaRules::image(),

            'title' => [
                'nullable',
                'string',
                'max:150',
            ],

            'description' => [
                'nullable',
                'string',
                'max:1000',
            ],
        ];
    }

    public function messages(): array
    {
        return [
            'image.required' => 'الصورة مطلوبة.',
            ...ProjectMediaRules::imageMessages('image'),

            'title.string' => 'عنوان الصورة يجب أن يكون نصاً.',
            'title.max' => 'عنوان الصورة يجب ألا يتجاوز 150 حرفاً.',

            'description.string' => 'وصف الصورة يجب أن يكون نصاً.',
            'description.max' => 'وصف الصورة يجب ألا يتجاوز 1000 حرف.',
        ];
    }
}