<?php

namespace App\Services;

use App\Models\Setting;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;

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

            $setting->update($data);

            return $setting->refresh();
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
                'facebook',
                'instagram',
                'linkedin',
                'logo',
            ])
            ->get();
    }
}