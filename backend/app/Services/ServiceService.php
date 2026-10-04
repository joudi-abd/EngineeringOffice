<?php

namespace App\Services;

use App\Models\Service;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\ConflictHttpException;

class ServiceService
{
    public function getPublicServices(): Collection
    {
        return Service::query()
            ->where('is_active', true)
            ->orderBy('name')
            ->get();
    }

    public function getPublicServiceBySlug(string $slug): Service
    {
        return Service::query()
            ->where('slug', $slug)
            ->where('is_active', true)
            ->firstOrFail();
    }

    public function getAdminServices(int $perPage = 15): LengthAwarePaginator
    {
        return Service::query()
            ->orderBy('name')
            ->paginate($perPage);
    }

    public function create(array $data): Service
    {
        return DB::transaction(function () use ($data) {
            return Service::create($data);
        });
    }

    public function update(Service $service, array $data): Service
    {
        return DB::transaction(function () use ($service, $data) {
            $service->update($data);

            return $service->refresh();
        });
    }

    public function delete(Service $service): void
    {
        if ($service->projects()->exists()) {
            throw new ConflictHttpException(
                'This service cannot be deleted because it is assigned to projects.'
            );
        }

        DB::transaction(function () use ($service) {
            $service->delete();
        });
    }
}