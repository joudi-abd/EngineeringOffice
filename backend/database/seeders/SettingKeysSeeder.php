<?php

namespace Database\Seeders;

use App\Models\Setting;
use Illuminate\Database\Seeder;

class SettingKeysSeeder extends Seeder
{
    public function run(): void
    {
        $keys = [
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
        ];

        foreach ($keys as $key) {
            Setting::query()->firstOrCreate(
                ['key' => $key],
                ['value' => null, 'type' => 'string']
            );
        }
    }
}
