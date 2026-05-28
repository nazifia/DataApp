from django.urls import path
from .views import TenantInfoView, TenantListCreateView, TenantDetailView

urlpatterns = [
    path('info/', TenantInfoView.as_view()),
    path('', TenantListCreateView.as_view()),
    path('<uuid:pk>/', TenantDetailView.as_view()),
]
