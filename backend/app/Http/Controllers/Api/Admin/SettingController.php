<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Setting\UpdateSettingRequest;
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
        $settings = $this->settingService->getAdminSettings();

        return response()->json([
            'data' => SettingResource::collection($settings),
        ]);
    }

    public function show(string $key): JsonResponse
    {
        $setting = $this->settingService->getAdminSetting($key);

        return response()->json([
            'data' => new SettingResource($setting),
        ]);
    }

    public function update(
        UpdateSettingRequest $request,
        string $key
    ): JsonResponse {
        $setting = $this->settingService->update(
            $key,
            $request->validated()
        );

        return response()->json([
            'message' => 'Setting updated successfully.',
            'data' => new SettingResource($setting),
        ]);
    }
}