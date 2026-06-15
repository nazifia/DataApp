from django.urls import path
from .views import AgentApplyView, AgentDashboardView, AgentSaleView

urlpatterns = [
    path('apply/', AgentApplyView.as_view()),
    path('dashboard/', AgentDashboardView.as_view()),
    path('sale/', AgentSaleView.as_view()),
]
