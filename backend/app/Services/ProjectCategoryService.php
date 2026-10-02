<?php

namespace App\Services;

use App\Models\ProjectCategory;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\ConflictHttpException;

class ProjectCategoryService
{
    /**
     * Create a new class instance.
     */
    public function __construct()
    {
        //
    }

    /**
     * Get all active project categories for the public website.
      */
    public function getPublicCategories(): Collection
    {
        return ProjectCategory::query()
            ->where('is_active', true)
            ->orderBy('name')
            ->get();
    }

    /**
     * Get all active category by slug for the public website
      */
    public function getPublicCategoryBySlug(string $slug): ?ProjectCategory
    {
        return ProjectCategory::query()
            ->where('is_active', true)
            ->where('slug', $slug)
            ->firstOrFail();
    }

    /**
     * Get all categories for the admin dashboard
     */

    public function getAdminCategories(int $perPage = 15): LengthAwarePaginator
    {
        return ProjectCategory::query()
            ->orderBy('name')
            ->paginate($perPage);
    }


    /**
     * Create a new project category
     */

    public function create(array $data): ?ProjectCategory
    {
        return DB::transaction(function () use ($data){
            return ProjectCategory::create($data);
        });
    }

    /**
     * Update an existing project category
     */

    public function update(ProjectCategory $category , array $data): ?ProjectCategory
    {
        return DB::transaction(function () use ($category, $data){
            $category->update($data);
            return $category->refresh();
        });
    }

    /**
     * Delete a project category 
     */

    public function delete(ProjectCategory $category): void
    {
        if($category->projects()->exists()){
            throw new ConflictHttpException('This category cannot be deleted because it has projects.');
        }

        DB::transaction(function () use ($category){
            $category->delete();
        });
    }
}
