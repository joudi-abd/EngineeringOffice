<?php

namespace App\Auth;

use Firebase\JWT\JWT;
use Firebase\JWT\Key;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use stdClass;
use Throwable;

class GoogleSecureTokenVerifier implements FirebaseGoogleTokenVerifier
{
    private const CERTS_URL = 'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com';

    public function verify(string $idToken): GoogleIdentity
    {
        $projectId = (string) config('services.firebase.project_id');

        if ($projectId === '') {
            throw new FirebaseVerificationUnavailable('Firebase project id is not configured.');
        }

        try {
            $claims = JWT::decode($idToken, $this->keys());
        } catch (FirebaseVerificationUnavailable $exception) {
            throw $exception;
        } catch (Throwable) {
            throw new InvalidFirebaseToken('Firebase token could not be verified.');
        }

        $this->assertProjectClaims($claims, $projectId);

        $googleId = $this->googleAccountId($claims);

        if ($googleId === null || !is_string($claims->email ?? null) || $claims->email === '' || ($claims->email_verified ?? false) !== true) {
            throw new InvalidFirebaseToken('Firebase token is not a verified Google login.');
        }

        return new GoogleIdentity(
            googleId: $googleId,
            email: mb_strtolower($claims->email),
            name: is_string($claims->name ?? null) ? $claims->name : '',
        );
    }

    private function assertProjectClaims(stdClass $claims, string $projectId): void
    {
        $subject = $claims->sub ?? null;

        if (
            ($claims->aud ?? null) !== $projectId
            || ($claims->iss ?? null) !== 'https://securetoken.google.com/'.$projectId
            || !is_string($subject)
            || $subject === ''
        ) {
            throw new InvalidFirebaseToken('Firebase token does not belong to this project.');
        }
    }

    private function googleAccountId(stdClass $claims): ?string
    {
        $firebase = $claims->firebase ?? null;

        if (!$firebase instanceof stdClass || ($firebase->sign_in_provider ?? null) !== 'google.com') {
            return null;
        }

        $identities = $firebase->identities ?? null;
        $ids = $identities instanceof stdClass ? ($identities->{'google.com'} ?? null) : null;
        $googleId = is_array($ids) ? ($ids[0] ?? null) : null;

        return is_string($googleId) && $googleId !== '' ? $googleId : null;
    }

    /**
     * @return array<string, Key>
     */
    private function keys(): array
    {
        $certificates = Cache::get('firebase.securetoken.certificates');

        if (!is_array($certificates)) {
            $certificates = $this->fetchCertificates();
        }

        $keys = [];

        foreach ($certificates as $keyId => $certificate) {
            if (is_string($keyId) && is_string($certificate) && $certificate !== '') {
                $keys[$keyId] = new Key($certificate, 'RS256');
            }
        }

        if ($keys === []) {
            throw new FirebaseVerificationUnavailable('Firebase signing keys are unavailable.');
        }

        return $keys;
    }

    /**
     * @return array<string, string>
     */
    private function fetchCertificates(): array
    {
        try {
            $response = Http::timeout(5)
                ->acceptJson()
                ->get(self::CERTS_URL);
        } catch (Throwable $exception) {
            throw new FirebaseVerificationUnavailable(
                'Could not connect to Firebase signing keys endpoint.',
                previous: $exception
            );
        }

        $certificates = $response->json();

        if (!$response->successful() || !is_array($certificates)) {
            throw new FirebaseVerificationUnavailable(
                'Firebase signing keys could not be downloaded.'
            );
        }

        $ttl = 3600;

        if (
            preg_match(
                '/max-age=(\d+)/',
                (string) $response->header('Cache-Control'),
                $matches
            ) === 1
        ) {
            $ttl = max(60, (int) $matches[1]);
        }

        Cache::put('firebase.securetoken.certificates', $certificates, $ttl);

        return $certificates;
    }
}
