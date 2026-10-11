<?php

namespace App\Http\Requests\Project;

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
            'image' => [
                'required',
                'image',
                'mimes:jpg,jpeg,png,webp',
                'max:5120',
            ],

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
            'image.image' => 'يجب أن يكون الملف صورة.',
            'image.mimes' => 'يُسمح بصيغ JPG وJPEG وPNG وWEBP فقط.',
            'image.max' => 'يجب ألا يتجاوز حجم الصورة 5 ميغابايت.',

            'title.string' => 'عنوان الصورة يجب أن يكون نصاً.',
            'title.max' => 'عنوان الصورة يجب ألا يتجاوز 150 حرفاً.',

            'description.string' => 'وصف الصورة يجب أن يكون نصاً.',
            'description.max' => 'وصف الصورة يجب ألا يتجاوز 1000 حرف.',
        ];
    }
}