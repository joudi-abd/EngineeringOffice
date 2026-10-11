<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Project\StoreProjectGalleryImageRequest;
use App\Http\Requests\Project\UpdateProjectGalleryImageRequest;
use App\Http\Resources\ProjectGalleryImageResource;
use App\Models\Project;
use App\Services\ProjectGalleryImageService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class ProjectGalleryImageController extends Controller
{
    public function __construct(
        protected ProjectGalleryImageService $projectGalleryImageService
    ) {}

    /**
     * عرض جميع صور معرض المشروع.
     */
    public function index(
        Project $project
    ): AnonymousResourceCollection {
        $images = $this->projectGalleryImageService
            ->getProjectImages($project);

        return ProjectGalleryImageResource::collection(
            $images
        );
    }

    /**
     * رفع صورة جديدة إلى معرض المشروع.
     */
    public function store(
        StoreProjectGalleryImageRequest $request,
        Project $project
    ): JsonResponse {
        $image = $this->projectGalleryImageService->store(
            project: $project,
            image: $request->file('image'),
            title: $request->input('title'),
            description: $request->input('description'),
        );

        return response()->json([
            'message' => 'Image uploaded successfully to the project gallery.',
            'data' => new ProjectGalleryImageResource($image),
        ], 201);
    }

    /**
     * عرض بيانات صورة محددة.
     */
    public function show(
        Project $project,
        int $image
    ): ProjectGalleryImageResource {
        $projectImage = $this->projectGalleryImageService
            ->findProjectImage($project, $image);

        return new ProjectGalleryImageResource(
            $projectImage
        );
    }

    /**
     * تعديل بيانات صورة محددة.
     */
    public function update(
        UpdateProjectGalleryImageRequest $request,
        Project $project,
        int $image
    ): ProjectGalleryImageResource {
        $updatedImage = $this->projectGalleryImageService->update(
            project: $project,
            imageId: $image,
            data: $request->validated(),
        );

        return new ProjectGalleryImageResource(
            $updatedImage
        );
    }

    /**
     * حذف صورة من معرض المشروع.
     */
    public function destroy(
        Project $project,
        int $image
    ): JsonResponse {
        $this->projectGalleryImageService->delete(
            $project,
            $image
        );

        return response()->json([
            'message' => 'Image deleted successfully from the project gallery.',
        ]);
    }
}