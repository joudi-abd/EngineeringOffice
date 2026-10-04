<?php

namespace App\Http\Controllers\Api\Public;

use App\Http\Controllers\Controller;
use App\Http\Requests\Testimonial\StoreTestimonialRequest;
use App\Http\Resources\TestimonialResource;
use App\Models\Project;
use App\Services\TestimonialService;
use Illuminate\Http\JsonResponse;

class TestimonialController extends Controller
{
    public function __construct(
        private TestimonialService $testimonialService
    ) {}

    public function index(Project $project): JsonResponse
    {
        $testimonials = $this->testimonialService
            ->getPublicProjectTestimonials($project);

        return response()->json([
            'data' => TestimonialResource::collection(
                $testimonials
            ),
        ]);
    }

    public function store(
        StoreTestimonialRequest $request,
        Project $project
    ): JsonResponse {
        $testimonial = $this->testimonialService->create(
            $project,
            $request->validated()
        );

        return response()->json([
            'message' => 'Testimonial submitted successfully.',
            'data' => new TestimonialResource($testimonial),
        ], 201);
    }


    public function IndexGlobal(): JsonResponse
    {
        $testimonials = $this->testimonialService
            ->getPublicTestimonials();

        return response()->json([
            'data' => TestimonialResource::collection(
                $testimonials
            ),
        ]);
    }
    public function storeGlobal(StoreTestimonialRequest $request): JsonResponse
    {
        $testimonial = $this->testimonialService->create(
            null,
            $request->validated()
        );

        return response()->json([
            'message' => 'Testimonial submitted successfully.',
            'data' => new TestimonialResource($testimonial),
        ], 201);
    }
}