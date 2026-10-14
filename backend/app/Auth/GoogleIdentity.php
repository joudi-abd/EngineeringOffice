<?php

namespace App\Auth;

final class GoogleIdentity
{
    public function __construct(
        public string $googleId,
        public string $email,
        public string $name,
    ) {
    }
}
