<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Support\Facades\Hash;
use App\Auth\FirebaseGoogleTokenVerifier;
use App\Auth\FirebaseVerificationUnavailable;
use App\Auth\InvalidFirebaseToken;
use App\Http\Requests\Auth\GoogleLoginRequest;
use App\Services\GoogleCustomerLogin;
use Illuminate\Http\JsonResponse;

class SocialController extends Controller
{
    public function loginWithGoogle(
        GoogleLoginRequest $request,
        FirebaseGoogleTokenVerifier $tokens,
        GoogleCustomerLogin $login,
    ): JsonResponse {
        try {
            $identity = $tokens->verify($request->string('id_token')->toString());
        } catch (InvalidFirebaseToken) {
            return response()->json([
                'success' => false,
                'message' => 'Firebase token is invalid.',
            ], 401);
        } catch (FirebaseVerificationUnavailable) {
            return response()->json([
                'success' => false,
                'message' => 'Firebase authentication is unavailable.',
            ], 503);
        }

        $user = $login->authenticate($identity);
        $token = $user->createToken('firebase-google')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Google login successful.',
            'data' => [
                'user' => $user->load('roles'),
                'token' => $token,
                'token_type' => 'Bearer',
            ],
        ]);
    }
}
