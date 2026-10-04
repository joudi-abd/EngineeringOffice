<?php

namespace App\Services;

use App\Models\TeamMember;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class TeamMemberService
{
    public function getPublicTeamMembers(): Collection
    {
        return TeamMember::query()
            ->where('is_active', true)
            ->latest()
            ->get();
    }

    public function getAdminTeamMembers(
        int $perPage = 15
    ): LengthAwarePaginator {
        return TeamMember::query()
            ->latest()
            ->paginate($perPage);
    }

    public function create(array $data): TeamMember
    {
        $image = $data['image'] ?? null;

        unset($data['image']);

        $imagePath = null;

        if ($image instanceof UploadedFile) {
            $imagePath = $image->store(
                'team-members',
                'public'
            );
        }

        try {
            return DB::transaction(function () use (
                $data,
                $imagePath
            ) {
                return TeamMember::create([
                    ...$data,
                    'image' => $imagePath,
                ]);
            });
        } catch (\Throwable $e) {
            if ($imagePath) {
                Storage::disk('public')->delete($imagePath);
            }

            throw $e;
        }
    }

    public function update(
        TeamMember $teamMember,
        array $data
    ): TeamMember {
        $image = $data['image'] ?? null;

        unset($data['image']);

        $oldImagePath = $teamMember->image;
        $newImagePath = null;

        if ($image instanceof UploadedFile) {
            $newImagePath = $image->store(
                'team-members',
                'public'
            );

            $data['image'] = $newImagePath;
        }

        try {
            $teamMember = DB::transaction(function () use (
                $teamMember,
                $data
            ) {
                $teamMember->update($data);

                return $teamMember->refresh();
            });

            if ($newImagePath && $oldImagePath) {
                Storage::disk('public')->delete($oldImagePath);
            }

            return $teamMember;
        } catch (\Throwable $e) {
            if ($newImagePath) {
                Storage::disk('public')->delete($newImagePath);
            }

            throw $e;
        }
    }

    public function delete(TeamMember $teamMember): void
    {
        $imagePath = $teamMember->image;

        DB::transaction(function () use ($teamMember) {
            $teamMember->delete();
        });

        if ($imagePath) {
            Storage::disk('public')->delete($imagePath);
        }
    }
}