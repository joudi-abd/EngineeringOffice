<?php

namespace App\Providers;

use App\Auth\FirebaseGoogleTokenVerifier;
use App\Auth\GoogleSecureTokenVerifier;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        $this->app->bind(FirebaseGoogleTokenVerifier::class, GoogleSecureTokenVerifier::class);
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        Schema::defaultStringLength(191);
    }
}
