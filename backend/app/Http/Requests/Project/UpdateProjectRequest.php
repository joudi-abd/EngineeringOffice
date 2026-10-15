<?php

namespace App\Http\Requests\Project;

use App\Support\ProjectMediaRules;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateProjectRequest extends FormRequest
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
            'category_id' => ['sometimes', 'integer', 'exists:project_categories,id'],
            'title' => ['sometimes', 'string', 'max:255'],
            'slug' => ['sometimes', 'string', 'max:255', Rule::unique('projects', 'slug')->ignore($this->route('project')?->id)],
            'short_description' => ['nullable', 'string' , 'max:500'],
            'description' => ['nullable', 'string'],
            'location' => ['nullable', 'string', 'max:255'],
            'area' => ['nullable', 'numeric', 'min:0'],
            'year' => ['nullable', 'integer', 'min:1900', 'max:' . (date('Y') + 1)],
            'status' => ['sometimes', Rule::in(['planning', 'in_progress', 'completed'])],
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
