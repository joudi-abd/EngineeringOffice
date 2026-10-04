<?php

namespace App\Http\Requests\Testimonial;

use Illuminate\Foundation\Http\FormRequest;

class StoreTestimonialRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'client_name' => [
                'required',
                'string',
                'max:255',
            ],

            'client_email' => [
                'required',
                'email',
                'max:255',
            ],

            'content' => [
                'required',
                'string',
                'max:2000',
            ],

            'rating' => [
                'required',
                'integer',
                'between:1,5',
            ],
        ];
    }
}