<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Service\StoreServiceRequest;
use App\Http\Requests\Service\UpdateServiceRequest;
use App\Http\Resources\ServiceResource;
use App\Models\Service;
use App\Services\ServiceService;
use Illuminate\Http\JsonResponse;

class ServiceController extends Controller
{
    public function __construct(
        private ServiceService $serviceService
    ) {}

    public function index(): JsonResponse
    {
        $services = $this->serviceService->getAdminServices();

        return response()->json([
            'data' => ServiceResource::collection($services),
            'meta' => [
                'current_page' => $services->currentPage(),
                'last_page' => $services->lastPage(),
                'per_page' => $services->perPage(),
                'total' => $services->total(),
            ],
        ]);
    }

    public function store(StoreServiceRequest $request): JsonResponse
    {
        $service = $this->serviceService->create(
            $request->validated()
        );

        return response()->json([
            'message' => 'Service created successfully.',
            'data' => new ServiceResource($service),
        ], 201);
    }

    public function show(Service $service): JsonResponse
    {
        return response()->json([
            'data' => new ServiceResource($service),
        ]);
    }

    public function update(
        UpdateServiceRequest $request,
        Service $service
    ): JsonResponse {
        $service = $this->serviceService->update(
            $service,
            $request->validated()
        );

        return response()->json([
            'message' => 'Service updated successfully.',
            'data' => new ServiceResource($service),
        ]);
    }

    public function destroy(Service $service): JsonResponse
    {
        $this->serviceService->delete($service);

        return response()->json([
            'message' => 'Service deleted successfully.',
        ]);
    }
}