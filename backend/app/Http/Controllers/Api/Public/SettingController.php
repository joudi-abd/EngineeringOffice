<?php

namespace App\Http\Controllers\Api\Public;

use App\Http\Controllers\Controller;
use App\Http\Resources\SettingResource;
use App\Services\SettingService;
use Illuminate\Http\JsonResponse;

class SettingController extends Controller
{
    public function __construct(
        private SettingService $settingService
    ) {}

    public function index(): JsonResponse
    {
        $settings = $this->settingService->getPublicSettings();

        return response()->json([
            'data' => SettingResource::collection($settings),
        ]);
    }
}