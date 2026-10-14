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
        $path = Project::firstOrFail()->cover_image;
        $this->assertStringStartsWith('projects/covers/', $path);
        Storage::disk('public')->assertExists($path);
        $this->assertStringContainsString('/storage/'.$path, $response->json('data.cover_image'));
    }

    public function test_update_with_multipart_post_override_keeps_and_replaces_cover(): void
    {
        $created = $this->post('/api/admin/projects', $this->payload([
            'cover_image' => UploadedFile::fake()->image('a.jpg'),
        ]), ['Accept' => 'application/json'])->assertCreated();
        $old = Project::firstOrFail()->cover_image;

        $this->post('/api/admin/projects/'.$created->json('data.id'), [
            '_method' => 'PUT',
            'title' => 'Villa One Renamed',
            'cover_image' => UploadedFile::fake()->image('b.jpg'),
        ], ['Accept' => 'application/json'])->assertOk();

        $project = Project::firstOrFail();
        $this->assertSame('Villa One Renamed', $project->title);
        $this->assertNotSame($old, $project->cover_image);
        Storage::disk('public')->assertMissing($old);
        Storage::disk('public')->assertExists($project->cover_image);
    }

    public function test_images_keep_upload_order_and_can_be_deleted(): void
    {
        $project = Project::create($this->payload());

        foreach (['one.jpg', 'two.jpg', 'three.jpg', 'four.jpg'] as $name) {
            $this->post("/api/admin/projects/{$project->id}/images", [
                'image' => UploadedFile::fake()->image($name),
            ], ['Accept' => 'application/json'])->assertCreated();
        }

        $this->assertCount(4, $project->images);
        $list = $this->getJson("/api/admin/projects/{$project->id}/images")->assertOk()->json('data');
        $this->assertSame(collect($list)->pluck('id')->sort()->values()->all(), collect($list)->pluck('id')->all());

        $first = $project->images()->orderBy('id')->first();
        $this->deleteJson("/api/admin/projects/{$project->id}/images/{$first->id}")->assertOk();
        Storage::disk('public')->assertMissing($first->image_path);
        $this->assertCount(3, $project->fresh()->images);
    }

    public function test_video_upload_and_external_link(): void
    {
        $project = Project::create($this->payload());

        $file = $this->post("/api/admin/projects/{$project->id}/videos", [
            'title' => 'Walkthrough',
            'video' => UploadedFile::fake()->create('tour.mp4', 2048, 'video/mp4'),
        ], ['Accept' => 'application/json'])->assertCreated();
        $path = $file->json('data.video_path');
        Storage::disk('public')->assertExists($path);
        $this->assertNotEmpty($file->json('data.video_url'));

        $link = $this->postJson("/api/admin/projects/{$project->id}/videos", [
            'external_url' => 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        ])->assertCreated();
        $this->assertNull($link->json('data.video_path'));

        $this->assertCount(2, $project->fresh()->videos);

        $this->deleteJson("/api/admin/projects/{$project->id}/videos/".$file->json('data.id'))->assertOk();
        Storage::disk('public')->assertMissing($path);
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
        $this->post("/api/admin/projects/{$project->id}/images", [
            'image' => UploadedFile::fake()->image('x.jpg'),
        ], ['Accept' => 'application/json']);
        $this->postJson("/api/admin/projects/{$project->id}/videos", [
            'external_url' => 'https://youtu.be/dQw4w9WgXcQ',
        ]);

        $data = $this->getJson('/api/projects/villa-one')->assertOk()->json('data');
        $this->assertCount(1, $data['images']);
        $this->assertCount(1, $data['videos']);
        $this->assertSame('https://youtu.be/dQw4w9WgXcQ', $data['videos'][0]['external_url']);
    }

    public function test_deleting_a_project_removes_its_files_and_rows(): void
    {
        $created = $this->post('/api/admin/projects', $this->payload([
            'cover_image' => UploadedFile::fake()->image('c.jpg'),
        ]), ['Accept' => 'application/json'])->assertCreated();
        $id = $created->json('data.id');
        $cover = Project::findOrFail($id)->cover_image;

        $image = $this->post("/api/admin/projects/{$id}/images", [
            'image' => UploadedFile::fake()->image('g.jpg'),
        ], ['Accept' => 'application/json'])->json('data.image_path');
        $video = $this->post("/api/admin/projects/{$id}/videos", [
            'video' => UploadedFile::fake()->create('v.mp4', 512, 'video/mp4'),
        ], ['Accept' => 'application/json'])->json('data.video_path');

        $this->deleteJson("/api/admin/projects/{$id}")->assertOk();

        $this->assertDatabaseMissing('projects', ['id' => $id]);
        $this->assertDatabaseCount('project_images', 0);
        $this->assertDatabaseCount('project_videos', 0);
        foreach ([$cover, $image, $video] as $file) {
            Storage::disk('public')->assertMissing($file);
        }
    }
}
