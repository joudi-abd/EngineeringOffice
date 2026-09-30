<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

// Route::get('/user', function (Request $request) {
//     return $request->user();
// })->middleware('auth:sanctum');

Route::prefix('auth')->group(function () {
    Route::post('login', [\App\Http\Controllers\Api\AuthController::class, 'login']);
    Route::post('logout', [\App\Http\Controllers\Api\AuthController::class, 'logout'])->middleware('auth:sanctum');
    Route::get('me', [\App\Http\Controllers\Api\AuthController::class, 'me'])->middleware('auth:sanctum');
});

Route::middleware('auth:sanctum')->prefix('admin')->group(function () {
   Route::get('/test' , function(){
    return response()->json([
        'message' => 'Admin API works'
    ]);
   })->middleware('permission:projects.view');
});