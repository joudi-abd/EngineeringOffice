<?php

namespace Tests\Feature;

use App\Models\Project;
use App\Models\ProjectCategory;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ProjectMediaTest extends TestCase
{
    use RefreshDatabase;

    private ProjectCategory $category;

    protected function setUp(): void
    {
        parent::setUp();

        Storage::fake('public');
        $this->seed();
        Sanctum::actingAs(User::where('email', 'admin@gmail.com')->firstOrFail());
        $this->category = ProjectCategory::create(['name' => 'Villas', 'slug' => 'villas']);
    }

    private function payload(array $extra = []): array
    {
        return array_merge([
            'category_id' => $this->category->id,
            'title' => 'Villa One',
            'slug' => 'villa-one',
            'status' => 'completed',
        ], $extra);
    }

    public function test_create_project_stores_cover_and_serves_it(): void
    {
        $response = $this->post('/api/admin/projects', $this->payload([
            'cover_image' => UploadedFile::fake()->image('cover.jpg', 800, 600),
        ]), ['Accept' => 'application/json']);

        $response->assertCreated();
        $cover = Project::firstOrFail()->getFirstMedia('cover_image');
        $this->assertNotNull($cover);
        Storage::disk('public')->assertExists($cover->getPathRelativeToRoot());
        $this->assertNotEmpty($response->json('data.cover_image'));
    }

    public function test_update_with_multipart_post_override_keeps_and_replaces_cover(): void
    {
        $created = $this->post('/api/admin/projects', $this->payload([
            'cover_image' => UploadedFile::fake()->image('a.jpg'),
        ]), ['Accept' => 'application/json'])->assertCreated();
        $old = Project::firstOrFail()->getFirstMedia('cover_image');
        $oldPath = $old->getPathRelativeToRoot();

        $this->post('/api/admin/projects/'.$created->json('data.id'), [
            '_method' => 'PUT',
            'title' => 'Villa One Renamed',
            'cover_image' => UploadedFile::fake()->image('b.jpg'),
        ], ['Accept' => 'application/json'])->assertOk();

        $project = Project::firstOrFail();
        $cover = $project->getFirstMedia('cover_image');
        $this->assertSame('Villa One Renamed', $project->title);
        $this->assertNotSame($old->id, $cover->id);
        Storage::disk('public')->assertMissing($oldPath);
        Storage::disk('public')->assertExists($cover->getPathRelativeToRoot());
    }

    public function test_images_keep_upload_order_and_can_be_deleted(): void
    {
        $project = Project::create($this->payload());

        foreach (['one.jpg', 'two.jpg', 'three.jpg', 'four.jpg'] as $name) {
            $this->post("/api/admin/projects/{$project->id}/gallery", [
                'image' => UploadedFile::fake()->image($name),
            ], ['Accept' => 'application/json'])->assertCreated();
        }

        $this->assertCount(4, $project->getMedia('gallery'));
        $list = $this->getJson("/api/admin/projects/{$project->id}/gallery")->assertOk()->json('data');
        $this->assertSame(collect($list)->pluck('id')->sort()->values()->all(), collect($list)->pluck('id')->all());

        $first = $project->getMedia('gallery')->sortBy('id')->first();
        $this->deleteJson("/api/admin/projects/{$project->id}/gallery/{$first->id}")->assertOk();
        Storage::disk('public')->assertMissing($first->getPathRelativeToRoot());
        $this->assertCount(3, $project->fresh()->getMedia('gallery'));
    }

    public function test_video_upload_and_external_link(): void
    {
        $project = Project::create($this->payload());

        $this->post("/api/admin/projects/{$project->id}/videos", [
            'title' => 'Walkthrough',
            'video' => UploadedFile::fake()->create('tour.mp4', 2048, 'video/mp4'),
        ], ['Accept' => 'application/json'])->assertStatus(422);

        $this->assertCount(0, $project->fresh()->getMedia('videos'));
    }

    public function test_video_requires_a_file_or_a_link_and_rejects_bad_input(): void
    {
        $project = Project::create($this->payload());

        $this->postJson("/api/admin/projects/{$project->id}/videos", [])->assertStatus(422);
        $this->postJson("/api/admin/projects/{$project->id}/videos", ['external_url' => 'javascript:alert(1)'])->assertStatus(422);
        $this->post("/api/admin/projects/{$project->id}/videos", [
            'video' => UploadedFile::fake()->create('notes.pdf', 10, 'application/pdf'),
        ], ['Accept' => 'application/json'])->assertStatus(422);
    }

    public function test_public_project_payload_includes_images_and_videos(): void
    {
        $project = Project::create($this->payload());
        $this->post("/api/admin/projects/{$project->id}/gallery", [
            'image' => UploadedFile::fake()->image('x.jpg'),
        ], ['Accept' => 'application/json'])->assertCreated();

        $this->getJson('/api/projects/villa-one/gallery')->assertOk()->assertJsonCount(1, 'data');
        $this->getJson('/api/projects/villa-one/videos')->assertOk()->assertJsonCount(0, 'data');
    }

    public function test_deleting_a_project_removes_its_files_and_rows(): void
    {
        $created = $this->post('/api/admin/projects', $this->payload([
            'cover_image' => UploadedFile::fake()->image('c.jpg'),
        ]), ['Accept' => 'application/json'])->assertCreated();
        $id = $created->json('data.id');
        $project = Project::findOrFail($id);
        $cover = $project->getFirstMedia('cover_image')->getPathRelativeToRoot();

        $this->post("/api/admin/projects/{$id}/gallery", [
            'image' => UploadedFile::fake()->image('g.jpg'),
        ], ['Accept' => 'application/json'])->assertCreated();
        $image = $project->fresh()->getMedia('gallery')->first()->getPathRelativeToRoot();

        $this->deleteJson("/api/admin/projects/{$id}")->assertOk();

        $this->assertDatabaseMissing('projects', ['id' => $id]);
        $this->assertDatabaseCount('media', 0);
        Storage::disk('public')->assertMissing($cover);
        Storage::disk('public')->assertMissing($image);
    }
}
