<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\TeamMember\StoreTeamMemberRequest;
use App\Http\Requests\TeamMember\UpdateTeamMemberRequest;
use App\Http\Resources\TeamMemberResource;
use App\Models\TeamMember;
use App\Services\TeamMemberService;
use Illuminate\Http\JsonResponse;

class TeamMemberController extends Controller
{
    public function __construct(
        private TeamMemberService $teamMemberService
    ) {}

    public function index(): JsonResponse
    {
        $teamMembers = $this->teamMemberService
            ->getAdminTeamMembers();

        return response()->json([
            'data' => TeamMemberResource::collection($teamMembers),

            'meta' => [
                'current_page' => $teamMembers->currentPage(),
                'last_page' => $teamMembers->lastPage(),
                'per_page' => $teamMembers->perPage(),
                'total' => $teamMembers->total(),
            ],
        ]);
    }

    public function store(
        StoreTeamMemberRequest $request
    ): JsonResponse {
        $teamMember = $this->teamMemberService->create(
            $request->validated()
        );

        return response()->json([
            'message' => 'Team member created successfully.',
            'data' => new TeamMemberResource($teamMember),
        ], 201);
    }

    public function show(TeamMember $teamMember): JsonResponse
    {
        return response()->json([
            'data' => new TeamMemberResource($teamMember),
        ]);
    }

    public function update(
        UpdateTeamMemberRequest $request,
        TeamMember $teamMember
    ): JsonResponse {
        $teamMember = $this->teamMemberService->update(
            $teamMember,
            $request->validated()
        );

        return response()->json([
            'message' => 'Team member updated successfully.',
            'data' => new TeamMemberResource($teamMember),
        ]);
    }

    public function destroy(
        TeamMember $teamMember
    ): JsonResponse {
        $this->teamMemberService->delete($teamMember);

        return response()->json([
            'message' => 'Team member deleted successfully.',
        ]);
    }
}