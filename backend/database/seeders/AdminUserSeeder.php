<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Role;

class AdminUserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $user = User::firstOrCreate([
            'email' => 'admin@gmail.com',
        ], [
            'first_name' => 'Site',
            'last_name' => 'Manager',
            'password' => 'password',
            'status' => 'active',
        ]);
        $role = Role::where('name', 'site_manager')->where('guard_name', 'web')->firstOrFail();
        $user->assignRole($role);
    }
}
