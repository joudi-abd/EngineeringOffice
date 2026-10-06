<?php

namespace App\Services;

use App\Models\Service;
use App\Support\StorageUrl;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
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
        $imagePath = $this->storeImage($data);

        try {
            return DB::transaction(function () use ($data, $imagePath) {
                if ($imagePath) {
                    $data['image'] = $imagePath;
                }

                return Service::create($data);
            });
        } catch (\Throwable $e) {
            if ($imagePath) {
                Storage::disk('public')->delete($imagePath);
            }

            throw $e;
        }
    }

    public function update(Service $service, array $data): Service
    {
        $imagePath = $this->storeImage($data);
        $previous = StorageUrl::relative($service->image);

        try {
            $updated = DB::transaction(function () use ($service, $data, $imagePath) {
                if ($imagePath) {
                    $data['image'] = $imagePath;
                }

                $service->update($data);

                return $service->refresh();
            });

            if ($imagePath && $previous && $previous !== $imagePath) {
                Storage::disk('public')->delete($previous);
            }

            return $updated;
        } catch (\Throwable $e) {
            if ($imagePath) {
                Storage::disk('public')->delete($imagePath);
            }

            throw $e;
        }
    }

    private function storeImage(array &$data): ?string
    {
        $image = $data['image'] ?? null;
        unset($data['image']);

        if (!$image instanceof UploadedFile) {
            return null;
        }

        return $image->store('services', 'public');
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