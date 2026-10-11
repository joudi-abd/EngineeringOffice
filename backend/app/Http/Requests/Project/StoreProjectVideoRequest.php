<?php

namespace App\Http\Requests\Project;

use Illuminate\Foundation\Http\FormRequest;

class StoreProjectVideoRequest extends FormRequest
{
    /**
     * Determine whether the user is authorized
     * to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     */
    public function rules(): array
    {
        return [
            'video' => [
                'required',
                'file',
                'mimes:mp4,webm,mov',
                'max:102400',
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

    /**
     * Custom validation messages.
     */
    public function messages(): array
    {
        return [
            'video.required' => 'يجب اختيار فيديو للمشروع.',
            'video.file' => 'الملف المرفوع يجب أن يكون ملفاً صالحاً.',
            'video.mimes' => 'صيغة الفيديو يجب أن تكون MP4 أو WebM أو MOV.',
            'video.max' => 'حجم الفيديو يجب ألا يتجاوز 100 ميغابايت.',

            'title.string' => 'عنوان الفيديو يجب أن يكون نصاً.',
            'title.max' => 'عنوان الفيديو يجب ألا يتجاوز 150 حرفاً.',

            'description.string' => 'وصف الفيديو يجب أن يكون نصاً.',
            'description.max' => 'وصف الفيديو يجب ألا يتجاوز 1000 حرف.',
        ];
    }
}