<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\ProjectRequestResource;
use App\Models\ProjectRequest;
use Illuminate\Http\Request;

class ProjectRequestController extends Controller
{
    public function index(Request $request)
    {
        $query = ProjectRequest::query()
            ->with(['user', 'services', 'attachments'])
            ->latest();

        if ($request->filled('status')) {
            $query->where('status', $request->query('status'));
        }

        return ProjectRequestResource::collection(
            $query->paginate(15)
        );
    }

    public function show(
        ProjectRequest $projectRequest
    ): ProjectRequestResource {
        $projectRequest->load([
            'user',
            'services',
            'attachments',
        ]);

        return new ProjectRequestResource($projectRequest);
    }
}