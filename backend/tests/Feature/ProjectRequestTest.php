<?php

namespace Tests\Feature;

use App\Models\ProjectRequest;
use App\Models\Service;
use App\Models\User;
use Database\Seeders\RoleAndPermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ProjectRequestTest extends TestCase
{
    use RefreshDatabase;

    private Service $service;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RoleAndPermissionSeeder::class);
        Storage::fake('local');
        $this->service = Service::create([
            'name' => 'Architecture',
            'slug' => 'architecture',
            'is_active' => true,
        ]);
    }

    public function test_customer_can_create_list_and_cancel_only_their_request(): void
    {
        $customer = $this->customer('lina@example.com');
        $other = $this->customer('other@example.com');
        Sanctum::actingAs($customer);

        $created = $this->post('/api/project-requests', [
            'title' => 'Villa in Damascus',
            'description' => 'A family house.',
            'location' => 'Damascus',
            'area' => 240,
            'budget' => 50000,
            'preferred_start_date' => now()->addWeek()->toDateString(),
            'service_ids' => [$this->service->id],
            'attachments' => [
                UploadedFile::fake()->create('plan.pdf', 100, 'application/pdf'),
            ],
        ], ['Accept' => 'application/json'])->assertCreated();

        $id = $created->json('data.id');
        $this->assertSame('new', $created->json('data.status'));
        $this->assertSame('Architecture', $created->json('data.services.0.name'));
        $this->assertSame('plan.pdf', $created->json('data.attachments.0.original_name'));
        Storage::disk('local')->assertExists(
            ProjectRequest::findOrFail($id)->attachments()->value('file_path')
        );

        $this->getJson('/api/project-requests')->assertOk()->assertJsonCount(1, 'data');

        Sanctum::actingAs($other);
        $this->getJson("/api/project-requests/{$id}")->assertNotFound();
        $this->getJson('/api/project-requests')->assertOk()->assertJsonCount(0, 'data');

        Sanctum::actingAs($customer);
        $this->patchJson("/api/project-requests/{$id}")->assertOk();
        $this->assertSame('cancelled', ProjectRequest::findOrFail($id)->status);
    }

    public function test_staff_cannot_submit_and_inactive_service_is_rejected(): void
    {
        $this->postJson('/api/project-requests', [])->assertUnauthorized();

        $manager = $this->manager();
        Sanctum::actingAs($manager);
        $this->postJson('/api/project-requests', $this->payload())->assertForbidden();

        Sanctum::actingAs($this->customer('lina@example.com'));
        $inactive = Service::create([
            'name' => 'Paused',
            'slug' => 'paused',
            'is_active' => false,
        ]);

        $this->postJson('/api/project-requests', $this->payload([
            'service_ids' => [$inactive->id],
        ]))->assertStatus(422);
    }

    public function test_manager_can_review_a_request_and_customer_cannot_open_admin_routes(): void
    {
        $customer = $this->customer('lina@example.com');
        Sanctum::actingAs($customer);
        $id = $this->postJson('/api/project-requests', $this->payload())
            ->assertCreated()
            ->json('data.id');

        $this->getJson('/api/admin/project-requests')->assertForbidden();

        Sanctum::actingAs($this->manager());
        $this->getJson('/api/admin/project-requests')->assertOk()->assertJsonCount(1, 'data');
        $this->getJson("/api/admin/project-requests/{$id}")->assertOk();

        $this->patchJson("/api/admin/project-requests/{$id}", [
            'status' => 'approved',
            'admin_notes' => 'Ready for a quote.',
        ])->assertOk();

        $request = ProjectRequest::findOrFail($id);
        $this->assertSame('approved', $request->status);
        $this->assertSame('Ready for a quote.', $request->admin_notes);

        Sanctum::actingAs($customer);
        $this->patchJson("/api/project-requests/{$id}")->assertStatus(422);
        $this->assertSame('approved', $request->refresh()->status);
    }

    private function payload(array $extra = []): array
    {
        return array_merge([
            'title' => 'Villa in Damascus',
            'description' => 'A family house.',
            'location' => 'Damascus',
            'service_ids' => [$this->service->id],
        ], $extra);
    }

    private function customer(string $email): User
    {
        $user = User::create([
            'first_name' => 'Lina',
            'last_name' => 'Nasser',
            'email' => $email,
            'password' => 'password123',
            'status' => 'active',
        ]);
        $user->assignRole('customer');

        return $user;
    }

    private function manager(): User
    {
        $user = User::create([
            'first_name' => 'Site',
            'last_name' => 'Manager',
            'email' => 'admin@example.com',
            'password' => 'password123',
            'status' => 'active',
        ]);
        $user->assignRole('site_manager');

        return $user;
    }
}
