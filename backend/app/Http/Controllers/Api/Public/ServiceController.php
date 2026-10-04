<?php

namespace App\Http\Controllers\Api\Public;

use App\Http\Controllers\Controller;
use App\Http\Resources\ServiceResource;
use App\Services\ServiceService;
use Illuminate\Http\JsonResponse;

class ServiceController extends Controller
{
    public function __construct(
        private ServiceService $serviceService
    ) {}

    public function index(): JsonResponse
    {
        $services = $this->serviceService->getPublicServices();

        return response()->json([
            'data' => ServiceResource::collection($services),
        ]);
    }

    public function show(string $slug): JsonResponse
    {
        $service = $this->serviceService
            ->getPublicServiceBySlug($slug);

        return response()->json([
            'data' => new ServiceResource($service),
        ]);
    }
}