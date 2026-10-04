<?php

namespace App\Services;

use App\Models\ContactMessage;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;

class ContactMessageService
{
    public function create(array $data): ContactMessage
    {
        return DB::transaction(function () use ($data) {
            return ContactMessage::create([
                ...$data,
                'status' => 'new',
            ]);
        });
    }

    public function getAdminMessages(
        int $perPage = 15
    ): LengthAwarePaginator {
        return ContactMessage::query()
            ->latest()
            ->paginate($perPage);
    }

    public function getAdminMessage(
        ContactMessage $contactMessage
    ): ContactMessage {
        return $contactMessage;
    }

    public function update(
        ContactMessage $contactMessage,
        array $data
    ): ContactMessage {
        return DB::transaction(function () use (
            $contactMessage,
            $data
        ) {
            $contactMessage->update($data);

            return $contactMessage->refresh();
        });
    }

    public function delete(ContactMessage $contactMessage): void
    {
        DB::transaction(function () use ($contactMessage) {
            $contactMessage->delete();
        });
    }
}