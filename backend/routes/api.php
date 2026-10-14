<?php

use App\Http\Controllers\Api\Admin\ProjectCategoryController as AdminProjectCategoryController;
use App\Http\Controllers\Api\Public\ProjectCategoryController as PublicProjectCategoryController;
use App\Http\Controllers\Api\Public\ProjectController as PublicProjectController;
use App\Http\Controllers\Api\Admin\ProjectController as AdminProjectController;
use App\Http\Controllers\Api\Admin\ProjectImageController;
use App\Http\Controllers\Api\Admin\ProjectVideoController;
use App\Http\Controllers\Api\Public\ServiceController as PublicServiceController;
use App\Http\Controllers\Api\Admin\ServiceController as AdminServiceController;
use App\Http\Controllers\Api\Admin\TeamMemberController as AdminTeamMemberController;
use App\Http\Controllers\Api\Public\TeamMemberController as PublicTeamMemberController;
use App\Http\Controllers\Api\Public\TestimonialController as PublicTestimonialController;
use App\Http\Controllers\Api\Admin\TestimonialController as AdminTestimonialController;
use App\Http\Controllers\Api\Public\ContactMessageController as PublicContactMessageController;
use App\Http\Controllers\Api\Admin\ContactMessageController as AdminContactMessageController;
use App\Http\Controllers\Api\Public\SettingController as PublicSettingController;
use App\Http\Controllers\Api\Admin\SettingController as AdminSettingController;
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

    Route::scopeBindings()->group(function () {
        Route::get('/projects/{project}/images' , [ProjectImageController::class , 'index'])->middleware('permission:projects.view');
        Route::post('/projects/{project}/images' , [ProjectImageController::class , 'store'])->middleware('permission:projects.update');
        Route::delete('/projects/{project}/images/{image}' , [ProjectImageController::class , 'destroy'])->middleware('permission:projects.update');

        Route::get('/projects/{project}/videos' , [ProjectVideoController::class , 'index'])->middleware('permission:projects.view');
        Route::post('/projects/{project}/videos' , [ProjectVideoController::class , 'store'])->middleware('permission:projects.update');
        Route::delete('/projects/{project}/videos/{video}' , [ProjectVideoController::class , 'destroy'])->middleware('permission:projects.update');
    });

    Route::get('/services' , [AdminServiceController::class, 'index'])->middleware('permission:services.view');
    Route::post('/services' , [AdminServiceController::class, 'store'])->middleware('permission:services.create');
    Route::get('/services/{service}' , [AdminServiceController::class, 'show'])->middleware('permission:services.view');
    Route::put('/services/{service}' , [AdminServiceController::class, 'update'])->middleware('permission:services.update');    
    Route::patch('/services/{service}' , [AdminServiceController::class, 'update'])->middleware('permission:services.update');
    Route::delete('/services/{service}' , [AdminServiceController::class, 'destroy'])->middleware('permission:services.delete');

    Route::get('/team-members' , [AdminTeamMemberController::class, 'index'])->middleware('permission:team.view');
    Route::post('/team-members' , [AdminTeamMemberController::class, 'store'])->middleware('permission:team.create');
    Route::get('/team-members/{teamMember}' , [AdminTeamMemberController::class, 'show'])->middleware('permission:team.view');
    Route::put('/team-members/{teamMember}' , [AdminTeamMemberController::class, 'update'])->middleware('permission:team.update');    
    Route::patch('/team-members/{teamMember}' , [AdminTeamMemberController::class, 'update'])->middleware('permission:team.update');
    Route::delete('/team-members/{teamMember}' , [AdminTeamMemberController::class, 'destroy'])->middleware('permission:team.delete');

    Route::get('/testimonials' , [AdminTestimonialController::class, 'index'])->middleware('permission:testimonials.view');
    Route::get('/testimonials/{testimonial}' , [AdminTestimonialController::class, 'show'])->middleware('permission:testimonials.view');
    Route::put('/testimonials/{testimonial}' , [AdminTestimonialController::class, 'update'])->middleware('permission:testimonials.update');    
    Route::patch('/testimonials/{testimonial}' , [AdminTestimonialController::class, 'update'])->middleware('permission:testimonials.update');
    Route::delete('/testimonials/{testimonial}' , [AdminTestimonialController::class, 'destroy'])->middleware('permission:testimonials.delete');

    Route::get('/contact-messages' , [AdminContactMessageController::class, 'index'])->middleware('permission:messages.view');
    Route::get('/contact-messages/{contactMessage}' , [AdminContactMessageController::class, 'show'])->middleware('permission:messages.view');
    Route::put('/contact-messages/{contactMessage}' , [AdminContactMessageController::class, 'update'])->middleware('permission:messages.update');    
    Route::patch('/contact-messages/{contactMessage}' , [AdminContactMessageController::class, 'update'])->middleware('permission:messages.update');
    Route::delete('/contact-messages/{contactMessage}' , [AdminContactMessageController::class, 'destroy'])->middleware('permission:messages.delete');

    Route::get('/settings' , [AdminSettingController::class, 'index'])->middleware('permission:settings.view');
    Route::get('/settings/{key}' , [AdminSettingController::class, 'show'])->middleware('permission:settings.view');
    Route::put('/settings/{key}' , [AdminSettingController::class, 'update'])->middleware('permission:settings.update');
    Route::patch('/settings/{key}' , [AdminSettingController::class, 'update'])->middleware('permission:settings.update');
});

Route::get('/categories' , [PublicProjectCategoryController::class , 'index']);
Route::get('/categories/{slug}' , [PublicProjectCategoryController::class , 'show']);

Route::get('/projects' , [PublicProjectController::class , 'index']);
Route::get('/projects/{slug}' , [PublicProjectController::class , 'show']);

Route::get('/services' , [PublicServiceController::class , 'index']);
Route::get('/services/{slug}' , [PublicServiceController::class , 'show']);

Route::get('/team-members' , [PublicTeamMemberController::class , 'index']);

Route::get('/projects/{project}/testimonials' , [PublicTestimonialController::class , 'index']);
Route::post('/projects/{project}/testimonials' , [PublicTestimonialController::class , 'store']);
Route::get('/testimonials' , [PublicTestimonialController::class , 'IndexGlobal']);
Route::post('/testimonials' , [PublicTestimonialController::class , 'storeGlobal']);

Route::post('/contact-messages' , [PublicContactMessageController::class , 'store'])->middleware('throttle:5,10');

Route::get('/settings' , [PublicSettingController::class , 'index']);