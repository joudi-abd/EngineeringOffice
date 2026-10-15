<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ProjectRequestAttachment extends Model
{
    use HasFactory;

    protected $fillable = [
        'file_path',
        'original_name',
        'mime_type',
        'file_size',
    ];

    public function projectRequest(): BelongsTo
    {
        return $this->belongsTo(
            ProjectRequest::class,
            'project_request_id'
        );
    }
}