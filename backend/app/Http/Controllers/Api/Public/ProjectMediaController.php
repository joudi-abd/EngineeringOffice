<?php

namespace App\Http\Controllers\Api\Public;

use App\Http\Controllers\Controller;
use App\Http\Resources\ProjectGalleryImageResource;
use App\Http\Resources\ProjectVideoResource;
use App\Models\Project;
use App\Support\StorageUrl;
use Illuminate\Http\JsonResponse;

class ProjectMediaController extends Controller
{
    /**
     * Get the cover image of a project.
     */
    public function cover(string $slug): JsonResponse
    {
        $project = $this->findPublishedProject($slug);

        $cover = $project->getFirstMedia('cover_image');

        if (!$cover) {
            return response()->json([
                'message' => 'This project does not have a cover image.',
            ], 404);
        }

        return response()->json([
            'data' => [
                'id' => $cover->id,
                'project_id' => $project->id,
                'url' => $cover->getUrl(),
                'file_name' => $cover->file_name,
                'mime_type' => $cover->mime_type,
                'size' => $cover->size,
                'size_in_mb' => round($cover->size / 1048576, 2),
            ],
        ]);
    }
        /**
     * Get gallery images of a project.
     */
    public function gallery(string $slug): JsonResponse
    {
        $project = $this->findPublishedProject($slug);

        $images = $project->getMedia('gallery');

        return response()->json([
            'data' => ProjectGalleryImageResource::collection($images),
        ]);
    }

    /**
     * Get videos of a project.
     */
    public function videos(string $slug): JsonResponse
    {
        $project = $this->findPublishedProject($slug);

        $videos = $project->getMedia('videos');

        return response()->json([
            'data' => ProjectVideoResource::collection($videos),
        ]);
    }

    /**
     * Find a project available to public visitors.
     */
    private function findPublishedProject(string $slug): Project
    {
        return Project::query()
            ->where('slug', $slug)
            ->firstOrFail();
    }
}