from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from django.http import JsonResponse


def health(request):
    return JsonResponse({'status': 'ok', 'service': 'TopUpNaija API'})


urlpatterns = [
    path('django-admin/', admin.site.urls),
    path('', health),
    path('health/', health),
    path('api/v1/auth/', include('apps.authentication.urls')),
    path('api/v1/user/', include('apps.authentication.user_urls')),
    path('api/v1/wallet/', include('apps.wallet.urls')),
    path('api/v1/airtime/', include('apps.airtime.urls')),
    path('api/v1/data/', include('apps.data_plans.urls')),
    path('api/v1/transactions/', include('apps.transactions.urls')),
    path('api/v1/admin/', include('apps.admin_portal.urls')),
    path('api/v1/tenants/', include('apps.tenants.urls')),
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
