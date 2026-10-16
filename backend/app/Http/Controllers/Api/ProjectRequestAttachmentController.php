<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ProjectRequest;
use App\Models\ProjectRequestAttachment;
use App\Http\Requests\ProjectRequest\StoreProjectRequestAttachmentsRequest;
use App\Http\Resources\ProjectRequestAttachmentResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\StreamedResponse;
use Illuminate\Validation\ValidationException;
use Throwable;

class ProjectRequestAttachmentController extends Controller
{
    public function download(
        Request $request,
        ProjectRequest $projectRequest,
        ProjectRequestAttachment $attachment
    ): StreamedResponse {
        $this->authorize('downloadAttachment', $projectRequest);
        $user = $request->user();

        // التحقق من أن المرفق تابع لطلب المشروع المحدد
        abort_unless(
            $attachment->project_request_id === $projectRequest->id,
            404
        );


        // التأكد من وجود الملف
        abort_unless(
            Storage::disk('local')->exists($attachment->file_path),
            404
        );

        return Storage::disk('local')->download(
            $attachment->file_path,
            $attachment->original_name
        );
    }

    public function store(
        StoreProjectRequestAttachmentsRequest $request,
        ProjectRequest $projectRequest
    ): JsonResponse {

        $this->authorize('manageAttachments', $projectRequest);
        $uploadedPaths = [];

        try {
            $attachments = DB::transaction(function () use (
                $request,
                $projectRequest,
                &$uploadedPaths
            ) {
                $lockedRequest = ProjectRequest::query()
                    ->lockForUpdate()
                    ->findOrFail($projectRequest->id);

                if ($lockedRequest->status !== ProjectRequest::STATUS_NEW) {
                    throw ValidationException::withMessages([
                        'status' => [
                            'لا يمكن تعديل مرفقات الطلب بعد بدء معالجته.',
                        ],
                    ]);
                }

                $files = $request->file('attachments', []);

                if ($lockedRequest->attachments()->count() + count($files) > ProjectRequest::MAX_ATTACHMENTS) {
                    throw ValidationException::withMessages([
                        'attachments' => ['يمكن إرفاق 10 ملفات كحد أقصى.'],
                    ]);
                }

                $createdAttachments = [];

                foreach ($files as $file) {
                    $path = $file->store(
                        "project-requests/{$lockedRequest->id}",
                        'local'
                    );

                    if ($path === false) {
                        throw new \RuntimeException(
                            'Failed to store project request attachment.'
                        );
                    }

                    $uploadedPaths[] = $path;

                    $createdAttachments[] = $lockedRequest->attachments()->create([
                        'file_path' => $path,
                        'original_name' => $file->getClientOriginalName(),
                        'mime_type' => $file->getMimeType()
                            ?? 'application/octet-stream',
                        'file_size' => $file->getSize() ?? 0,
                    ]);
                }

                return $createdAttachments;
            });
        } catch (Throwable $exception) {
            if ($uploadedPaths !== []) {
                Storage::disk('local')->delete($uploadedPaths);
            }

            throw $exception;
        }

        return ProjectRequestAttachmentResource::collection($attachments)
            ->additional([
                'success' => true,
                'message' => 'Attachments uploaded successfully.',
            ])
            ->response()
            ->setStatusCode(201);
    }

    public function destroy(
    Request $request,
    ProjectRequest $projectRequest,
    ProjectRequestAttachment $attachment
    ): JsonResponse {
        $this->authorize('manageAttachments', $projectRequest);

        // التأكد من أن المرفق تابع لهذا الطلب
        abort_unless(
            $attachment->project_request_id === $projectRequest->id,
            404
        );

        $path = DB::transaction(function () use (
            $projectRequest,
            $attachment
        ) {
            $lockedRequest = ProjectRequest::query()
                ->lockForUpdate()
                ->findOrFail($projectRequest->id);

            if ($lockedRequest->status !== ProjectRequest::STATUS_NEW) {
                throw ValidationException::withMessages([
                    'status' => [
                        'لا يمكن حذف مرفقات الطلب بعد بدء معالجته.',
                    ],
                ]);
            }

            // إعادة التحقق من تبعية المرفق للطلب
            $lockedAttachment = $lockedRequest->attachments()
                ->whereKey($attachment->id)
                ->firstOrFail();

            $filePath = $lockedAttachment->file_path;

            $lockedAttachment->delete();

            return $filePath;
        });

        // حذف الملف بعد نجاح معاملة قاعدة البيانات
        $deleted = Storage::disk('local')->delete($path);

        if (! $deleted && Storage::disk('local')->exists($path)) {
            report("Failed to delete project request attachment: {$path}");
        }

        return response()->json([
            'success' => true,
            'message' => 'Attachment deleted successfully.',
        ]);
    }
}