<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ProjectResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'slug' => $this->slug,
            'short_description' => $this->short_description,
            'description' => $this->description,
            'location' => $this->location,
            'area' => $this->area,
            'year' => $this->year,
            'status' => $this->status,
            'cover_image' => $this->coverUrl(),
            'is_featured' => $this->is_featured,
            'published_at' => $this->published_at,
            'category' => $this->whenLoaded('category' , fn () => new ProjectCategoryResource($this->category)),
            'images' => $this->whenLoaded('images', fn () => ProjectImageResource::collection($this->images)),
            'videos' => $this->whenLoaded('videos', fn () => ProjectVideoResource::collection($this->videos)),
            'services' => $this->whenLoaded('services', fn () => ServiceResource::collection($this->services)),
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }

    private function coverUrl(): ?string
    {
        $cover = $this->resource->getFirstMedia('cover_image');

        return $cover?->getUrl();
    }
}
