<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('project_requests', function (Blueprint $table) {
            $table->id();

            $table->foreignId('user_id')
                ->constrained('users')
                ->restrictOnDelete();

            $table->string('title');
            $table->text('description');
            $table->string('location');

            $table->decimal('area', 10, 2)->nullable();
            $table->decimal('budget', 15, 2)->nullable();

            $table->date('preferred_start_date')->nullable();

            $table->string('status')->default('new');

            $table->text('admin_notes')->nullable();

            $table->timestamps();

            $table->index(['user_id', 'status']);
            $table->index(['status', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('project_requests');
    }
};