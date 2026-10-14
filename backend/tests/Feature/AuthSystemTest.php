<?php

namespace Tests\Feature;

use App\Mail\EmailVerificationMail;
use App\Mail\PasswordResetMail;
use App\Models\PasswordResetCode;
use App\Models\User;
use Database\Seeders\RoleAndPermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use Laravel\Sanctum\PersonalAccessToken;
use Tests\TestCase;

class AuthSystemTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RoleAndPermissionSeeder::class);
    }

    public function test_customer_must_verify_email_before_login(): void
    {
        Mail::fake();

        $this->postJson('/api/auth/register', [
            'first_name' => 'Lina',
            'last_name' => 'Nasser',
            'email' => 'lina@example.com',
            'phone' => '0999111001',
            'password' => 'password123',
            'password_confirmation' => 'password123',
            'role' => 'site_manager',
        ])->assertCreated();

        $user = User::where('email', 'lina@example.com')->firstOrFail();
        $this->assertTrue($user->hasRole('customer'));
        $this->assertFalse($user->hasRole('site_manager'));
        $this->assertNull($user->email_verified_at);

        $this->postJson('/api/auth/login', [
            'email' => 'lina@example.com',
            'password' => 'password123',
        ])->assertForbidden()->assertJsonPath('email_verified', false);

        $code = null;
        Mail::assertSent(EmailVerificationMail::class, function (EmailVerificationMail $mail) use (&$code) {
            $code = $mail->code;

            return true;
        });

        $this->postJson('/api/auth/verify-email', [
            'email' => 'lina@example.com',
            'code' => $code,
        ])->assertOk();

        $this->postJson('/api/auth/login', [
            'email' => 'lina@example.com',
            'password' => 'password123',
        ])->assertOk()->assertJsonStructure(['access_token', 'user']);
    }

    public function test_staff_can_login_without_email_verification(): void
    {
        $manager = User::create([
            'first_name' => 'Site',
            'last_name' => 'Manager',
            'email' => 'admin@example.com',
            'password' => 'password123',
            'status' => 'active',
        ]);
        $manager->assignRole('site_manager');

        $this->postJson('/api/auth/login', [
            'email' => 'admin@example.com',
            'password' => 'password123',
        ])->assertOk();
    }

    public function test_inactive_user_cannot_login(): void
    {
        $user = User::create([
            'first_name' => 'Lina',
            'last_name' => 'Nasser',
            'email' => 'lina@example.com',
            'password' => 'password123',
            'status' => 'inactive',
        ]);
        $user->forceFill(['email_verified_at' => now()])->save();
        $user->assignRole('customer');

        $this->postJson('/api/auth/login', [
            'email' => 'lina@example.com',
            'password' => 'password123',
        ])->assertForbidden();
    }

    public function test_password_reset_replaces_the_password_and_revokes_tokens(): void
    {
        Mail::fake();

        $user = User::create([
            'first_name' => 'Lina',
            'last_name' => 'Nasser',
            'email' => 'lina@example.com',
            'password' => 'password123',
            'status' => 'active',
        ]);
        $user->forceFill(['email_verified_at' => now()])->save();
        $user->assignRole('customer');
        $oldToken = $user->createToken('auth_token')->plainTextToken;

        $this->postJson('/api/auth/forgot-password', [
            'email' => 'missing@example.com',
        ])->assertOk();
        Mail::assertNothingSent();

        $this->postJson('/api/auth/forgot-password', [
            'email' => 'lina@example.com',
        ])->assertOk();

        $code = null;
        Mail::assertSent(PasswordResetMail::class, function (PasswordResetMail $mail) use (&$code) {
            $code = $mail->code;

            return true;
        });

        $this->travel(30)->seconds();
        $this->postJson('/api/auth/forgot-password', [
            'email' => 'lina@example.com',
        ])->assertStatus(422);

        $this->postJson('/api/auth/reset-password', [
            'email' => 'lina@example.com',
            'code' => '000000',
            'password' => 'new-password',
            'password_confirmation' => 'new-password',
        ])->assertStatus(422);
        $this->assertSame(1, PasswordResetCode::first()->attempts);

        $this->postJson('/api/auth/reset-password', [
            'email' => 'lina@example.com',
            'code' => $code,
            'password' => 'new-password',
            'password_confirmation' => 'new-password',
        ])->assertOk();

        $this->assertNull(PasswordResetCode::first());
        $this->assertNull(PersonalAccessToken::findToken($oldToken));

        $this->postJson('/api/auth/login', [
            'email' => 'lina@example.com',
            'password' => 'password123',
        ])->assertStatus(422);

        $this->postJson('/api/auth/login', [
            'email' => 'lina@example.com',
            'password' => 'new-password',
        ])->assertOk();
    }

    public function test_expired_reset_code_and_inactive_account_are_rejected(): void
    {
        Mail::fake();

        $user = User::create([
            'first_name' => 'Lina',
            'last_name' => 'Nasser',
            'email' => 'lina@example.com',
            'password' => 'password123',
            'status' => 'active',
        ]);
        $user->assignRole('customer');

        $this->postJson('/api/auth/forgot-password', [
            'email' => 'lina@example.com',
        ])->assertOk();

        $code = null;
        Mail::assertSent(PasswordResetMail::class, function (PasswordResetMail $mail) use (&$code) {
            $code = $mail->code;

            return true;
        });

        $this->travel(11)->minutes();

        $this->postJson('/api/auth/reset-password', [
            'email' => 'lina@example.com',
            'code' => $code,
            'password' => 'new-password',
            'password_confirmation' => 'new-password',
        ])->assertStatus(422);
        $this->assertNull(PasswordResetCode::first());

        $user->update(['status' => 'inactive']);
        Mail::fake();

        $this->postJson('/api/auth/forgot-password', [
            'email' => 'lina@example.com',
        ])->assertOk();
        Mail::assertNothingSent();
    }

    public function test_fifth_wrong_reset_attempt_deletes_the_code(): void
    {
        Mail::fake();

        $user = User::create([
            'first_name' => 'Lina',
            'last_name' => 'Nasser',
            'email' => 'lina@example.com',
            'password' => 'password123',
            'status' => 'active',
        ]);
        $user->assignRole('customer');

        $this->postJson('/api/auth/forgot-password', [
            'email' => 'lina@example.com',
        ])->assertOk();

        $code = null;
        Mail::assertSent(PasswordResetMail::class, function (PasswordResetMail $mail) use (&$code) {
            $code = $mail->code;

            return true;
        });

        for ($attempt = 1; $attempt <= 4; $attempt++) {
            $this->postJson('/api/auth/reset-password', [
                'email' => 'lina@example.com',
                'code' => '000000',
                'password' => 'new-password',
                'password_confirmation' => 'new-password',
            ])->assertStatus(422);
            $this->assertSame($attempt, PasswordResetCode::first()->attempts);
        }

        $this->postJson('/api/auth/reset-password', [
            'email' => 'lina@example.com',
            'code' => '000000',
            'password' => 'new-password',
            'password_confirmation' => 'new-password',
        ])->assertStatus(422)->assertJsonPath('errors.code.0', 'Too many attempts. Request a new reset code.');

        $this->assertNull(PasswordResetCode::first());

        $this->travel(61)->seconds();

        $this->postJson('/api/auth/reset-password', [
            'email' => 'lina@example.com',
            'code' => $code,
            'password' => 'new-password',
            'password_confirmation' => 'new-password',
        ])->assertStatus(422)->assertJsonPath('errors.code.0', 'No reset code was found.');
    }
}
