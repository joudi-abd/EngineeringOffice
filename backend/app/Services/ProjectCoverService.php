<?php

namespace App\Services;

use App\Models\Project;
use Illuminate\Http\UploadedFile;
use Spatie\MediaLibrary\MediaCollections\Models\Media;

class ProjectCoverService
{
    /**
     * Upload or replace a project's cover image.
     */
    public function store(
        Project $project,
        UploadedFile $cover
    ): Media {
        return $project
            ->addMedia($cover)
            ->toMediaCollection('cover_image');
    }

    /**
     * Get the project's current cover image.
     */
    public function getCover(Project $project): ?Media
    {
        return $project->getFirstMedia('cover_image');
    }

    /**
     * Delete the project's current cover image.
     */
    public function delete(Project $project): bool
    {
        $cover = $this->getCover($project);

        if (! $cover) {
            return false;
        }

        $cover->delete();

        return true;
    }
}