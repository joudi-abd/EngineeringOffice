<?php

namespace App\Http\Controllers\Api\Public;

use App\Http\Controllers\Controller;
use App\Http\Resources\ProjectCategoryResource;
use App\Services\ProjectCategoryService;

class ProjectCategoryController extends Controller
{
    public function __construct(
        private ProjectCategoryService $categoryService
    ) {
    }

    /**
     * Display active categories for the public website.
     */
    public function index()
    {
        $categories = $this->categoryService->getPublicCategories();

        return ProjectCategoryResource::collection($categories);
    }

    /**
     * Display an active category by slug.
     */
    public function show(string $slug)
    {
        $category = $this->categoryService
            ->getPublicCategoryBySlug($slug);

        return new ProjectCategoryResource($category);
    }
}