<?php

namespace App\Policies;

use App\Models\ProjectRequest;
use App\Models\User;

class ProjectRequestPolicy
{
    /**
     * عرض قائمة الطلبات.
     */
    public function viewAny(User $user): bool
    {
        return $user->hasAnyRole([
            'customer',
            'site_manager',
            'admin',
            'super_admin',
        ]);
    }

    /**
     * عرض طلب محدد.
     */
    public function view(User $user, ProjectRequest $projectRequest): bool
    {
        return $this->isOwner($user, $projectRequest)
            || $this->isAdmin($user);
    }

    /**
     * إنشاء طلب جديد.
     */
    public function create(User $user): bool
    {
        return $user->hasRole('customer');
    }

    /**
     * تعديل بيانات الطلب.
     */
    public function update(User $user, ProjectRequest $projectRequest): bool
    {
        return $this->isOwner($user, $projectRequest)
            && $projectRequest->status === ProjectRequest::STATUS_NEW;
    }

    /**
     * إلغاء الطلب.
     */
    public function cancel(User $user, ProjectRequest $projectRequest): bool
    {
        return $this->isOwner($user, $projectRequest)
            && in_array($projectRequest->status, [
                ProjectRequest::STATUS_NEW,
                ProjectRequest::STATUS_UNDER_REVIEW,
            ], true);
    }

    /**
     * إضافة مرفقات أو حذفها.
     */
    public function manageAttachments(
        User $user,
        ProjectRequest $projectRequest
    ): bool {
        return $this->isOwner($user, $projectRequest)
            && $projectRequest->status === ProjectRequest::STATUS_NEW;
    }

    /**
     * تنزيل المرفقات.
     */
    public function downloadAttachment(
        User $user,
        ProjectRequest $projectRequest
    ): bool {
        return $this->isOwner($user, $projectRequest)
            || $this->isAdmin($user);
    }

    /**
     * التحقق من ملكية الطلب.
     */
    private function isOwner(
        User $user,
        ProjectRequest $projectRequest
    ): bool {
        return (int) $projectRequest->user_id === (int) $user->id;
    }

    /**
     * التحقق من الدور الإداري.
     */
    private function isAdmin(User $user): bool
    {
        return $user->hasAnyRole([
            'site_manager',
            'admin',
            'super_admin',
        ]);
    }
}