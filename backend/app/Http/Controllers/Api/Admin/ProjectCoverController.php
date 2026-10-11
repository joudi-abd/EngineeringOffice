<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Project\StoreProjectCoverRequest;
use App\Http\Resources\ProjectCoverResource;
use App\Models\Project;
use App\Services\ProjectCoverService;
use Illuminate\Http\JsonResponse;

class ProjectCoverController extends Controller
{
    public function __construct(
        protected ProjectCoverService $projectCoverService
    ) {}

    /**
     * عرض صورة غلاف المشروع.
     */
    public function show(Project $project): ProjectCoverResource
    {
        $cover = $this->projectCoverService->getCover($project);

        abort_if(
            !$cover,
            404,
            'Project cover image not found.'
        );

        return new ProjectCoverResource($cover);
    }

    /**
     * رفع صورة غلاف المشروع أو استبدالها.
     */
    public function store(
        StoreProjectCoverRequest $request,
        Project $project
    ): JsonResponse {
        $cover = $this->projectCoverService->store(
            $project,
            $request->file('cover')
        );

        return response()->json([
            'message' => 'Project cover image uploaded successfully.',
            'data' => new ProjectCoverResource($cover),
        ], 201);
    }

    /**
     * حذف صورة غلاف المشروع.
     */
    public function destroy(Project $project): JsonResponse
    {
        $deleted = $this->projectCoverService->delete($project);

        abort_if(
            !$deleted,
            404,
            'Project cover image not found.'
        );

        return response()->json([
            'message' => 'Project cover image deleted successfully.',
        ]);
    }
}