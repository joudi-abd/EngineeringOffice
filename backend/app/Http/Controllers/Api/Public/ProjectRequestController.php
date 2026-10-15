<?php

namespace App\Http\Controllers\Api\Public;

use App\Http\Controllers\Controller;
use App\Http\Requests\ProjectRequest\StoreProjectRequestRequest;
use App\Http\Resources\ProjectRequestResource;
use App\Models\ProjectRequest;
use App\Services\ProjectRequestService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProjectRequestController extends Controller
{
    public function index(Request $request)
    {
        $requests = $request->user()
            ->projectRequests()
            ->with(['services', 'attachments'])
            ->latest()
            ->paginate(15);

        return ProjectRequestResource::collection($requests);
    }

    public function store(
        StoreProjectRequestRequest $request,
        ProjectRequestService $service
    ): JsonResponse {
        $projectRequest = $service->create(
            $request->user(),
            $request->validated()
        );

        return (new ProjectRequestResource($projectRequest))
            ->response()
            ->setStatusCode(201);
    }

    public function show(
        Request $request,
        ProjectRequest $projectRequest
    ): ProjectRequestResource {
        abort_unless(
            $projectRequest->user_id === $request->user()->id,
            404
        );

        $projectRequest->load(['services', 'attachments']);

        return new ProjectRequestResource($projectRequest);
    }

    public function cancel(
        Request $request,
        ProjectRequest $projectRequest
    ): JsonResponse {
        abort_unless(
            $projectRequest->user_id === $request->user()->id,
            404
        );

        abort_unless(
            in_array($projectRequest->status, [
                ProjectRequest::STATUS_NEW,
                ProjectRequest::STATUS_UNDER_REVIEW,
            ], true),
            422,
            'This project request cannot be cancelled.'
        );

        $projectRequest->update([
            'status' => ProjectRequest::STATUS_CANCELLED,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Project request cancelled successfully.',
        ]);
    }
}