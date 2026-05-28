from rest_framework.permissions import BasePermission

ROLE_LEVELS = {
    'user': 0,
    'support': 1,
    'moderator': 2,
    'admin': 3,
    'super_admin': 4,
}


def role_level(role: str) -> int:
    return ROLE_LEVELS.get(role, 0)


class IsAdminRole(BasePermission):
    """Requires support level or above."""
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated
                    and role_level(request.user.role) >= role_level('support'))


class IsModeratorOrAbove(BasePermission):
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated
                    and role_level(request.user.role) >= role_level('moderator'))


class IsAdminOrAbove(BasePermission):
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated
                    and role_level(request.user.role) >= role_level('admin'))


class IsSuperAdmin(BasePermission):
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated
                    and request.user.role == 'super_admin')


class IsTenantOwnerOrSuperAdmin(BasePermission):
    """Allows tenant owner or super_admin to manage tenant settings."""
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        if request.user.role == 'super_admin':
            return True
        if request.tenant and request.user.role == 'admin':
            return request.user.tenant_id == request.tenant.id
        return False
