<?php

namespace App\Http\Requests\ProjectRequest;

use App\Models\ProjectRequest;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreProjectRequestRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null
            && $this->user()->hasRole('customer');
    }

    public function rules(): array
    {
        return [
            'title' => [
                'required',
                'string',
                'max:255',
            ],

            'description' => [
                'required',
                'string',
                'max:10000',
            ],

            'location' => [
                'required',
                'string',
                'max:255',
            ],

            'area' => [
                'nullable',
                'numeric',
                'gt:0',
                'max:99999999.99',
            ],

            'budget' => [
                'nullable',
                'numeric',
                'min:0',
                'max:9999999999999.99',
            ],

            'preferred_start_date' => [
                'nullable',
                'date',
                'after_or_equal:today',
            ],

            'service_ids' => [
                'required',
                'array',
                'min:1',
                'max:20',
            ],

            'service_ids.*' => [
                'required',
                'integer',
                'distinct',
                Rule::exists('services', 'id')
                    ->where('is_active', true),
            ],

            'attachments' => [
                'nullable',
                'array',
                'max:'.ProjectRequest::MAX_ATTACHMENTS,
            ],

            'attachments.*' => [
                'required',
                'file',
                'mimes:jpg,jpeg,png,webp,pdf',
                'max:10240',
            ],
            'latitude' => [
                'nullable',
                'numeric',
                'min:-90',
                'max:90',
            ],
            'longitude' => [
                'nullable',
                'numeric',
                'min:-180',
                'max:180',
            ],
        ];
    }

    public function messages(): array
    {
        return [
            'service_ids.required' =>
                'يجب اختيار خدمة واحدة على الأقل.',

            'service_ids.*.exists' =>
                'إحدى الخدمات المختارة غير موجودة أو غير فعالة.',

            'service_ids.*.distinct' =>
                'لا يمكن اختيار الخدمة نفسها أكثر من مرة.',

            'attachments.max' =>
                'يمكن إرفاق 10 ملفات كحد أقصى.',

            'attachments.*.max' =>
                'يجب ألا يتجاوز حجم الملف الواحد 10 ميغابايت.',

            'attachments.*.mimes' =>
                'الملفات المسموحة هي JPG وPNG وWEBP وPDF.',
        ];
    }
}