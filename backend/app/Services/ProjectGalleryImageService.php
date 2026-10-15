<?php

namespace App\Services;

use App\Models\Project;
use App\Support\ProjectMediaRules;
use Illuminate\Http\UploadedFile;
use Spatie\MediaLibrary\MediaCollections\Models\Media;

class ProjectGalleryImageService
{
    /**
     * إضافة صورة جديدة إلى معرض المشروع.
     */
    public function store(
        Project $project,
        UploadedFile $image,
        ?string $title = null,
        ?string $description = null
    ): Media {
        return ProjectMediaRules::store(
            fn () => $project
                ->addMedia($image)
                ->withCustomProperties([
                    'title' => $title,
                    'description' => $description,
                ])
                ->toMediaCollection('gallery'),
            'image',
            'image',
        );
    }

    /**
     * جلب جميع صور معرض المشروع.
     */
    public function getProjectImages(Project $project)
    {
        return $project->getMedia('gallery');
    }

    /**
     * جلب صورة محددة من معرض المشروع.
     *
     * نبحث ضمن صور المشروع نفسه للتأكد من أن
     * الصورة المطلوبة تتبع للمشروع المحدد.
     */
    public function findProjectImage(
        Project $project,
        int $imageId
    ): Media {
        return $project->getMedia('gallery')->firstOrFail(
            fn (Media $media) => $media->id === $imageId
        );
    }

    /**
     * تعديل عنوان الصورة ووصفها.
     */
    public function update(
        Project $project,
        int $imageId,
        array $data
    ): Media {
        $image = $this->findProjectImage(
            $project,
            $imageId
        );

        if (array_key_exists('title', $data)) {
            $image->setCustomProperty(
                'title',
                $data['title']
            );
        }

        if (array_key_exists('description', $data)) {
            $image->setCustomProperty(
                'description',
                $data['description']
            );
        }

        $image->save();

        return $image;
    }

    /**
     * حذف صورة من معرض المشروع.
     */
    public function delete(
        Project $project,
        int $imageId
    ): void {
        $image = $this->findProjectImage(
            $project,
            $imageId
        );

        $image->delete();
    }
}