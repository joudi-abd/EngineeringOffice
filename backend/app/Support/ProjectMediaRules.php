<?php

namespace App\Support;

use Spatie\MediaLibrary\MediaCollections\File;

final class ProjectMediaRules
{
    public const IMAGE_EXTENSIONS = ['jpg', 'jpeg', 'png', 'webp'];

    public const IMAGE_MIME_TYPES = [
        'image/jpeg',
        'image/png',
        'image/webp',
    ];

    public const IMAGE_MAX_KILOBYTES = 5120;

    public const IMAGE_MAX_BYTES = self::IMAGE_MAX_KILOBYTES * 1024;

    public const VIDEO_EXTENSIONS = ['mp4', 'webm', 'mov'];

    public const VIDEO_MIME_TYPES = [
        'video/mp4',
        'video/webm',
        'video/quicktime',
    ];

    public const VIDEO_MAX_KILOBYTES = 102400;

    public const VIDEO_MAX_BYTES = self::VIDEO_MAX_KILOBYTES * 1024;

    public static function image(bool $required = true): array
    {
        return [
            $required ? 'required' : 'nullable',
            'image',
            'mimes:'.implode(',', self::IMAGE_EXTENSIONS),
            'mimetypes:'.implode(',', self::IMAGE_MIME_TYPES),
            'max:'.self::IMAGE_MAX_KILOBYTES,
        ];
    }

    public static function video(bool $required = true): array
    {
        return [
            $required ? 'required' : 'nullable',
            'file',
            'mimes:'.implode(',', self::VIDEO_EXTENSIONS),
            'mimetypes:'.implode(',', self::VIDEO_MIME_TYPES),
            'max:'.self::VIDEO_MAX_KILOBYTES,
        ];
    }

    public static function acceptsImage(File $file, mixed $subject = null): bool
    {
        return $file->size <= self::IMAGE_MAX_BYTES;
    }

    public static function acceptsVideo(File $file, mixed $subject = null): bool
    {
        return $file->size <= self::VIDEO_MAX_BYTES;
    }

    public static function imageMessages(string $attribute): array
    {
        return [
            "{$attribute}.image" => 'يجب أن يكون الملف صورة.',
            "{$attribute}.mimes" => 'يُسمح بصيغ JPG و JPEG و PNG و WebP فقط.',
            "{$attribute}.mimetypes" => 'يُسمح بصيغ JPG و JPEG و PNG و WebP فقط.',
            "{$attribute}.max" => 'يجب ألا يتجاوز حجم الصورة 5 ميغابايت.',
        ];
    }

    public static function videoMessages(string $attribute): array
    {
        return [
            "{$attribute}.file" => 'الملف المرفوع يجب أن يكون ملفاً صالحاً.',
            "{$attribute}.mimes" => 'صيغة الفيديو يجب أن تكون MP4 أو WebM أو MOV.',
            "{$attribute}.mimetypes" => 'صيغة الفيديو يجب أن تكون MP4 أو WebM أو MOV.',
            "{$attribute}.max" => 'يجب ألا يتجاوز حجم الفيديو 100 ميغابايت.',
        ];
    }
}
