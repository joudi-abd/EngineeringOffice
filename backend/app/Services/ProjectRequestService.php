<?php

namespace App\Services;

use App\Models\ProjectRequest;
use App\Models\User;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;
use App\Models\ProjectRequestAttachment;

use Throwable;

class ProjectRequestService
{
    public function create(User $user, array $data): ProjectRequest
    {
        $uploadedPaths = [];

        try {
            $projectRequest = DB::transaction(function () use (
                $user,
                $data,
                &$uploadedPaths
            ) {
                $projectRequest = $user->projectRequests()->create([
                    'title' => $data['title'],
                    'description' => $data['description'],
                    'location' => $data['location'],
                    'area' => $data['area'] ?? null,
                    'budget' => $data['budget'] ?? null,
                    'preferred_start_date' =>
                        $data['preferred_start_date'] ?? null,
                    'status' => ProjectRequest::STATUS_NEW,
                    'latitude' => $data['latitude'] ?? null,
                    'longitude' => $data['longitude'] ?? null,
                ]);

                $projectRequest->services()->sync(
                    $data['service_ids']
                );

                foreach ($data['attachments'] ?? [] as $file) {
                    if (!$file instanceof UploadedFile) {
                        continue;
                    }

                    $path = $file->store(
                        'project-requests/' . $projectRequest->id,
                        'local'
                    );

                    if ($path === false) {
                        throw new \RuntimeException(
                            'Failed to store project request attachment.'
                        );
                    }

                    $uploadedPaths[] = $path;

                    $projectRequest->attachments()->create([
                        'file_path' => $path,
                        'original_name' => $file->getClientOriginalName(),
                        'mime_type' => $file->getMimeType()
                            ?? 'application/octet-stream',
                        'file_size' => $file->getSize() ?? 0,
                    ]);
                }

                return $projectRequest;
            });

            return $projectRequest->load([
                'services',
                'attachments',
            ]);
        } catch (Throwable $exception) {
            if ($uploadedPaths !== []) {
                Storage::disk('local')->delete($uploadedPaths);
            }

            throw $exception;
        }
    }

    public function update(
    ProjectRequest $projectRequest,
    array $data
    ): ProjectRequest {

        if ($projectRequest->status !== ProjectRequest::STATUS_NEW) {
            throw ValidationException::withMessages([
                'status' => [
                    'لا يمكن تعديل الطلب بعد بدء معالجته.',
                ],
            ]);
        }

        DB::transaction(function () use ($projectRequest, $data) {

            $projectRequest = ProjectRequest::query()
                ->lockForUpdate()
                ->findOrFail($projectRequest->id);

            if ($projectRequest->status !== ProjectRequest::STATUS_NEW) {
                throw ValidationException::withMessages([
                    'status' => [
                        'لا يمكن تعديل الطلب بعد بدء معالجته.',
                    ],
                ]);
            }

            $fields = [
                'title',
                'description',
                'location',
                'area',
                'budget',
                'preferred_start_date',
                'latitude',
                'longitude',
            ];

            $projectRequest->fill(
                array_intersect_key(
                    $data,
                    array_flip($fields)
                )
            );

            $projectRequest->save();

            if (array_key_exists('service_ids', $data)) {
                $projectRequest->services()->sync(
                    $data['service_ids']
                );
            }
        });

        return $projectRequest->fresh([
            'services',
            'attachments',
        ]);
    }
}