<?php

namespace App\Services;

use App\Mail\PasswordResetMail;
use App\Models\PasswordResetCode;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Validation\ValidationException;

class PasswordResetService
{
    public function sendCode(string $email): void
    {
        $user = User::query()->where('email', $email)->first();

        if (!$user || $user->status !== 'active') {
            return;
        }

        $reset = PasswordResetCode::firstOrNew([
            'user_id' => $user->id,
        ]);

        if (
            $reset->exists
            && $reset->last_sent_at
            && $reset->last_sent_at->gt(now()->subMinute())
        ) {
            throw ValidationException::withMessages([
                'email' => ['Please wait before requesting another reset code.'],
            ]);
        }

        $code = (string) random_int(100000, 999999);

        try {
            Mail::to($user->email)->send(new PasswordResetMail($code));
        } catch (\Throwable $exception) {
            report($exception);

            throw ValidationException::withMessages([
                'email' => ['Unable to send the reset email. Please try again later.'],
            ]);
        }

        $reset->fill([
            'code_hash' => Hash::make($code),
            'expires_at' => now()->addMinutes(10),
            'attempts' => 0,
            'last_sent_at' => now(),
        ])->save();
    }

    public function reset(string $email, string $code, string $password): void
    {
        $user = User::query()->where('email', $email)->first();

        if (!$user || $user->status !== 'active') {
            throw ValidationException::withMessages([
                'code' => ['The reset code is incorrect.'],
            ]);
        }

        $failure = null;

        DB::transaction(function () use ($user, $code, $password, &$failure) {
            $reset = PasswordResetCode::query()
                ->where('user_id', $user->id)
                ->lockForUpdate()
                ->first();

            if (!$reset) {
                $failure = ValidationException::withMessages([
                    'code' => ['No reset code was found.'],
                ]);

                return;
            }

            if ($reset->expires_at->isPast()) {
                $reset->delete();

                $failure = ValidationException::withMessages([
                    'code' => ['The reset code has expired.'],
                ]);

                return;
            }

            if ($reset->attempts >= 5) {
                $reset->delete();

                $failure = ValidationException::withMessages([
                    'code' => ['Too many attempts. Request a new reset code.'],
                ]);

                return;
            }

            if (!Hash::check($code, $reset->code_hash)) {
                $reset->increment('attempts');

                if ($reset->attempts >= 5) {
                    $reset->delete();

                    $failure = ValidationException::withMessages([
                        'code' => ['Too many attempts. Request a new reset code.'],
                    ]);

                    return;
                }

                $failure = ValidationException::withMessages([
                    'code' => ['The reset code is incorrect.'],
                ]);

                return;
            }

            $user->password = $password;
            $user->save();
            $user->tokens()->delete();
            $reset->delete();
        });

        if ($failure) {
            throw $failure;
        }
    }
}
