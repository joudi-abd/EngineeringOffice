<?php

namespace App\Services;

use App\Models\Project;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Http\UploadedFile;
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
                'services',
            ])
            ->where('slug', $slug)
            ->where('status', 'completed')
            ->firstOrFail();
    }

    public function getAdminProjects(
        int $perPage = 15
    ): LengthAwarePaginator {
        return Project::query()
            ->with('category')
            ->latest()
            ->paginate($perPage);
    }

    public function create(array $data): Project
    {
        $cover = $data['cover_image'] ?? null;

        unset($data['cover_image']);

        $serviceIds = $data['service_ids'] ?? [];

        unset($data['service_ids']);

        $project = DB::transaction(function () use (
            $data,
            $serviceIds
        ) {
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

            return $project;
        });

        try {
            if ($cover instanceof UploadedFile) {
                $project
                    ->addMedia($cover)
                    ->toMediaCollection('cover_image');
            }
        } catch (\Throwable $e) {
            // Avoid leaving a project behind if its initial cover upload fails.
            DB::transaction(function () use ($project) {
                $project->services()->detach();
                $project->delete();
            });

            throw $e;
        }

        return $project->load([
            'category',
            'services',
        ]);
    }

    public function update(
        Project $project,
        array $data
    ): Project {
        $cover = $data['cover_image'] ?? null;

        unset($data['cover_image']);

        $serviceIds = $data['service_ids'] ?? null;

        unset($data['service_ids']);

        DB::transaction(function () use (
            $project,
            $data,
            $serviceIds
        ) {
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
        });
        if ($cover instanceof UploadedFile) {
            $project
                ->addMedia($cover)
                ->toMediaCollection('cover_image');
        }

        return $project->refresh()->load([
            'category',
            'services',
        ]);
    }

    public function delete(Project $project): void
    {
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