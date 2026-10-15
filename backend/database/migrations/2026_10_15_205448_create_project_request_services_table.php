<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('project_request_services', function (Blueprint $table) {
            $table->id();

            $table->foreignId('project_request_id')
                ->constrained('project_requests')
                ->cascadeOnDelete();

            $table->foreignId('service_id')
                ->constrained('services')
                ->restrictOnDelete();

            $table->timestamps();

            $table->unique([
                'project_request_id',
                'service_id',
            ]);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('project_request_services');
    }
};