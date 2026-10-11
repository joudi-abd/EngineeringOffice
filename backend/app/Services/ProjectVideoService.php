<?php

namespace App\Services;

use App\Models\Project;
use Illuminate\Http\UploadedFile;
use Spatie\MediaLibrary\MediaCollections\Models\Media;

class ProjectVideoService
{
    /**
     * Upload a new video for a project.
     */
    public function store(
        Project $project,
        UploadedFile $video,
        ?string $title = null,
        ?string $description = null
    ): Media {
        return $project
            ->addMedia($video)
            ->withCustomProperties([
                'title' => $title,
                'description' => $description,
            ])
            ->toMediaCollection('videos');
    }

    /**
     * Get all videos belonging to a project.
     */
    public function getProjectVideos(Project $project)
    {
        return $project->getMedia('videos');
    }

    /**
     * Find a specific video belonging to a project.
     */
    public function findProjectVideo(
        Project $project,
        int $videoId
    ): Media {
        return $project
            ->getMedia('videos')
            ->firstOrFail(
                fn (Media $media) => $media->id === $videoId
            );
    }

    /**
     * Delete a video belonging to a project.
     */
    public function delete(
        Project $project,
        int $videoId
    ): void {
        $video = $this->findProjectVideo($project, $videoId);

        $video->delete();
    }

    /**
     * Update a project's video metadata.
     */
    public function update(
        Project $project,
        int $videoId,
        array $data
    ): Media {
        $video = $this->findProjectVideo($project, $videoId);

        if (array_key_exists('title', $data)) {
            $video->setCustomProperty('title', $data['title']);
        }

        if (array_key_exists('description', $data)) {
            $video->setCustomProperty('description', $data['description']);
        }

        $video->save();

        return $video;
    }
}