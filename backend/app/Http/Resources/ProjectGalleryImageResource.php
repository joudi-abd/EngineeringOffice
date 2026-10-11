<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ProjectGalleryImageResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,

            'project_id' => $this->model_id,

            'title' => $this->getCustomProperty('title'),

            'description' => $this->getCustomProperty('description'),

            'url' => $this->getUrl(),

            'file_name' => $this->file_name,

            'mime_type' => $this->mime_type,

            'size' => $this->size,

            'size_in_mb' => round(
                $this->size / 1024 / 1024,
                2
            ),

            'created_at' => $this->created_at?->toISOString(),

            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}