<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ProjectRequest extends Model
{
    use HasFactory;

    public const STATUS_NEW = 'new';
    public const STATUS_UNDER_REVIEW = 'under_review';
    public const STATUS_CONTACTED = 'contacted';
    public const STATUS_QUOTED = 'quoted';
    public const STATUS_APPROVED = 'approved';
    public const STATUS_REJECTED = 'rejected';
    public const STATUS_CANCELLED = 'cancelled';

    public const MAX_ATTACHMENTS = 10;

    public const STATUSES = [
        self::STATUS_NEW,
        self::STATUS_UNDER_REVIEW,
        self::STATUS_CONTACTED,
        self::STATUS_QUOTED,
        self::STATUS_APPROVED,
        self::STATUS_REJECTED,
        self::STATUS_CANCELLED,
    ];

    protected $fillable = [
        'title',
        'description',
        'location',
        'area',
        'budget',
        'preferred_start_date',
        'status',
        'admin_notes',
        'latitude',
        'longitude',
    ];

    protected function casts(): array
    {
        return [
            'area' => 'decimal:2',
            'budget' => 'decimal:2',
            'preferred_start_date' => 'date',
            'latitude' => 'decimal:7',
            'longitude' => 'decimal:7',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function services(): BelongsToMany
    {
        return $this->belongsToMany(
            Service::class,
            'project_request_services'
        )->withTimestamps();
    }

    public function attachments(): HasMany
    {
        return $this->hasMany(ProjectRequestAttachment::class);
    }
}