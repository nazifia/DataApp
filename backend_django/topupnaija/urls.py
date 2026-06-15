from django.contrib import admin
from django.contrib.admin.forms import AdminAuthenticationForm
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from django.http import JsonResponse, HttpResponse


class _PhoneLoginForm(AdminAuthenticationForm):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['username'].label = 'Phone Number'
        self.error_messages['invalid_login'] = (
            'Please enter a valid phone number and password for a staff account.'
        )


admin.site.login_form = _PhoneLoginForm
admin.site.site_header = 'TopUpNaija Administration'
admin.site.site_title = 'TopUpNaija Admin'
admin.site.index_title = 'Dashboard'


def health(request):
    return JsonResponse({'status': 'ok', 'service': 'TopUpNaija API'})


def sw_js(request):
    return HttpResponse('', content_type='application/javascript')


urlpatterns = [
    path('admin/', admin.site.urls),
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
    path('api/v1/beneficiaries/', include('apps.beneficiaries.urls')),
    path('api/v1/disputes/', include('apps.disputes.urls')),
    path('api/v1/bills/', include('apps.bills.urls')),
    path('api/v1/referrals/', include('apps.referrals.urls')),
    path('api/v1/agents/', include('apps.agents.urls')),
    path('api/v1/ussd/', include('apps.ussd.urls')),
    path('api/v1/notifications/', include('apps.notifications.urls')),
    path('sw.js', sw_js),
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
