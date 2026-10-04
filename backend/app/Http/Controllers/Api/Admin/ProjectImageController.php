<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\ProjectImage\StoreProjectImageRequest;
use App\Http\Resources\ProjectImageResource;
use App\Models\Project;
use App\Models\ProjectImage;
use App\Services\ProjectImageService;
use Illuminate\Http\JsonResponse;

class ProjectImageController extends Controller
{
    public function __construct(
        private ProjectImageService $imageService
    ) {}

    public function index(Project $project): JsonResponse
    {
        $images = $this->imageService->getProjectImages($project);

        return response()->json([
            'data' => ProjectImageResource::collection($images),
        ]);
    }

    public function store(StoreProjectImageRequest $request, Project $project): JsonResponse 
    {
        $image = $this->imageService->create(
            $project,
            $request->file('image'),
            $request->input('alt_text')
        );

        return response()->json([
            'message' => 'Project image uploaded successfully.',
            'data' => new ProjectImageResource($image),
        ], 201);
    }

    public function destroy(Project $project, ProjectImage $image): JsonResponse 
    {
        $this->imageService->delete($image);

        return response()->json([
            'message' => 'Project image deleted successfully.',
        ]);
    }
}