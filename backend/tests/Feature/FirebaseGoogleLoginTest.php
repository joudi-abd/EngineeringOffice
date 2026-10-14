<?php

namespace Tests\Feature;

use App\Auth\FirebaseGoogleTokenVerifier;
use App\Auth\GoogleIdentity;
use App\Auth\InvalidFirebaseToken;
use App\Models\User;
use Database\Seeders\RoleAndPermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class FirebaseGoogleLoginTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RoleAndPermissionSeeder::class);
    }

    public function test_new_google_customer_receives_a_token(): void
    {
        $this->fakeGoogle('google-1', 'new@example.com', 'Lina Nasser');

        $response = $this->postJson('/api/auth/google', [
            'id_token' => 'firebase-token',
        ])->assertOk();

        $response->assertJsonPath('data.token_type', 'Bearer');
        $user = User::where('email', 'new@example.com')->firstOrFail();
        $this->assertSame('google-1', $user->google_id);
        $this->assertTrue($user->hasRole('customer'));
        $this->assertNotNull($user->email_verified_at);
        $this->assertNull($user->phone);
    }

    public function test_verified_customer_can_link_google_and_staff_cannot(): void
    {
        $customer = User::create([
            'first_name' => 'Lina',
            'last_name' => 'Nasser',
            'email' => 'customer@example.com',
            'phone' => '0999111001',
            'password' => 'password123',
            'status' => 'active',
        ]);
        $customer->forceFill(['email_verified_at' => now()])->save();
        $customer->assignRole('customer');

        $this->fakeGoogle('google-2', 'customer@example.com', 'Lina Nasser');

        $this->postJson('/api/auth/google', ['id_token' => 'token'])->assertOk();
        $this->assertSame('google-2', $customer->refresh()->google_id);

        $manager = User::create([
            'first_name' => 'Admin',
            'last_name' => 'User',
            'email' => 'admin@example.com',
            'phone' => '0999111002',
            'password' => 'password123',
            'status' => 'active',
        ]);
        $manager->assignRole('site_manager');

        $this->fakeGoogle('google-3', 'admin@example.com', 'Admin User');

        $this->postJson('/api/auth/google', ['id_token' => 'token'])
            ->assertForbidden();
    }

    public function test_invalid_firebase_token_is_rejected(): void
    {
        $this->app->instance(FirebaseGoogleTokenVerifier::class, new class implements FirebaseGoogleTokenVerifier
        {
            public function verify(string $idToken): GoogleIdentity
            {
                throw new InvalidFirebaseToken();
            }
        });

        $this->postJson('/api/auth/google', ['id_token' => 'bad'])
            ->assertUnauthorized();
    }

    private function fakeGoogle(string $googleId, string $email, string $name): void
    {
        $this->app->instance(FirebaseGoogleTokenVerifier::class, new class($googleId, $email, $name) implements FirebaseGoogleTokenVerifier
        {
            public function __construct(
                private string $googleId,
                private string $email,
                private string $name,
            ) {
            }

            public function verify(string $idToken): GoogleIdentity
            {
                return new GoogleIdentity($this->googleId, $this->email, $this->name);
            }
        });
    }
}
