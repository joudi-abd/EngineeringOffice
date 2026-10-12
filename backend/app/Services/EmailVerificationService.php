<?php

namespace App\Services;

use App\Mail\EmailVerificationMail;
use App\Models\EmailVerificationCode;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Validation\ValidationException;

class EmailVerificationService
{
    public function sendCode(User $user): void
    {
        $verification = EmailVerificationCode::firstOrNew([
            'user_id' => $user->id,
        ]);

        if (
            $verification->exists &&
            $verification->last_sent_at &&
            $verification->last_sent_at->gt(now()->subMinute())
        ) {
            throw ValidationException::withMessages([
                'email' => [
                    'Please wait before requesting another verification code.',
                ],
            ]);
        }

        $code = (string) random_int(100000, 999999);

        try {
            Mail::to($user->email)->send(
                new EmailVerificationMail($code)
            );
        } catch (\Throwable $exception) {
            report($exception);

            throw ValidationException::withMessages([
                'email' => [
                    'Unable to send the verification email. Please try again later.',
                ],
            ]);
        }

        $verification->fill([
            'code_hash' => Hash::make($code),
            'expires_at' => now()->addMinutes(10),
            'attempts' => 0,
            'last_sent_at' => now(),
        ]);

        $verification->save();
    }

    public function verifyCode(User $user, string $code): void
    {
        $failure = null;

        DB::transaction(function () use ($user, $code, &$failure) {
            $verification = EmailVerificationCode::query()
                ->where('user_id', $user->id)
                ->lockForUpdate()
                ->first();

            if (!$verification) {
                $failure = ValidationException::withMessages([
                    'code' => ['No verification code was found.'],
                ]);

                return;
            }

            if ($verification->expires_at->isPast()) {
                $verification->delete();

                $failure = ValidationException::withMessages([
                    'code' => ['The verification code has expired.'],
                ]);

                return;
            }

            if ($verification->attempts >= 5) {
                $verification->delete();

                $failure = ValidationException::withMessages([
                    'code' => [
                        'Too many attempts. Request a new verification code.',
                    ],
                ]);

                return;
            }

            if (!Hash::check($code, $verification->code_hash)) {
                $verification->increment('attempts');

                if ($verification->attempts >= 5) {
                    $verification->delete();

                    $failure = ValidationException::withMessages([
                        'code' => [
                            'Too many attempts. Request a new verification code.',
                        ],
                    ]);

                    return;
                }

                $failure = ValidationException::withMessages([
                    'code' => ['The verification code is incorrect.'],
                ]);

                return;
            }

            $user->forceFill([
                'email_verified_at' => now(),
            ])->save();

            $verification->delete();
        });

        if ($failure) {
            throw $failure;
        }
    }
}