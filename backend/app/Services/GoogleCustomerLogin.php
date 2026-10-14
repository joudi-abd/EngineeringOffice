<?php

namespace App\Services;

use App\Auth\GoogleIdentity;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;
use Symfony\Component\HttpKernel\Exception\ConflictHttpException;

class GoogleCustomerLogin
{
    public function authenticate(GoogleIdentity $google): User
    {
        $byGoogle = User::query()->where('google_id', $google->googleId)->first();
        $byEmail = User::query()->where('email', $google->email)->first();

        if ($byGoogle && $byEmail && $byGoogle->isNot($byEmail)) {
            throw new ConflictHttpException('This email is associated with another Google account.');
        }

        $user = $byGoogle ?? $byEmail;

        if ($user) {
            return $this->loginExisting($user, $google);
        }

        return $this->register($google);
    }

    private function loginExisting(User $user, GoogleIdentity $google): User
    {
        if ($user->hasRole('site_manager') || $user->hasRole('admin') || $user->hasRole('super_admin')) {
            throw new AccessDeniedHttpException('Google login is available for customers only.');
        }

        if (!$user->hasRole('customer')) {
            throw new AccessDeniedHttpException('This account is not eligible for Google login.');
        }

        if ($user->status !== 'active') {
            throw new AccessDeniedHttpException('Your account is inactive.');
        }

        if ($user->google_id && $user->google_id !== $google->googleId) {
            throw new ConflictHttpException('This email is associated with another Google account.');
        }

        if (!$user->google_id) {
            if (!$user->email_verified_at) {
                throw new AccessDeniedHttpException('Please verify your email before linking Google.');
            }

            $user->google_id = $google->googleId;
        }

        if (!$user->email_verified_at) {
            $user->email_verified_at = now();
        }

        $user->last_login_at = now();
        $user->save();

        return $user;
    }

    private function register(GoogleIdentity $google): User
    {
        $nameParts = preg_split('/\s+/', trim($google->name), 2) ?: [];

        return DB::transaction(function () use ($google, $nameParts) {
            $user = User::query()->create([
                'first_name' => $nameParts[0] ?? '',
                'last_name' => $nameParts[1] ?? '',
                'email' => $google->email,
                'google_id' => $google->googleId,
                'password' => Str::random(40),
                'status' => 'active',
                'last_login_at' => now(),
            ]);

            $user->forceFill([
                'email_verified_at' => now(),
            ])->save();

            $user->assignRole('customer');

            return $user;
        });
    }
}
