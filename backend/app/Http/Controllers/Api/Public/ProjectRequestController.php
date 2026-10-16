<?php

namespace App\Http\Controllers\Api\Public;

use App\Http\Controllers\Controller;
use App\Http\Requests\ProjectRequest\StoreProjectRequestRequest;
use App\Http\Requests\ProjectRequest\UpdateProjectRequestRequest;
use App\Http\Resources\ProjectRequestResource;
use App\Models\ProjectRequest;
use App\Services\ProjectRequestService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProjectRequestController extends Controller
{

    public function index(Request $request)
    {
        $this->authorize('viewAny', ProjectRequest::class);
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
        $this->authorize('create', ProjectRequest::class);
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
        $this->authorize('view', $projectRequest);

        $projectRequest->load(['services', 'attachments']);

        return new ProjectRequestResource($projectRequest);
    }

    public function cancel(
        Request $request,
        ProjectRequest $projectRequest
    ): JsonResponse {
        $this->authorize('cancel', $projectRequest);

        $projectRequest->update([
            'status' => ProjectRequest::STATUS_CANCELLED,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Project request cancelled successfully.',
        ]);
    }

    public function update(
        UpdateProjectRequestRequest $request,
        ProjectRequest $projectRequest,
        ProjectRequestService $service
    ): JsonResponse {
        $this->authorize('update', $projectRequest);
        $projectRequest = $service->update(
            $projectRequest,
            $request->validated()
        );

        return response()->json([
            'success' => true,
            'message' => 'Project request updated successfully.',
            'data' => new ProjectRequestResource($projectRequest),
        ]);
    }
}