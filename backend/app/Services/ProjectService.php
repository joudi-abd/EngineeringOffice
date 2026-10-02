<?php

namespace App\Services;

use App\Models\Project;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\ConflictHttpException;

class ProjectService
{
    public function getPublicProjects(
        ?int $categoryId = null,
        ?bool $featuredOnly = null
    ): Collection {
        return Project::query()
            ->with('category')
            ->where('status', 'completed')
            ->when(
                $categoryId,
                fn ($query) => $query->where('category_id', $categoryId)
            )
            ->when(
                $featuredOnly === true,
                fn ($query) => $query->where('is_featured', true)
            )
            ->latest()
            ->get();
    }

    public function getPublicProjectBySlug(string $slug): Project
    {
        return Project::query()
            ->with([
                'category',
                'images',
                'services',
            ])
            ->where('slug', $slug)
            ->where('status', 'completed')
            ->firstOrFail();
    }

    public function getAdminProjects(int $perPage = 15): LengthAwarePaginator
    {
        return Project::query()
            ->with('category')
            ->latest()
            ->paginate($perPage);
    }

    public function create(array $data): Project
    {
        return DB::transaction(function () use ($data) {

            $serviceIds = $data['service_ids'] ?? [];

            unset($data['service_ids']);

            $project = Project::create($data);

            if (!empty($serviceIds)) {
                $project->services()->sync(
                    collect($serviceIds)
                        ->values()
                        ->mapWithKeys(
                            fn ($serviceId, $index) => [
                                $serviceId => [
                                    'sort_order' => $index + 1,
                                ],
                            ]
                        )
                        ->toArray()
                );
            }

            return $project->load([
                'category',
                'services',
                'images',
            ]);
        });
    }

    public function update(
        Project $project,
        array $data
    ): Project {
        return DB::transaction(function () use ($project, $data) {

            $serviceIds = $data['service_ids'] ?? null;

            unset($data['service_ids']);

            $project->update($data);

            if ($serviceIds !== null) {
                $project->services()->sync(
                    collect($serviceIds)
                        ->values()
                        ->mapWithKeys(
                            fn ($serviceId, $index) => [
                                $serviceId => [
                                    'sort_order' => $index + 1,
                                ],
                            ]
                        )
                        ->toArray()
                );
            }

            return $project->refresh()->load([
                'category',
                'services',
                'images',
            ]);
        });
    }

    public function delete(Project $project): void
    {
        if ($project->images()->exists()) {
            throw new ConflictHttpException(
                'This project cannot be deleted because it has images.'
            );
        }

        if ($project->testimonials()->exists()) {
            throw new ConflictHttpException(
                'This project cannot be deleted because it has testimonials.'
            );
        }

        DB::transaction(function () use ($project) {
            $project->services()->detach();
            $project->delete();
        });
    }
}