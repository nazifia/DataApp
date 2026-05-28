import re
import threading
from django.http import JsonResponse

_thread_local = threading.local()

_IP_RE = re.compile(r'^\d{1,3}(\.\d{1,3}){3}$')
_ADMIN_PATHS = ('/admin/',)


def get_current_tenant():
    return getattr(_thread_local, 'tenant', None)


def set_current_tenant(tenant):
    _thread_local.tenant = tenant


def clear_current_tenant():
    _thread_local.tenant = None


class TenantMiddleware:
    """
    Resolves the tenant from the X-Tenant-Slug header or subdomain.
    Sets it on the request and in thread-local storage for model managers.
    Superadmin requests with no tenant header bypass tenant filtering.
    Admin paths and IP-address hosts are always exempt from tenant resolution.
    """

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        from apps.tenants.models import Tenant

        clear_current_tenant()
        request.tenant = None

        # Admin paths bypass tenant resolution entirely
        if any(request.path_info.startswith(p) for p in _ADMIN_PATHS):
            return self.get_response(request)

        slug = (
            request.headers.get('X-Tenant-Slug')
            or self._slug_from_subdomain(request)
        )

        if slug:
            try:
                tenant = Tenant.all_objects.get(slug=slug, is_active=True)
                request.tenant = tenant
                set_current_tenant(tenant)
            except Tenant.DoesNotExist:
                return JsonResponse(
                    {'detail': f'Tenant "{slug}" not found or inactive.'},
                    status=404,
                )

        response = self.get_response(request)
        clear_current_tenant()
        return response

    @staticmethod
    def _slug_from_subdomain(request):
        host = request.get_host().split(':')[0]
        # Skip raw IP addresses — their dotted segments are not subdomains
        if _IP_RE.match(host):
            return None
        parts = host.split('.')
        # e.g. acme.topupnaija.com → slug = acme
        if len(parts) >= 3:
            return parts[0]
        return None
