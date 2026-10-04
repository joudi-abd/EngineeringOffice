<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Testimonial\UpdateTestimonialRequest;
use App\Http\Resources\TestimonialResource;
use App\Models\Testimonial;
use App\Services\TestimonialService;
use Illuminate\Http\JsonResponse;

class TestimonialController extends Controller
{
    public function __construct(
        private TestimonialService $testimonialService
    ) {}

    public function index(): JsonResponse
    {
        $testimonials = $this->testimonialService
            ->getAdminTestimonials();

        return response()->json([
            'data' => TestimonialResource::collection(
                $testimonials
            ),

            'meta' => [
                'current_page' => $testimonials->currentPage(),
                'last_page' => $testimonials->lastPage(),
                'per_page' => $testimonials->perPage(),
                'total' => $testimonials->total(),
            ],
        ]);
    }

    public function show(Testimonial $testimonial): JsonResponse
    {
        $testimonial = $this->testimonialService
            ->getAdminTestimonial($testimonial);

        return response()->json([
            'data' => new TestimonialResource($testimonial),
        ]);
    }

    public function update(
        UpdateTestimonialRequest $request,
        Testimonial $testimonial
    ): JsonResponse {
        $testimonial = $this->testimonialService->update(
            $testimonial,
            $request->validated()
        );

        return response()->json([
            'message' => 'Testimonial updated successfully.',
            'data' => new TestimonialResource($testimonial),
        ]);
    }

    public function destroy(
        Testimonial $testimonial
    ): JsonResponse {
        $this->testimonialService->delete($testimonial);

        return response()->json([
            'message' => 'Testimonial deleted successfully.',
        ]);
    }
}