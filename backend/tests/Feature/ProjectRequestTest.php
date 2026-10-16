<?php

namespace Tests\Feature;

use App\Models\ProjectRequest;
use App\Models\ProjectRequestAttachment;
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
        $this->getJson("/api/project-requests/{$id}")->assertForbidden();
        $this->getJson('/api/project-requests')->assertOk()->assertJsonCount(0, 'data');

        Sanctum::actingAs($customer);
        $this->patchJson("/api/project-requests/{$id}/cancel")->assertOk();
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
        $this->patchJson("/api/project-requests/{$id}/cancel")->assertForbidden();
        $this->assertSame('approved', $request->refresh()->status);
    }

    public function test_customer_can_update_a_new_request_and_not_one_already_reviewed(): void
    {
        $customer = $this->customer('lina@example.com');
        $other = $this->customer('other@example.com');
        $second = Service::create([
            'name' => 'Interior',
            'slug' => 'interior',
            'is_active' => true,
        ]);
        Sanctum::actingAs($customer);
        $id = $this->postJson('/api/project-requests', $this->payload())
            ->assertCreated()
            ->json('data.id');

        Sanctum::actingAs($other);
        $this->patchJson("/api/project-requests/{$id}/update", [
            'title' => 'Taken over',
        ])->assertForbidden();

        Sanctum::actingAs($customer);
        $this->patchJson("/api/project-requests/{$id}/update", [
            'title' => 'Updated villa',
            'latitude' => 33.5138,
            'longitude' => 36.2765,
            'service_ids' => [$second->id],
        ])->assertOk()
            ->assertJsonPath('data.title', 'Updated villa')
            ->assertJsonPath('data.services.0.slug', 'interior');

        $request = ProjectRequest::findOrFail($id);
        $this->assertEquals(33.5138, (float) $request->latitude);
        $this->assertTrue($request->services()->whereKey($second->id)->exists());

        $request->update(['status' => ProjectRequest::STATUS_UNDER_REVIEW]);

        $this->patchJson("/api/project-requests/{$id}/update", [
            'title' => 'Too late',
        ])->assertForbidden();
        $this->assertSame('Updated villa', $request->refresh()->title);
    }

    public function test_customer_can_add_and_delete_attachments_only_while_the_request_is_new(): void
    {
        $customer = $this->customer('lina@example.com');
        $other = $this->customer('other@example.com');
        Sanctum::actingAs($customer);
        $id = $this->postJson('/api/project-requests', $this->payload([
            'attachments' => [
                UploadedFile::fake()->create('plan.pdf', 100, 'application/pdf'),
            ],
        ]))->assertCreated()->json('data.id');

        $original = ProjectRequestAttachment::where('project_request_id', $id)->firstOrFail();
        $originalPath = $original->file_path;

        $added = $this->post("/api/project-requests/{$id}/attachments", [
            'attachments' => [
                UploadedFile::fake()->create('extra.pdf', 40, 'application/pdf'),
            ],
        ], ['Accept' => 'application/json'])->assertCreated();

        $addedId = $added->json('data.0.id');
        $this->assertArrayNotHasKey('file_path', $added->json('data.0'));
        $addedPath = ProjectRequestAttachment::findOrFail($addedId)->file_path;
        Storage::disk('local')->assertExists($addedPath);
        $this->assertSame(2, ProjectRequestAttachment::where('project_request_id', $id)->count());

        $tooMany = [];
        for ($index = 0; $index < 9; $index++) {
            $tooMany[] = UploadedFile::fake()->create("more-{$index}.pdf", 20, 'application/pdf');
        }
        $this->post("/api/project-requests/{$id}/attachments", [
            'attachments' => $tooMany,
        ], ['Accept' => 'application/json'])->assertStatus(422);
        $this->assertSame(2, ProjectRequestAttachment::where('project_request_id', $id)->count());

        $this->post("/api/project-requests/{$id}/attachments", [
            'attachments' => [
                UploadedFile::fake()->create('notes.txt', 10, 'text/plain'),
            ],
        ], ['Accept' => 'application/json'])->assertStatus(422);

        Sanctum::actingAs($other);
        $this->post("/api/project-requests/{$id}/attachments", [
            'attachments' => [
                UploadedFile::fake()->create('stolen.pdf', 20, 'application/pdf'),
            ],
        ], ['Accept' => 'application/json'])->assertForbidden();
        $this->deleteJson("/api/project-requests/{$id}/attachments/{$original->id}")->assertForbidden();

        $foreign = ProjectRequest::findOrFail($id);
        Sanctum::actingAs($customer);
        $otherRequest = $this->postJson('/api/project-requests', $this->payload())
            ->assertCreated()
            ->json('data.id');
        $this->deleteJson("/api/project-requests/{$otherRequest}/attachments/{$original->id}")
            ->assertNotFound();
        $this->assertNotNull($foreign->attachments()->find($original->id));

        $this->deleteJson("/api/project-requests/{$id}/attachments/{$original->id}")->assertOk();
        $this->assertDatabaseMissing('project_request_attachments', ['id' => $original->id]);
        Storage::disk('local')->assertMissing($originalPath);

        ProjectRequest::findOrFail($id)->update([
            'status' => ProjectRequest::STATUS_UNDER_REVIEW,
        ]);

        $this->post("/api/project-requests/{$id}/attachments", [
            'attachments' => [
                UploadedFile::fake()->create('late.pdf', 20, 'application/pdf'),
            ],
        ], ['Accept' => 'application/json'])->assertForbidden();
        $this->deleteJson("/api/project-requests/{$id}/attachments/{$addedId}")->assertForbidden();
        Storage::disk('local')->assertExists($addedPath);
    }

    public function test_policy_gates_view_cancel_and_attachment_download(): void
    {
        $customer = $this->customer('lina@example.com');
        $other = $this->customer('other@example.com');
        $manager = $this->manager();
        $guest = User::create([
            'first_name' => 'No',
            'last_name' => 'Role',
            'email' => 'norole@example.com',
            'password' => 'password123',
            'status' => 'active',
        ]);

        Sanctum::actingAs($guest);
        $this->getJson('/api/project-requests')->assertForbidden();

        Sanctum::actingAs($customer);
        $id = $this->postJson('/api/project-requests', $this->payload([
            'attachments' => [
                UploadedFile::fake()->create('plan.pdf', 100, 'application/pdf'),
            ],
        ]))->assertCreated()->json('data.id');
        $attachmentId = ProjectRequestAttachment::where('project_request_id', $id)->value('id');

        $this->get("/api/project-requests/{$id}/attachments/{$attachmentId}/download")
            ->assertOk()
            ->assertDownload('plan.pdf');

        Sanctum::actingAs($other);
        $this->getJson("/api/project-requests/{$id}")->assertForbidden();
        $this->patchJson("/api/project-requests/{$id}/cancel")->assertForbidden();
        $this->getJson("/api/project-requests/{$id}/attachments/{$attachmentId}/download")->assertForbidden();

        Sanctum::actingAs($manager);
        $this->getJson("/api/project-requests/{$id}")->assertOk()->assertJsonPath('data.id', $id);
        $this->get("/api/project-requests/{$id}/attachments/{$attachmentId}/download")->assertOk();
        $this->patchJson("/api/project-requests/{$id}/update", ['title' => 'Staff edit'])->assertForbidden();
        $this->patchJson("/api/project-requests/{$id}/cancel")->assertForbidden();

        Sanctum::actingAs($customer);
        ProjectRequest::findOrFail($id)->update(['status' => ProjectRequest::STATUS_UNDER_REVIEW]);
        $this->patchJson("/api/project-requests/{$id}/update", ['title' => 'Too late'])->assertForbidden();
        $this->patchJson("/api/project-requests/{$id}/cancel")->assertOk();
        $this->assertSame(
            ProjectRequest::STATUS_CANCELLED,
            ProjectRequest::findOrFail($id)->status
        );
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
