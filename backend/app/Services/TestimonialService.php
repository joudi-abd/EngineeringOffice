<?php

namespace App\Services;

use App\Models\Project;
use App\Models\Testimonial;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\ConflictHttpException;

class TestimonialService
{
    public function getPublicTestimonials(): Collection
    {
        return Testimonial::query()
            ->with('project')
            ->latest()
            ->get();
    }

    public function getPublicProjectTestimonials(Project $project): Collection
    {
        return $project->testimonials()
            ->latest()
            ->get();
    }

    public function getAdminTestimonials(int $perPage = 15): LengthAwarePaginator
    {
        return Testimonial::query()
            ->with('project')
            ->latest()
            ->paginate($perPage);
    }

    public function getAdminTestimonial(Testimonial $testimonial): Testimonial
    {
        return $testimonial->load('project');
    }

    public function create(?Project $project, array $data): Testimonial
    {
        $query = Testimonial::query()
            ->where('client_email', $data['client_email']);

        if ($project) {
            $query->where('project_id', $project->id);
        } else {
            $query->whereNull('project_id');
        }

        if ($query->exists()) {
            throw new ConflictHttpException(
                'This email has already submitted a testimonial.'
            );
        }

        return DB::transaction(function () use ($project, $data) {
            return Testimonial::create([
                'project_id' => $project?->id,
                'client_name' => $data['client_name'],
                'client_email' => $data['client_email'],
                'content' => $data['content'],
                'rating' => $data['rating'],
            ]);
        });
    }

    public function update(
        Testimonial $testimonial,
        array $data
    ): Testimonial {
        if (isset($data['client_email'])) {

            $query = Testimonial::query()
                ->where('client_email', $data['client_email'])
                ->where('id', '!=', $testimonial->id);

            if ($testimonial->project_id) {
                $query->where('project_id', $testimonial->project_id);
            } else {
                $query->whereNull('project_id');
            }

            if ($query->exists()) {
                throw new ConflictHttpException(
                    'This email has already submitted a testimonial.'
                );
            }
        }

        return DB::transaction(function () use ($testimonial, $data) {
            $testimonial->update($data);

            return $testimonial
                ->refresh()
                ->load('project');
        });
    }

    public function delete(Testimonial $testimonial): void
    {
        DB::transaction(function () use ($testimonial) {
            $testimonial->delete();
        });
    }
}