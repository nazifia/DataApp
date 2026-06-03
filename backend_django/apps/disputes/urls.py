from django.urls import path
from .views import UserDisputeListCreateView

urlpatterns = [
    path('', UserDisputeListCreateView.as_view()),
]
