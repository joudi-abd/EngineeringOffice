<?php

namespace App\Models;

use App\Support\ProjectMediaRules;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Spatie\MediaLibrary\HasMedia;
use Spatie\MediaLibrary\InteractsWithMedia;

class Project extends Model implements HasMedia
{
    use HasFactory, InteractsWithMedia;

    protected $fillable = [
        'category_id',
        'title',
        'slug',
        'short_description',
        'description',
        'location',
        'area',
        'year',
        'status',
        'is_featured',
        'published_at',
    ];

    protected function casts(): array
    {
        return [
            'area' => 'decimal:2',
            'year' => 'integer',
            'is_featured' => 'boolean',
            'published_at' => 'datetime',
        ];
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(ProjectCategory::class, 'category_id');
    }


    public function services(): BelongsToMany
    {
        return $this->belongsToMany(Service::class, 'project_services')
            ->withPivot('sort_order')
            ->orderByPivot('sort_order');
    }

    public function testimonials(): HasMany
    {
        return $this->hasMany(Testimonial::class);
    }

    public function registerMediaCollections(): void
    {
        $this->addMediaCollection('cover_image')
            ->singleFile()
            ->useDisk('public')
            ->acceptsMimeTypes(ProjectMediaRules::IMAGE_MIME_TYPES)
            ->acceptsFile(ProjectMediaRules::acceptsImage(...));

        $this->addMediaCollection('gallery')
            ->useDisk('public')
            ->acceptsMimeTypes(ProjectMediaRules::IMAGE_MIME_TYPES)
            ->acceptsFile(ProjectMediaRules::acceptsImage(...));

        $this->addMediaCollection('videos')
            ->useDisk('public')
            ->acceptsMimeTypes(ProjectMediaRules::VIDEO_MIME_TYPES)
            ->acceptsFile(ProjectMediaRules::acceptsVideo(...));
    }
}