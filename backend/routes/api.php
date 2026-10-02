<?php

use App\Http\Controllers\Api\Admin\ProjectCategoryController as AdminProjectCategoryController;
use App\Http\Controllers\Api\Public\ProjectCategoryController as PublicProjectCategoryController;
use App\Http\Controllers\Api\Public\ProjectController as PublicProjectController;
use App\Http\Controllers\Api\Admin\ProjectController as AdminProjectController;
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

   Route::get('/categories' , [AdminProjectCategoryController::class, 'index'])->middleware('permission:categories.view');
   Route::post('/categories' , [AdminProjectCategoryController::class, 'store'])->middleware('permission:categories.create');
   Route::get('/categories/{category}' , [AdminProjectCategoryController::class, 'show'])->middleware('permission:categories.view');
   Route::put('/categories/{category}' , [AdminProjectCategoryController::class, 'update'])->middleware('permission:categories.update');
   Route::patch('/categories/{category}' , [AdminProjectCategoryController::class, 'update'])->middleware('permission:categories.update');
   Route::delete('/categories/{category}' , [AdminProjectCategoryController::class, 'destroy'])->middleware('permission:categories.delete');

    Route::get('/projects' , [AdminProjectController::class, 'index'])->middleware('permission:projects.view');
    Route::post('/projects' , [AdminProjectController::class, 'store'])->middleware('permission:projects.create');
    Route::get('/projects/{project}' , [AdminProjectController::class, 'show'])->middleware('permission:projects.view');
    Route::put('/projects/{project}' , [AdminProjectController::class, 'update'])->middleware('permission:projects.update');
    Route::patch('/projects/{project}' , [AdminProjectController::class, 'update'])->middleware('permission:projects.update');
    Route::delete('/projects/{project}' , [AdminProjectController::class, 'destroy'])->middleware('permission:projects.delete');
});

Route::get('/categories' , [PublicProjectCategoryController::class , 'index']);
Route::get('/categories/{slug}' , [PublicProjectCategoryController::class , 'show']);

Route::get('/projects' , [PublicProjectController::class , 'index']);
Route::get('/projects/{slug}' , [PublicProjectController::class , 'show']);