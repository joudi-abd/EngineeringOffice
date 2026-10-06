<?php

namespace App\Services;

use App\Models\Setting;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class SettingService
{
    public function getAdminSettings(): Collection
    {
        return Setting::query()
            ->orderBy('key')
            ->get();
    }

    public function getAdminSetting(string $key): Setting
    {
        return Setting::query()
            ->where('key', $key)
            ->firstOrFail();
    }

    public function update(
        string $key,
        array $data
    ): Setting {
        return DB::transaction(function () use ($key, $data) {
            $setting = Setting::query()
                ->where('key', $key)
                ->firstOrFail();

            $previous = $setting->value;
            $storedLogo = null;

            if (($data['value'] ?? null) instanceof UploadedFile) {
                $storedLogo = $data['value']->store('settings', 'public');
                $data['value'] = $storedLogo;
                $data['type'] = 'string';
            } elseif ($key === 'logo' && ($data['value'] ?? null) === '') {
                $data['value'] = null;
            }

            try {
                $setting->update($data);
            } catch (\Throwable $error) {
                if ($storedLogo) {
                    Storage::disk('public')->delete($storedLogo);
                }
                throw $error;
            }

            $setting->refresh();

            if ($key === 'logo' && $previous && $previous !== $setting->value && !str_starts_with((string) $previous, 'http')) {
                Storage::disk('public')->delete($previous);
            }

            return $setting;
        });
    }

    public function getPublicSettings(): Collection
    {
        return Setting::query()
            ->whereIn('key', [
                'company_name',
                'company_description',
                'phone',
                'email',
                'address',
                'whatsapp',
                'hours',
                'facebook',
                'instagram',
                'linkedin',
                'logo',
            ])
            ->get();
    }
}