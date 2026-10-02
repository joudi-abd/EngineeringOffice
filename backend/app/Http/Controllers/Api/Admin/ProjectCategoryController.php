<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\ProjectCategory\StoreProjectCategoryRequest;
use App\Http\Requests\ProjectCategory\UpdateProjectCategoryRequest;
use App\Http\Resources\ProjectCategoryResource;
use App\Models\ProjectCategory;
use App\Services\ProjectCategoryService;
use Illuminate\Http\Request;

class ProjectCategoryController extends Controller
{
    public function __construct(
        private ProjectCategoryService $categoryService
    ) {
    }

    /**
     * Display a listing of categories.
     */
    public function index()
    {
        $categories = $this->categoryService->getAdminCategories();

        return response()->json([
            'data' => ProjectCategoryResource::collection($categories),
            'meta' => [
                'current_page' => $categories->currentPage(),
                'last_page' => $categories->lastPage(),
                'per_page' => $categories->perPage(),
                'total' => $categories->total(),
            ],
        ]);
    }

    /**
     * Store a newly created category.
     */
    public function store(StoreProjectCategoryRequest $request)
    {
        $category = $this->categoryService->create(
            $request->validated()
        );

        return response()->json([
            'message' => 'Category created successfully.',
            'data' => new ProjectCategoryResource($category),
        ], 201);
    }

    /**
     * Display the specified category.
     */
    public function show(ProjectCategory $category)
    {
        return response()->json([
            'data' => new ProjectCategoryResource($category),
        ]);

    }
    /**
     * Update the specified category.
     */
    public function update(
        UpdateProjectCategoryRequest $request,
        ProjectCategory $category
    ) {
        $category = $this->categoryService->update(
            $category,
            $request->validated()
        );

        return response()->json([
            'message' => 'Category updated successfully.',
            'data' => new ProjectCategoryResource($category),
        ]);
    }

    /**
     * Remove the specified category.
     */
    public function destroy(ProjectCategory $category)
    {
        $this->categoryService->delete($category);

        return response()->json([
            'message' => 'Category deleted successfully.',
        ]);
    }
}