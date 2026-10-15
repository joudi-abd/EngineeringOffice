<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\ProjectRequest;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class ProjectRequestStatusController extends Controller
{
    public function update(
        Request $request,
        ProjectRequest $projectRequest
    ): JsonResponse {
        $validated = $request->validate([
            'status' => [
                'required',
                'string',
                Rule::in(ProjectRequest::STATUSES),
            ],

            'admin_notes' => [
                'nullable',
                'string',
                'max:10000',
            ],
        ]);

        $projectRequest->update([
            'status' => $validated['status'],
            'admin_notes' => $validated['admin_notes']
                ?? $projectRequest->admin_notes,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Project request updated successfully.',
            'data' => [
                'id' => $projectRequest->id,
                'status' => $projectRequest->status,
                'admin_notes' => $projectRequest->admin_notes,
            ],
        ]);
    }
}