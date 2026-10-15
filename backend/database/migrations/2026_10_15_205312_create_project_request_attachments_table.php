<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('project_request_attachments', function (Blueprint $table) {
            $table->id();

            $table->foreignId('project_request_id')
                ->constrained('project_requests')
                ->cascadeOnDelete();

            $table->string('file_path');
            $table->string('original_name');
            $table->string('mime_type', 100);
            $table->unsignedBigInteger('file_size');

            $table->timestamps();

            $table->index('project_request_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('project_request_attachments');
    }
};