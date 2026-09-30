<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;

class RoleAndPermissionSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $permissions = [
            'projects.view',
            'projects.create',
            'projects.update',
            'projects.delete',

            'services.view',
            'services.create',
            'services.update',
            'services.delete',

            'categories.view',
            'categories.create',
            'categories.update',
            'categories.delete',

            'team.view',
            'team.create',
            'team.update',
            'team.delete',

            'testimonials.view',
            'testimonials.update',
            'testimonials.delete',

            'messages.view',
            'messages.update',
            'messages.delete',

            'settings.view',
            'settings.update',
        ];
    
        foreach ($permissions as $permission) {
            Permission::firstOrCreate([
                'name' => $permission,
                'guard_name' => 'web',
            ]);
        }
        $siteManager = Role::firstOrCreate([
            'name' => 'site_manager',
            'guard_name' => 'web',
        ]);
        $siteManager->syncPermissions($permissions);
        
    }
}
