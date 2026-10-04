<?php

namespace App\Http\Requests\Testimonial;

use Illuminate\Foundation\Http\FormRequest;

class UpdateTestimonialRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'client_name' => [
                'sometimes',
                'string',
                'max:255',
            ],

            'client_email' => [
                'sometimes',
                'email',
                'max:255',
            ],

            'content' => [
                'sometimes',
                'string',
                'max:2000',
            ],

            'rating' => [
                'sometimes',
                'integer',
                'between:1,5',
            ],
        ];
    }
}