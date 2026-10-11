<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Project\StoreProjectVideoRequest;
use App\Http\Requests\Project\UpdateProjectVideoRequest;
use App\Http\Resources\ProjectVideoResource;
use App\Models\Project;
use App\Services\ProjectVideoService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class ProjectVideoController extends Controller
{
    public function __construct(
        protected ProjectVideoService $projectVideoService
    ) {}

    /**
     * Display all videos belonging to a project.
     */
    public function index(
        Project $project
    ): AnonymousResourceCollection {
        $videos = $this->projectVideoService
            ->getProjectVideos($project);

        return ProjectVideoResource::collection($videos);
    }

    /**
     * Store a new video for a project.
     */
    public function store(
        StoreProjectVideoRequest $request,
        Project $project
    ): JsonResponse {
        $video = $this->projectVideoService->store(
            project: $project,
            video: $request->file('video'),
            title: $request->input('title'),
            description: $request->input('description'),
        );

        return response()->json([
            'message' => 'Project video uploaded successfully.',
            'data' => new ProjectVideoResource($video),
        ], 201);
    }

    /**
     * Display a specific project video.
     */
    public function show(
        Project $project,
        int $video
    ): ProjectVideoResource {
        $projectVideo = $this->projectVideoService
            ->findProjectVideo($project, $video);

        return new ProjectVideoResource($projectVideo);
    }

    /**
     * Delete a project video.
     */
    public function destroy(
        Project $project,
        int $video
    ): JsonResponse {
        $this->projectVideoService->delete(
            $project,
            $video
        );

        return response()->json([
            'message' => 'Project video deleted successfully.',
        ]);
    }

    /**
     * Update a project's video metadata.
     */
    public function update(
        UpdateProjectVideoRequest $request,
        Project $project,
        int $video
    ): ProjectVideoResource {
        $updatedVideo = $this->projectVideoService->update(
            $project,
            $video,
            $request->validated()
        );

        return new ProjectVideoResource($updatedVideo);
    }
}