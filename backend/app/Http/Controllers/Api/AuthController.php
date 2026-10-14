<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Services\EmailVerificationService;
use App\Services\PasswordResetService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function register(
        Request $request,
        EmailVerificationService $verificationService,
    ) {
        $data = $request->validate([
            'first_name' => ['required', 'string', 'max:100'],
            'last_name' => ['required', 'string', 'max:100'],
            'email' => ['required', 'string', 'email', 'max:255', 'unique:users,email'],
            'phone' => ['required', 'string', 'max:20', 'unique:users,phone', 'regex:/^\+?[0-9\s\-()]{7,20}$/'],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
        ]);

        $user = DB::transaction(function () use ($data) {
            $user = User::create([
                'first_name' => $data['first_name'],
                'last_name' => $data['last_name'],
                'email' => $data['email'],
                'phone' => $data['phone'],
                'password' => $data['password'],
                'status' => 'active',
            ]);

            $user->assignRole('customer');

            return $user;
        });

        try {
            $verificationService->sendCode($user);
        } catch (\Throwable $exception) {
            report($exception);

            $user->roles()->detach();
            $user->delete();

            throw $exception;
        }

        return response()->json([
            'message' => 'Account created successfully. Please verify your email.',
        ], 201);
    }

    public function verifyEmail(
        Request $request,
        EmailVerificationService $verificationService,
    ) {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'code' => ['required', 'digits:6'],
        ]);

        $user = User::where('email', $data['email'])
            ->whereHas('roles', function ($query) {
                $query->where('name', 'customer');
            })
            ->first();

        if (!$user) {
            return response()->json([
                'message' => 'Invalid verification request.',
            ], 422);
        }

        if ($user->email_verified_at) {
            return response()->json([
                'message' => 'Email is already verified.',
            ], 422);
        }

        $verificationService->verifyCode($user, $data['code']);

        return response()->json([
            'message' => 'Email verified successfully. You can now log in.',
        ]);
    }

    public function resendVerificationCode(
        Request $request,
        EmailVerificationService $verificationService,
    ) {
        $data = $request->validate([
            'email' => ['required', 'email'],
        ]);

        $user = User::where('email', $data['email'])
            ->whereHas('roles', function ($query) {
                $query->where('name', 'customer');
            })
            ->first();

        if (!$user || $user->email_verified_at) {
            return response()->json([
                'message' => 'If the account requires verification, a code will be sent.',
            ]);
        }

        $verificationService->sendCode($user);

        return response()->json([
            'message' => 'Verification code sent if the request was allowed.',
        ]);
    }

    public function forgotPassword(Request $request, PasswordResetService $resets)
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
        ]);

        $resets->sendCode($data['email']);

        return response()->json([
            'message' => 'If an account exists for this email, a reset code has been sent.',
        ]);
    }

    public function resetPassword(Request $request, PasswordResetService $resets)
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'code' => ['required', 'digits:6'],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
        ]);

        $resets->reset($data['email'], $data['code'], $data['password']);

        return response()->json([
            'message' => 'Password reset successfully. You can now log in.',
        ]);
    }

    public function login(Request $request)
    {
        $credentials = $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
        ]);
        $user = User::where('email', $credentials['email'])->first();
        if (!$user || !Hash::check($credentials['password'], $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['The provided credentials are incorrect.'],
            ]);
        }
        if ($user->status !== 'active') {
            return response()->json([
                'message' => 'Your account is inactive. Please contact the administrator.',
            ], 403);
        }

        if ($user->hasRole('customer') && !$user->email_verified_at) {
            return response()->json([
                'message' => 'Please verify your email address to login.',
                'email_verified' => false,
            ], 403);
        }

        $user->update(['last_login_at' => now()]);
        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Login successful',
            'access_token' => $token,
            'user' => $user->load('roles'),
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Logout successful',
        ]);
    }

    public function me(Request $request)
    {
        return response()->json($request->user()->load('roles'));
    }
}
