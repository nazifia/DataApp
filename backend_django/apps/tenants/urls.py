from django.urls import path
from .views import TenantInfoView, TenantListCreateView, TenantDetailView, MarkupUpdateView

urlpatterns = [
    path('info/', TenantInfoView.as_view()),
    path('markup/', MarkupUpdateView.as_view()),
    path('', TenantListCreateView.as_view()),
    path('<uuid:pk>/', TenantDetailView.as_view()),
]
