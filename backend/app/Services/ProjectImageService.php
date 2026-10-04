<?php

namespace App\Services;

use App\Models\Project;
use App\Models\ProjectImage;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class ProjectImageService
{
    public function getProjectImages(Project $project)
    {
        return $project->images()
            ->latest()
            ->get();
    }

    public function create(Project $project, UploadedFile $image, ?string $altText = null): ProjectImage
    {
        $path = $image->store(
            "projects/{$project->id}/images",
            'public'
        );

        try {
            return DB::transaction(function () use (
                $project,
                $path,
                $altText
            ) {
                return $project->images()->create([
                    'image_path' => $path,
                    'alt_text' => $altText,
                ]);
            });
        } catch (\Throwable $e) {
            Storage::disk('public')->delete($path);

            throw $e;
        }
    }

    public function delete(ProjectImage $image): void
    {
        $path = $image->image_path;

        DB::transaction(function () use ($image) {
            $image->delete();
        });

        if ($path) {
            Storage::disk('public')->delete($path);
        }
    }
}