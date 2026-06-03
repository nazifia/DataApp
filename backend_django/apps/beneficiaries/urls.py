from django.urls import path
from .views import BeneficiaryListCreateView, BeneficiaryDetailView

urlpatterns = [
    path('', BeneficiaryListCreateView.as_view()),
    path('<uuid:pk>/', BeneficiaryDetailView.as_view()),
]
