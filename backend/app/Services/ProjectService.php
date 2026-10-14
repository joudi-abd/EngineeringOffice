<?php

namespace App\Services;

use App\Models\Project;
use App\Support\StorageUrl;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpKernel\Exception\ConflictHttpException;

class ProjectService
{
    public function getPublicProjects(
        ?int $categoryId = null,
        ?bool $featuredOnly = null
    ): Collection {
        return Project::query()
            ->with(['category', 'images'])
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
                'videos',
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
        $coverPath = $this->storeCover($data);

        try {
            return DB::transaction(function () use ($data, $coverPath) {

            $serviceIds = $data['service_ids'] ?? [];

            unset($data['service_ids']);

            if ($coverPath) {
                $data['cover_image'] = $coverPath;
            }

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
                'videos',
            ]);
            });
        } catch (\Throwable $e) {
            if ($coverPath) {
                Storage::disk('public')->delete($coverPath);
            }

            throw $e;
        }
    }

    public function update(
        Project $project,
        array $data
    ): Project {
        $coverPath = $this->storeCover($data);
        $previousCover = StorageUrl::relative($project->cover_image);

        try {
            $updated = DB::transaction(function () use ($project, $data, $coverPath) {

            $serviceIds = $data['service_ids'] ?? null;

            unset($data['service_ids']);

            if ($coverPath) {
                $data['cover_image'] = $coverPath;
            }

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
                'videos',
            ]);
            });

            if ($coverPath && $previousCover && $previousCover !== $coverPath) {
                Storage::disk('public')->delete($previousCover);
            }

            return $updated;
        } catch (\Throwable $e) {
            if ($coverPath) {
                Storage::disk('public')->delete($coverPath);
            }

            throw $e;
        }
    }

    private function storeCover(array &$data): ?string
    {
        $image = $data['cover_image'] ?? null;
        unset($data['cover_image']);

        if (!$image instanceof UploadedFile) {
            return null;
        }

        return $image->store('projects/covers', 'public');
    }

    public function delete(Project $project): void
    {
        if ($project->testimonials()->exists()) {
            throw new ConflictHttpException(
                'This project cannot be deleted because it has testimonials.'
            );
        }

        $project->load(['images', 'videos']);

        $files = array_filter([
            StorageUrl::relative($project->cover_image),
            ...$project->images->pluck('image_path')->all(),
            ...$project->videos->pluck('video_path')->all(),
        ]);

        DB::transaction(function () use ($project) {
            $project->services()->detach();
            $project->images()->delete();
            $project->videos()->delete();
            $project->delete();
        });

        foreach ($files as $file) {
            $relative = StorageUrl::relative($file);

            if ($relative) {
                Storage::disk('public')->delete($relative);
            }
        }

        Storage::disk('public')->deleteDirectory("projects/{$project->id}");
    }
}
