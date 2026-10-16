<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ProjectRequestResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,

            'title' => $this->title,
            'description' => $this->description,
            'location' => $this->location,
            'latitude' => $this->latitude,
            'longitude' => $this->longitude,

            'area' => $this->area,
            'budget' => $this->budget,

            'preferred_start_date' => $this->preferred_start_date
                ? $this->preferred_start_date->toDateString()
                : null,

            'status' => $this->status,

            'admin_notes' => $request->user()?->hasRole([
                'site_manager',
                'admin',
                'super_admin',
            ]) ? $this->admin_notes : null,
            'user' => $this->when(request()->user()?->hasAnyRole([
                    'site_manager',
                    'admin',
                    'super_admin',
                ]), fn () => $this->whenLoaded('user', function() {
                    return [
                        'id' => $this->user->id,
                        'first_name' => $this->user->first_name,
                        'last_name' => $this->user->last_name,
                        'email' => $this->user->email,
                        'phone' => $this->user->phone,
                    ];
                })
            ),

            'services' => $this->whenLoaded(
                'services',
                fn () => $this->services->map(fn ($service) => [
                    'id' => $service->id,
                    'name' => $service->name,
                    'slug' => $service->slug,
                ])
            ),

            'attachments' => ProjectRequestAttachmentResource::collection(
                $this->whenLoaded('attachments')
            ),

            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}