<?php

namespace App\Http\Controllers\Api\Public;

use App\Http\Controllers\Controller;
use App\Http\Requests\ContactMessage\StoreContactMessageRequest;
use App\Http\Resources\ContactMessageResource;
use App\Services\ContactMessageService;
use Illuminate\Http\JsonResponse;

class ContactMessageController extends Controller
{
    public function __construct(
        private ContactMessageService $contactMessageService
    ) {}

    public function store(
        StoreContactMessageRequest $request
    ): JsonResponse {
        $contactMessage = $this->contactMessageService->create(
            $request->validated()
        );

        return response()->json([
            'message' => 'Your message has been sent successfully.',
            'data' => new ContactMessageResource($contactMessage),
        ], 201);
    }
}