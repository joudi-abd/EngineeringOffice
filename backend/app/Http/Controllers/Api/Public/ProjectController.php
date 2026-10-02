<?php

namespace App\Http\Controllers\Api\Public;

use App\Http\Controllers\Controller;
use App\Http\Resources\ProjectResource;
use App\Services\ProjectService;
use Illuminate\Http\Request;

class ProjectController extends Controller
{
    public function __construct(
        private ProjectService $projectService
    ) {
    }

    public function index(Request $request)
    {
        $projects = $this->projectService->getPublicProjects(
            $request->integer('category_id') ?: null,
            $request->boolean('featured')
        );

        return response()->json([
            'data' => ProjectResource::collection($projects),
        ]);
    }

    public function show(string $slug)
    {
        $project = $this->projectService
            ->getPublicProjectBySlug($slug);

        return response()->json([
            'data' => new ProjectResource($project),
        ]);
    }
}