<?php

namespace App\Support;

use Illuminate\Support\Facades\Storage;

class StorageUrl
{
    public static function public(?string $path): ?string
    {
        $relative = self::relative($path);

        if ($relative === null || !Storage::disk('public')->exists($relative)) {
            return null;
        }

        return request()->getSchemeAndHttpHost().'/storage/'.$relative;
    }

    public static function relative(?string $path): ?string
    {
        if ($path === null || trim($path) === '') {
            return null;
        }

        $path = str_replace('\\', '/', trim($path));

        if (preg_match('#^https?://#i', $path) === 1) {
            $pathname = parse_url($path, PHP_URL_PATH) ?: '';
            $marker = strpos($pathname, '/storage/');
            if ($marker === false) {
                return null;
            }
            $path = substr($pathname, $marker + strlen('/storage/'));
        }

        $path = ltrim($path, '/');

        if (str_starts_with($path, 'storage/')) {
            $path = substr($path, strlen('storage/'));
        }

        if (
            $path === ''
            || str_contains($path, '..')
            || str_starts_with($path, 'tmp/')
            || str_contains($path, '/tmp/')
        ) {
            return null;
        }

        return $path;
    }
}
