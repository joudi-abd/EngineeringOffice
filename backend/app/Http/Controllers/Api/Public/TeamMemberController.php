<?php

namespace App\Http\Controllers\Api\Public;

use App\Http\Controllers\Controller;
use App\Http\Resources\TeamMemberResource;
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
            ->getPublicTeamMembers();

        return response()->json([
            'data' => TeamMemberResource::collection($teamMembers),
        ]);
    }
}