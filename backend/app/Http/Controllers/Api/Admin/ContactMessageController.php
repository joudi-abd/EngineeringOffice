<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\ContactMessage\UpdateContactMessageRequest;
use App\Http\Resources\ContactMessageResource;
use App\Models\ContactMessage;
use App\Services\ContactMessageService;
use Illuminate\Http\JsonResponse;

class ContactMessageController extends Controller
{
    public function __construct(
        private ContactMessageService $contactMessageService
    ) {}

    public function index(): JsonResponse
    {
        $messages = $this->contactMessageService
            ->getAdminMessages();

        return response()->json([
            'data' => ContactMessageResource::collection($messages),

            'meta' => [
                'current_page' => $messages->currentPage(),
                'last_page' => $messages->lastPage(),
                'per_page' => $messages->perPage(),
                'total' => $messages->total(),
            ],
        ]);
    }

    public function show(
        ContactMessage $contactMessage
    ): JsonResponse {
        $contactMessage = $this->contactMessageService
            ->getAdminMessage($contactMessage);

        return response()->json([
            'data' => new ContactMessageResource($contactMessage),
        ]);
    }

    public function update(
        UpdateContactMessageRequest $request,
        ContactMessage $contactMessage
    ): JsonResponse {
        $contactMessage = $this->contactMessageService->update(
            $contactMessage,
            $request->validated()
        );

        return response()->json([
            'message' => 'Message status updated successfully.',
            'data' => new ContactMessageResource($contactMessage),
        ]);
    }

    public function destroy(
        ContactMessage $contactMessage
    ): JsonResponse {
        $this->contactMessageService->delete($contactMessage);

        return response()->json([
            'message' => 'Message deleted successfully.',
        ]);
    }
}