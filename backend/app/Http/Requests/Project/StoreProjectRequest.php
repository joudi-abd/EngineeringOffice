<?php

namespace App\Http\Requests\Project;

use App\Support\ProjectMediaRules;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreProjectRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'category_id' => ['required', 'integer', 'exists:project_categories,id'],
            'title' => ['required', 'string', 'max:255'],
            'slug' => ['required', 'string', 'max:255', 'unique:projects,slug'],
            'short_description' => ['nullable', 'string' , 'max:500'],
            'description' => ['nullable', 'string'],
            'location' => ['nullable', 'string', 'max:255'],
            'area' => ['nullable', 'numeric', 'min:0'],
            'year' => ['nullable', 'integer', 'min:1900', 'max:' . (date('Y') + 1)],
            'status' => ['nullable', Rule::in(['planning', 'in_progress', 'completed'])],
            'cover_image' => ProjectMediaRules::image(required: false),
            'is_featured' => ['sometimes', 'boolean'],
            'published_at' => ['nullable', 'date'],
            'service_ids' => ['sometimes', 'array'],
            'service_ids.*' => ['integer', 'exists:services,id'],
        ];
    }

    public function messages(): array
    {
        return ProjectMediaRules::imageMessages('cover_image');
    }
}
