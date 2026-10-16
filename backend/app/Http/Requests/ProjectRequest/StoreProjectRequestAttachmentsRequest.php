<?php

namespace App\Http\Requests\ProjectRequest;

use App\Models\ProjectRequest;
use Illuminate\Foundation\Http\FormRequest;

class StoreProjectRequestAttachmentsRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'attachments' => [
                'required',
                'array',
                'min:1',
                'max:'.ProjectRequest::MAX_ATTACHMENTS,
            ],

            'attachments.*' => [
                'required',
                'file',
                'mimes:jpg,jpeg,png,webp,pdf',
                'max:10240',
            ],
        ];
    }

    public function messages(): array
    {
        return [
            'attachments.max' => 'يمكن إرفاق 10 ملفات كحد أقصى.',
            'attachments.*.max' => 'يجب ألا يتجاوز حجم الملف الواحد 10 ميغابايت.',
            'attachments.*.mimes' => 'الملفات المسموحة هي JPG وPNG وWEBP وPDF.',
        ];
    }
}
