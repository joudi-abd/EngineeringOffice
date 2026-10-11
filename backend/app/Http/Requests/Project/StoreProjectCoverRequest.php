<?php

namespace App\Http\Requests\Project;

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
            'cover' => [
                'required',
                'image',
                'mimes:jpg,jpeg,png,webp',
                'max:5120',
            ],
        ];
    }

    public function messages(): array
    {
        return [
            'cover.required' => 'يجب اختيار صورة لغلاف المشروع.',
            'cover.image' => 'الملف المرفوع يجب أن يكون صورة.',
            'cover.mimes' => 'صيغة الصورة يجب أن تكون JPG أو JPEG أو PNG أو WebP.',
            'cover.max' => 'حجم صورة الغلاف يجب ألا يتجاوز 5 ميغابايت.',
        ];
    }
}