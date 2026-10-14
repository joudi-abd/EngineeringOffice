<?php

namespace App\Auth;

interface FirebaseGoogleTokenVerifier
{
    public function verify(string $idToken): GoogleIdentity;
}
